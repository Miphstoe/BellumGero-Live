#include "engine/engine.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/managers/credit/CreditManager.h"
#include "server/zone/managers/skill/SkillManager.h"
#include "server/zone/managers/skill/imagedesign/ImageDesignManager.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/credits/CreditObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sessions/ImageDesignStationSession.h"
#include "server/zone/objects/player/sessions/ImageDesignStationObserver.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/tangible/components/imagedesignstation/ImageDesignStationDataComponent.h"
#include "server/zone/objects/transaction/TransactionLog.h"

#include "server/zone/packets/object/ImageDesignMessage.h"

namespace {
const float kStationUseRange = 10.0f;
const String kTemporarySkillMarker = "fmidstation_temp_id_skills";

const char* kImageDesignerSkills[] = {
	"social_imagedesigner_novice",
	"social_imagedesigner_hairstyle_01",
	"social_imagedesigner_hairstyle_02",
	"social_imagedesigner_hairstyle_03",
	"social_imagedesigner_hairstyle_04",
	"social_imagedesigner_exotic_01",
	"social_imagedesigner_exotic_02",
	"social_imagedesigner_exotic_03",
	"social_imagedesigner_exotic_04",
	"social_imagedesigner_bodyform_01",
	"social_imagedesigner_bodyform_02",
	"social_imagedesigner_bodyform_03",
	"social_imagedesigner_bodyform_04",
	"social_imagedesigner_markings_01",
	"social_imagedesigner_markings_02",
	"social_imagedesigner_markings_03",
	"social_imagedesigner_markings_04",
	"social_imagedesigner_master"
};

const int kImageDesignerSkillCount =
	sizeof(kImageDesignerSkills) / sizeof(kImageDesignerSkills[0]);
}

void ImageDesignStationSessionImplementation::initializeTransientMembers() {
	FacadeImplementation::initializeTransientMembers();
}

bool ImageDesignStationSessionImplementation::isStationSessionValid(
	bool notifyPlayer) {

	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer == nullptr || customer->getZoneServer() == nullptr)
		return false;

	ManagedReference<SceneObject*> station =
		customer->getZoneServer()->getObject(stationObjectId);

	bool valid =
		station != nullptr &&
		station->getZone() != nullptr &&
		station->getZone() == customer->getZone() &&
		station->getParentID() == customer->getParentID() &&
		station->getDistanceTo(customer) <= kStationUseRange;

	if (!valid && notifyPlayer) {
		customer->sendSystemMessage(
			"Image Designer Station session cancelled because you "
			"moved away from the station or it is no longer available.");
	}

	return valid;
}

void ImageDesignStationSessionImplementation::cleanupTemporarySkills() {
	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer == nullptr)
		return;

	String skillsToRemove = temporarySkillList;

	if (skillsToRemove.isEmpty())
		skillsToRemove = customer->getLuaStringData(kTemporarySkillMarker);

	if (!skillsToRemove.isEmpty()) {
		Vector<String> skills;
		StringTokenizer tokenizer(skillsToRemove);
		tokenizer.setDelimeter(",");

		while (tokenizer.hasMoreTokens()) {
			String skill;
			tokenizer.getStringToken(skill);

			if (!skill.isEmpty())
				skills.add(skill);
		}

		for (int i = skills.size() - 1; i >= 0; --i) {
			SkillManager::instance()->removeTemporarySkillState(
				skills.get(i),
				customer,
				true);
		}
	}

	PlayerObject* ghost =
		customer->getPlayerObject();

	if (ghost != nullptr && originalSkillPoints >= 0)
		ghost->setSkillPoints(originalSkillPoints);

	customer->deleteLuaStringData(kTemporarySkillMarker);
	customer->deleteLuaStringData(
		"fmidstation_original_skill_points");

	temporarySkillList = "";
	originalSkillPoints = -1;
}

int ImageDesignStationSessionImplementation::cancelSession() {
	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer != nullptr) {
		Locker locker(customer);

		if (stationObserver != nullptr) {
			customer->dropObserver(
				ObserverEventType::POSITIONCHANGED,
				stationObserver);

			customer->dropObserver(
				ObserverEventType::LOGGEDOUT,
				stationObserver);
		}

		stationObserver = nullptr;

		cleanupTemporarySkills();
		customer->dropActiveSession(
			SessionFacadeType::IMAGEDESIGN);
	}

	return 0;
}

void ImageDesignStationSessionImplementation::forceCloseStationSession(
	bool notifyPlayer) {

	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer == nullptr)
		return;

	Locker locker(customer);

	ImageDesignRejectMessage* message =
		new ImageDesignRejectMessage(
			customer->getObjectID(),
			customer->getObjectID(),
			customer->getObjectID(),
			stationVenueId,
			0);

	imageDesignData.insertToMessage(message);
	customer->sendMessage(message);

	if (notifyPlayer) {
		customer->sendSystemMessage(
			"Image Designer Station session cancelled because you "
			"moved away from the station or changed rooms.");
	}

	cancelSession();
}

void ImageDesignStationSessionImplementation::startStationImageDesign(
	CreatureObject* customer,
	uint64 stationId,
	uint64 ownerId,
	int price) {

	if (customer == nullptr || stationId == 0 || ownerId == 0)
		return;

	customerCreature = customer;
	stationObjectId = stationId;
	stationOwnerId = ownerId;
	servicePrice = Math::max(0, price);
	sessionStartTime.updateToCurrentTime();

	PlayerObject* ghost =
		customer->getPlayerObject();

	if (ghost == nullptr)
		return;

	originalSkillPoints =
		ghost->getSkillPoints();

	customer->setLuaStringData(
		"fmidstation_original_skill_points",
		String::valueOf(originalSkillPoints));

	if (!isStationSessionValid(true))
		return;

	StringBuffer addedSkills;

	for (int i = 0; i < kImageDesignerSkillCount; ++i) {
		String skill = kImageDesignerSkills[i];

		if (customer->hasSkill(skill))
			continue;

		if (addedSkills.length() > 0)
			addedSkills << ",";

		addedSkills << skill;
	}

	temporarySkillList = addedSkills.toString();

	if (!temporarySkillList.isEmpty())
		customer->setLuaStringData(
			kTemporarySkillMarker, temporarySkillList);

	if (!temporarySkillList.isEmpty()) {
		StringTokenizer tokenizer(temporarySkillList);
		tokenizer.setDelimeter(",");

		while (tokenizer.hasMoreTokens()) {
			String skill;
			tokenizer.getStringToken(skill);

			if (!skill.isEmpty()) {
				bool granted =
					SkillManager::instance()
						->grantTemporarySkillState(
							skill,
							customer,
							true);

				if (!granted) {
					customer->sendSystemMessage(
						"Image Designer Station could not "
						"prepare the temporary Image Designer "
						"profession state.");

					cleanupTemporarySkills();
					return;
				}
			}
		}
	}

	customer->addActiveSession(
		SessionFacadeType::IMAGEDESIGN,
		_this.getReferenceUnsafeStaticCast());

	String holoemote;

	if (ghost != nullptr)
		holoemote = ghost->getInstalledHoloEmote();

	stationVenueId = 0;
	SceneObject* root = customer->getRootParent();

	if (root != nullptr && root->isBuildingObject())
		stationVenueId = root->getObjectID();

	stationObserver =
		new ImageDesignStationObserver(
			_this.getReferenceUnsafeStaticCast());

	customer->registerObserver(
		ObserverEventType::POSITIONCHANGED,
		stationObserver);

	customer->registerObserver(
		ObserverEventType::LOGGEDOUT,
		stationObserver);

	ImageDesignStartMessage* msg =
		new ImageDesignStartMessage(
			customer, customer, customer,
			stationVenueId, holoemote);

	customer->sendMessage(msg);
}

bool ImageDesignStationSessionImplementation::doStationPayment() {
	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer == nullptr)
		return false;

	int paymentAmount = Math::max(0, servicePrice);

	int64 customerCredits =
		(int64)customer->getCashCredits() +
		(int64)customer->getBankCredits();

	if (customerCredits < paymentAmount) {
		customer->sendSystemMessage(
			"You do not have enough credits to use this "
			"Image Designer Station.");
		return false;
	}

	Reference<CreditObject*> ownerCredits =
		CreditManager::getCreditObject(stationOwnerId);

	if (stationOwnerId == 0 || ownerCredits == nullptr) {
		customer->sendSystemMessage(
			"The station owner cannot currently receive payment. "
			"No credits were charged.");
		return false;
	}

	int cash = customer->getCashCredits();

	if (cash >= paymentAmount) {
		customer->subtractCashCredits(paymentAmount);
	} else {
		if (cash > 0)
			customer->subtractCashCredits(cash);

		customer->subtractBankCredits(paymentAmount - cash);
	}

	CreditManager::addBankCredits(
		stationOwnerId, paymentAmount, true);

	TransactionLog trx(
		customer, TrxCode::IMAGEDESIGN,
		(uint)paymentAmount, false);

	trx.addState("feature", String("FMIDStationDedicatedSession"));
	trx.addState("stationId", stationObjectId);
	trx.addState("stationOwnerId", stationOwnerId);
	trx.addState("price", paymentAmount);
	trx.commit();

	ManagedReference<SceneObject*> station =
		customer->getZoneServer()->getObject(stationObjectId);

	if (station != nullptr) {
		Locker stationLocker(station, customer);

		DataObjectComponentReference* dataRef =
			station->getDataObjectComponent();

		ImageDesignStationDataComponent* data =
			(dataRef != nullptr && dataRef->get() != nullptr) ?
				dynamic_cast<ImageDesignStationDataComponent*>(
					dataRef->get()) :
				nullptr;

		if (data != nullptr) {
			data->recordCompletedSession(paymentAmount);
			station->updateToDatabase();
		}
	}

	return true;
}

void ImageDesignStationSessionImplementation::updateStationImageDesign(
	CreatureObject* updater,
	uint64 designer,
	uint64 targetPlayer,
	uint64 tent,
	int type,
	const ImageDesignData& data) {

	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer == nullptr || updater == nullptr)
		return;

	if (updater != customer ||
			designer != customer->getObjectID() ||
			targetPlayer != customer->getObjectID()) {
		customer->sendSystemMessage(
			"Invalid Image Designer Station session data received.");
		cancelSession();
		return;
	}

	if (!isStationSessionValid(true)) {
		cancelStationImageDesign(
			designer, targetPlayer, tent, type, data);
		return;
	}

	Locker locker(customer);

	imageDesignData = data;

	bool commitChanges =
		imageDesignData.isAcceptedByDesigner();

	if (commitChanges)
		commitChanges = doStationPayment();

	if (commitChanges) {
		VectorMap<String, float>* bodyAttributes =
			imageDesignData.getBodyAttributesMap();

		VectorMap<String, uint32>* colorAttributes =
			imageDesignData.getColorAttributesMap();

		ImageDesignManager* imageDesignManager =
			ImageDesignManager::instance();

		if (imageDesignManager == nullptr) {
			cancelSession();
			return;
		}

		ManagedReference<TangibleObject*> currentHair =
			hairObject =
				customer->getSlottedObject("hair")
					.castTo<TangibleObject*>();

		if (type == 1) {
			String oldCustomization;

			if (currentHair != nullptr) {
				hairObject = nullptr;

				Locker hlock(currentHair);
				currentHair->getCustomizationString(
					oldCustomization);

				currentHair->destroyObjectFromWorld(true);
				currentHair->destroyObjectFromDatabase();
			}

			String hairTemplate =
				imageDesignData.getHairTemplate();

			hairObject =
				imageDesignManager->createHairObject(
					customer, customer,
					hairTemplate,
					oldCustomization);
		}

		int modificationType =
			ImageDesignManager::NONE;

		for (int i = 0; i < bodyAttributes->size(); ++i) {
			VectorMapEntry<String, float>* entry =
				&bodyAttributes->elementAt(i);

			imageDesignManager->updateCustomization(
				customer,
				entry->getKey(),
				entry->getValue(),
				modificationType,
				customer);
		}

		for (int i = 0; i < colorAttributes->size(); ++i) {
			VectorMapEntry<String, uint32>* entry =
				&colorAttributes->elementAt(i);

			imageDesignManager->updateColorCustomization(
				customer,
				entry->getKey(),
				entry->getValue(),
				hairObject,
				modificationType,
				customer);
		}

		if (hairObject != nullptr)
			imageDesignManager->updateHairObject(
				customer, hairObject);

		String holoemote =
			imageDesignData.getHoloEmote();

		if (!holoemote.isEmpty()) {
			PlayerObject* ghost =
				customer->getPlayerObject();

			if (ghost != nullptr) {
				ghost->setInstalledHoloEmote(holoemote);
				customer->sendSystemMessage(
					"@image_designer:new_holoemote");
			}
		}

		cancelSession();

		customer->sendSystemMessage(
			"Image Designer Station service completed. "
			+ String::valueOf(servicePrice)
			+ " credits were paid to the station owner.");
	}

	ImageDesignChangeMessage* message =
		new ImageDesignChangeMessage(
			customer->getObjectID(),
			designer,
			targetPlayer,
			tent,
			type);

	imageDesignData.insertToMessage(message);
	customer->sendMessage(message);
}

void ImageDesignStationSessionImplementation::cancelStationImageDesign(
	uint64 designer,
	uint64 targetPlayer,
	uint64 tent,
	int type,
	const ImageDesignData& data) {

	ManagedReference<CreatureObject*> customer =
		customerCreature.get();

	if (customer == nullptr)
		return;

	Locker locker(customer);

	imageDesignData = data;

	ImageDesignRejectMessage* message =
		new ImageDesignRejectMessage(
			customer->getObjectID(),
			designer,
			targetPlayer,
			tent,
			type);

	imageDesignData.insertToMessage(message);
	customer->sendMessage(message);

	cancelSession();
}
