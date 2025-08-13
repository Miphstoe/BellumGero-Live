/*
 * ImageDesignSessionImplementation.cpp
 *
 *  Created on: Feb 2, 2011
 *      Author: Polonel
 */

#include "engine/engine.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/skill/imagedesign/ImageDesignManager.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/events/ImageDesignTimeoutEvent.h"
#include "server/zone/objects/player/sessions/ImageDesignPositionObserver.h"
#include "server/zone/objects/player/sessions/ImageDesignSession.h"
#include "server/zone/objects/player/sessions/MigrateStatsSession.h"
#include "server/zone/packets/object/ImageDesignMessage.h"
#include "server/zone/objects/transaction/TransactionLog.h"

// NEW: allow cantinas as valid stat migration venues in addition to salons
#include "server/zone/objects/building/BuildingObject.h"

// #define DEBUG_ID

// Helper: returns the building the player is in if it's a valid stat migration venue
// (either a Salon (image design tent) or any Cantina). Otherwise returns nullptr.
static SceneObject* getEligibleStatMigVenue(CreatureObject* creo) {
    if (creo == nullptr)
        return nullptr;

    // Original behavior: salons (image design tents)
    SceneObject* salon = creo->getParentRecursively(SceneObjectType::SALONBUILDING);
    if (salon != nullptr)
        return salon;

    // New behavior: any cantina building (by template path)
    SceneObject* root = creo->getRootParent();
    if (root == nullptr || !root->isBuildingObject())
        return nullptr;

    auto* building = cast<BuildingObject*>(root);
    if (building == nullptr)
        return nullptr;

    SharedObjectTemplate* shot = building->getObjectTemplate();
    if (shot == nullptr)
        return nullptr;

    // Common NPC-city and player-city cantinas have template names containing "cantina".
    String tmpl = shot->getFullTemplateString();
    if (tmpl.contains("cantina"))
        return building;

    return nullptr;
}

void ImageDesignSessionImplementation::initializeTransientMembers() {
	FacadeImplementation::initializeTransientMembers();
}

int ImageDesignSessionImplementation::cancelSession() {
	ManagedReference<CreatureObject*> designerCreature = this->designerCreature.get();
	ManagedReference<CreatureObject*> targetCreature = this->targetCreature.get();

	if (designerCreature != nullptr) {
		designerCreature->dropActiveSession(SessionFacadeType::IMAGEDESIGN);

		if (positionObserver != nullptr)
			designerCreature->dropObserver(ObserverEventType::POSITIONCHANGED, positionObserver);
	}

	if (targetCreature != nullptr) {
		targetCreature->dropActiveSession(SessionFacadeType::IMAGEDESIGN);

		if (positionObserver != nullptr)
			targetCreature->dropObserver(ObserverEventType::POSITIONCHANGED, positionObserver);
	}

	dequeueIdTimeoutEvent();

	return 0;
}

void ImageDesignSessionImplementation::startImageDesign(CreatureObject* designer, CreatureObject* targetPlayer) {
	sessionStartTime.updateToCurrentTime();

	uint64 designerTentID = 0; // non-zero enables the Stat Migration checkbox client-side
	uint64 targetTentID = 0;

	ManagedReference<SceneObject*> venue = getEligibleStatMigVenue(designer);
	if (venue != nullptr)
		designerTentID = venue->getObjectID();

	if (designerTentID != 0) {
		venue = getEligibleStatMigVenue(targetPlayer);

		if (venue != nullptr)
			targetTentID = venue->getObjectID();

		if (targetTentID != 0) {
			positionObserver = new ImageDesignPositionObserver(_this.getReferenceUnsafeStaticCast());

			designer->registerObserver(ObserverEventType::POSITIONCHANGED, positionObserver);

			if (targetPlayer != designer)
				targetPlayer->registerObserver(ObserverEventType::POSITIONCHANGED, positionObserver);
		}
	}

	if (targetTentID == 0 || designerTentID == 0) {
		targetTentID = 0;
		designerTentID = 0;
	}

	designer->addActiveSession(SessionFacadeType::IMAGEDESIGN, _this.getReferenceUnsafeStaticCast());

	String holoemote;
	PlayerObject* ghost = targetPlayer->getPlayerObject();

	if (ghost != nullptr) {
		holoemote = ghost->getInstalledHoloEmote();
	}

	ImageDesignStartMessage* msg = new ImageDesignStartMessage(designer, designer, targetPlayer, designerTentID, holoemote);
	designer->sendMessage(msg);

	if (designer != targetPlayer) {
		targetPlayer->addActiveSession(SessionFacadeType::IMAGEDESIGN, _this.getReferenceUnsafeStaticCast());

		ImageDesignStartMessage* msg2 = new ImageDesignStartMessage(targetPlayer, designer, targetPlayer, targetTentID, holoemote);
		targetPlayer->sendMessage(msg2);
	}

	designerCreature = designer;
	targetCreature = targetPlayer;

	idTimeoutEvent = new ImageDesignTimeoutEvent(_this.getReferenceUnsafeStaticCast());

#ifdef DEBUG_ID
	info(true) << "startImageDesign - for Target Player: " << targetPlayer->getFirstName() << " Target Venue ID = " <<  targetTentID << " Designer Venue ID = " << designerTentID << " Holoemote = " << holoemote;
#endif
}

void ImageDesignSessionImplementation::updateImageDesign(CreatureObject* updater, uint64 designer, uint64 targetPlayer, uint64 tent, int type, const ImageDesignData& data) {
	ManagedReference<CreatureObject*> strongReferenceTarget = targetCreature.get();
	ManagedReference<CreatureObject*> strongReferenceDesigner = designerCreature.get();

	if (strongReferenceTarget == nullptr || strongReferenceDesigner == nullptr)
		return;

#ifdef DEBUG_ID
	info(true) << "---------- updateImageDesign called for Target Player: " << strongReferenceTarget->getFirstName() << " ----------";
#endif

	Locker locker(strongReferenceDesigner);
	Locker clocker(strongReferenceTarget, strongReferenceDesigner);

	imageDesignData = data;

	CreatureObject* targetObject = nullptr;

	if (updater == strongReferenceDesigner)
		targetObject = strongReferenceTarget;
	else
		targetObject = strongReferenceDesigner;

	bool statMig = imageDesignData.isStatMigrationRequested();
	bool designerAccepted = imageDesignData.isAcceptedByDesigner();

	// Check time since session started to ensure timer is not bypassed client side
	if (statMig && strongReferenceDesigner != strongReferenceTarget) {
		uint64 timeElapsed = sessionStartTime.miliDifference() / 1000;
		int remainingTime = (4 * 60) - timeElapsed;

#ifdef DEBUG_ID
		info(true) << "updateImageDesign - start time elapsed = " << timeElapsed << " with remaining time of " << remainingTime;
#endif

		// Only break the session if the ID attempts to accept prior to sufficient time elapsing
		if (designerAccepted && remainingTime > 0) {
			int minutes = remainingTime / 60;

			StringBuffer msg;
			msg << "Warning: You have attempted to bypass the stat migration timer. You must wait a total of 4 minutes before committing a migration to another player. Session Terminated with time remaining: ";

			if (minutes > 0)
				msg << minutes << " minutes and ";

			int seconds = remainingTime % 60;

			if (seconds == 1) {
				msg << seconds << " second.";
			} else {
				msg << seconds << " seconds.";
			}

			strongReferenceDesigner->sendSystemMessage(msg.toString());
			cancelSession();

			strongReferenceDesigner->error() << "Player has attempted to bypass the stat migration timer in the client -- Image Designer: " << strongReferenceDesigner->getFirstName() << " " << strongReferenceDesigner->getObjectID() << " Target Player: " << strongReferenceTarget->getFirstName() << " " << strongReferenceTarget->getObjectID() << " Message to Image Designer: " << msg.toString();

			return;
		}
	}

	bool commitChanges = false;

	if (designerAccepted) {
		commitChanges = true;

		if (strongReferenceDesigner != strongReferenceTarget && !imageDesignData.isAcceptedByTarget()) {
			commitChanges = false;

			if (idTimeoutEvent == nullptr)
				idTimeoutEvent = new ImageDesignTimeoutEvent(_this.getReferenceUnsafeStaticCast());

			if (!idTimeoutEvent->isScheduled())
				idTimeoutEvent->schedule(120000); // 2 minutes
		} else {
			commitChanges = doPayment();
		}
	}

	if (commitChanges) {
#ifdef DEBUG_ID
		info(true) << "updateImageDesign - COMMIT CHANGES.";
#endif

		int xpGranted = 0; // Minimum Image Design XP granted (base amount).

		// Only allow stat migration when BOTH parties are in an eligible venue (salon or cantina)
		if (statMig
			&& strongReferenceDesigner != strongReferenceTarget
			&& getEligibleStatMigVenue(strongReferenceDesigner) != nullptr
			&& getEligibleStatMigVenue(strongReferenceTarget)   != nullptr) {

			ManagedReference<Facade*> facade = strongReferenceTarget->getActiveSession(SessionFacadeType::MIGRATESTATS);
			ManagedReference<MigrateStatsSession*> session = dynamic_cast<MigrateStatsSession*>(facade.get());

			if (session != nullptr) {
				session->migrateStats();
				xpGranted = 2000;

#ifdef DEBUG_ID
				info(true) << "updateImageDesign - Stats Migrated.";
#endif
			}
		}

		VectorMap<String, float>* bodyAttributes = imageDesignData.getBodyAttributesMap();
		VectorMap<String, uint32>* colorAttributes = imageDesignData.getColorAttributesMap();

		ImageDesignManager* imageDesignManager = ImageDesignManager::instance();

		if (imageDesignManager == nullptr) {
			cancelSession();
			return;
		}

		ManagedReference<TangibleObject*> currentHair = hairObject = strongReferenceTarget->getSlottedObject("hair").castTo<TangibleObject*>();

		// Session is updating hair style. Does not include color changes
		if (type == 1) {
			String oldCustomization;

			// First destroy current hair.
			if (currentHair != nullptr) {
				hairObject = nullptr;

				Locker hlock(currentHair);
				currentHair->getCustomizationString(oldCustomization);

				currentHair->destroyObjectFromWorld(true);
				currentHair->destroyObjectFromDatabase();
			}

			String hairTempString = imageDesignData.getHairTemplate();

			// Create new hair for the player. Returns nullptr if the creature type can be bald and that is selected.
			hairObject = imageDesignManager->createHairObject(strongReferenceDesigner, strongReferenceTarget, hairTempString, oldCustomization);

			strongReferenceDesigner->notifyObservers(ObserverEventType::IMAGEDESIGNHAIR, nullptr, 0);

			if (xpGranted < 100)
				xpGranted = 100;
		}

		int bodyAttSize = bodyAttributes->size();
		int colorAttSize = colorAttributes->size();

		// Modification type pulled from iff customization_data
		int modificationType = ImageDesignManager::NONE;

		if (bodyAttSize > 0) {
			for (int i = 0; i < bodyAttSize; ++i) {
				VectorMapEntry<String, float>* entry = &bodyAttributes->elementAt(i);
				imageDesignManager->updateCustomization(strongReferenceDesigner, entry->getKey(), entry->getValue(), modificationType, strongReferenceTarget);
			}
		}

		if (colorAttSize > 0) {
			for (int i = 0; i < colorAttSize; ++i) {
				VectorMapEntry<String, uint32>* entry = &colorAttributes->elementAt(i);
				imageDesignManager->updateColorCustomization(strongReferenceDesigner, entry->getKey(), entry->getValue(), hairObject, modificationType, strongReferenceTarget);
			}
		}

#ifdef DEBUG_ID
		info(true) << "updateImageDesign - Type: " << type << " Body Attributes Size = " << bodyAttSize << " Color Attributes = " << colorAttSize << " Modification Type = " << modificationType;
#endif

		// Set XP based on modification type
		switch (modificationType) {
			case ImageDesignManager::PHYSICAL: {
				if (xpGranted < 300)
					xpGranted = 300;
			}
			case ImageDesignManager::COSMETIC: {
				if (xpGranted < 100)
					xpGranted = 100;
			}
		}

		// apply hair changes
		if (hairObject != nullptr)
			imageDesignManager->updateHairObject(strongReferenceTarget, hairObject);

		// Add holo emote
		String holoemote = imageDesignData.getHoloEmote();

		if (!holoemote.isEmpty()) {
			PlayerObject* ghost = strongReferenceTarget->getPlayerObject();

			if (ghost != nullptr) {
				ghost->setInstalledHoloEmote(holoemote); // Also resets number of uses available

				strongReferenceTarget->sendSystemMessage("@image_designer:new_holoemote"); // "Congratulations! You have purchased a new Holo-Emote generator. Type '/holoemote help' for instructions."

				if (xpGranted < 100)
					xpGranted = 100;
			}
		}

		// Award XP.
		PlayerManager* playerManager = strongReferenceDesigner->getZoneServer()->getPlayerManager();

		if (playerManager != nullptr && xpGranted > 0) {
			if (strongReferenceDesigner == strongReferenceTarget) {
				xpGranted /= 2;
			}

			playerManager->awardExperience(strongReferenceDesigner, "imagedesigner", xpGranted, true);
		}

		// End the session
		cancelSession();
	}

	ImageDesignChangeMessage* message = new ImageDesignChangeMessage(targetObject->getObjectID(), designer, targetPlayer, tent, type);
	imageDesignData.insertToMessage(message);

	targetObject->sendMessage(message);
}

bool ImageDesignSessionImplementation::doPayment() {
	ManagedReference<CreatureObject*> designerCreature = this->designerCreature.get();
	ManagedReference<CreatureObject*> targetCreature = this->targetCreature.get();

	int targetCredits = targetCreature->getCashCredits() + targetCreature->getBankCredits();

	uint32 requiredPayment = imageDesignData.getRequiredPayment();
	uint32 offeredPayment = imageDesignData.getOfferedPayment();
	uint32 paymentAmount = requiredPayment;

	if (paymentAmount < offeredPayment)
		paymentAmount = offeredPayment;

	// The client should prevent this, but in case it doesn't
	if (targetCredits < paymentAmount) {
		targetCreature->sendSystemMessage("You do not have enough credits to pay the required payment.");
		designerCreature->sendSystemMessage("Target does not have enough credits for the required payment.");

		cancelSession();

		return false;
	}

	if (paymentAmount <= targetCreature->getCashCredits()) {
		TransactionLog trx(targetCreature, designerCreature, TrxCode::IMAGEDESIGN, paymentAmount, true);
		targetCreature->subtractCashCredits(paymentAmount);
		designerCreature->addCashCredits(paymentAmount);
	} else {
		int requiredBankCredits = paymentAmount - targetCreature->getCashCredits();

		TransactionLog trxCash(targetCreature, designerCreature, TrxCode::IMAGEDESIGN, targetCreature->getCashCredits(), true);
		targetCreature->subtractCashCredits(targetCreature->getCashCredits());

		TransactionLog trxBank(targetCreature, designerCreature, TrxCode::IMAGEDESIGN, requiredBankCredits, true);
		trxBank.groupWith(trxCash);

		targetCreature->subtractBankCredits(requiredBankCredits);
		designerCreature->addCashCredits(paymentAmount);
	}

	return true;
}

void ImageDesignSessionImplementation::checkDequeueEvent(SceneObject* scene) {
	ManagedReference<CreatureObject*> designerCreature = this->designerCreature.get();
	ManagedReference<CreatureObject*> targetCreature = this->targetCreature.get();

	if (targetCreature == nullptr || designerCreature == nullptr)
		return;

	if (scene == designerCreature) {
		Locker clocker(targetCreature, designerCreature);

		if (getEligibleStatMigVenue(targetCreature) == nullptr || getEligibleStatMigVenue(designerCreature) == nullptr)
			return;
	} else if (scene == targetCreature) {
		Locker clocker(designerCreature, targetCreature);

		if (getEligibleStatMigVenue(targetCreature) == nullptr || getEligibleStatMigVenue(designerCreature) == nullptr)
			return;
	}

	dequeueIdTimeoutEvent();
}

void ImageDesignSessionImplementation::sessionTimeout() {
	ManagedReference<CreatureObject*> designerCreature = this->designerCreature.get();
	ManagedReference<CreatureObject*> targetCreature = this->targetCreature.get();

	if (designerCreature != nullptr) {
		Locker locker(designerCreature);

		if (getEligibleStatMigVenue(designerCreature) == nullptr || imageDesignData.isAcceptedByDesigner()) {
			designerCreature->sendSystemMessage("Image Design session has timed out. Changes aborted.");

			cancelImageDesign(designerCreature->getObjectID(), targetCreature->getObjectID(), 0, 0, imageDesignData);

			return;
		}
	}

	if (targetCreature != nullptr) {
		Locker locker(designerCreature);
		Locker clocker(targetCreature, designerCreature);

		if (getEligibleStatMigVenue(targetCreature) == nullptr || imageDesignData.isAcceptedByDesigner()) {
			targetCreature->sendSystemMessage("Image Design session has timed out. Changes aborted.");

			cancelImageDesign(designerCreature->getObjectID(), targetCreature->getObjectID(), 0, 0, imageDesignData);

			return;
		}
	}
}

void ImageDesignSessionImplementation::cancelImageDesign(uint64 designer, uint64 targetPlayer, uint64 tent, int type, const ImageDesignData& data) {
	ManagedReference<CreatureObject*> designerCreature = this->designerCreature.get();
	ManagedReference<CreatureObject*> targetCreature = this->targetCreature.get();

	if (targetCreature == nullptr || designerCreature == nullptr)
		return;

	Locker locker(designerCreature);
	Locker clocker(targetCreature, designerCreature);

	imageDesignData = data;

	ImageDesignRejectMessage* message = new ImageDesignRejectMessage(targetCreature->getObjectID(), designer, targetPlayer, tent, type);
	imageDesignData.insertToMessage(message);
	targetCreature->sendMessage(message);

	ImageDesignRejectMessage* msg2 = new ImageDesignRejectMessage(designerCreature->getObjectID(), designer, targetPlayer, tent, type);
	imageDesignData.insertToMessage(msg2);
	designerCreature->sendMessage(msg2);

	// TODO: Needs research.

	cancelSession();
}
