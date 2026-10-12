#include "engine/engine.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/managers/skill/SkillManager.h"
#include "server/zone/managers/skill/SkillModManager.h"
#include "server/zone/managers/skill/imagedesign/ImageDesignManager.h"

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/variables/Skill.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sessions/VendorImageDesignSession.h"
#include "server/zone/objects/player/sessions/VendorImageDesignObserver.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "server/zone/objects/tangible/components/vendor/VendorDataComponent.h"

#include "server/zone/packets/object/ImageDesignMessage.h"

#include "templates/creature/PlayerCreatureTemplate.h"
#include "templates/creature/VendorCreatureTemplate.h"
#include "templates/customization/CustomizationIdManager.h"
#include "templates/manager/TemplateManager.h"

namespace {
const float kVendorDesignRange = 16.0f;
const uint64 kVendorDesignTimeoutMs = 15 * 60 * 1000;

// Image Designer skill boxes whose skill mods are summed to determine the
// master-level ID mods the stock client needs to enable its UI options.
// Only the mods listed in kImageDesignerModNames are granted.
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

const char* kImageDesignerModNames[] = {
	"hair",
	"face",
	"body",
	"markings"
};

// Process-lifetime vendor lock (vendor oid -> designer oid). Intentionally not
// persisted: a server restart ends every session, so it must start empty.
Mutex& getVendorLockMutex() {
	static Mutex mutex;
	return mutex;
}

VectorMap<uint64, uint64>& getVendorLocks() {
	static VectorMap<uint64, uint64> locks;
	return locks;
}

VendorDataComponent* getVendorData(SceneObject* vendor) {
	if (vendor == nullptr)
		return nullptr;

	DataObjectComponentReference* data = vendor->getDataObjectComponent();

	if (data == nullptr || data->get() == nullptr || !data->get()->isVendorData())
		return nullptr;

	return cast<VendorDataComponent*>(data->get());
}

// Species/gender key used by customization_data (e.g. "twilek_female"), or
// empty if the vendor's model has no player Image Designer data.
String getDesignableSpeciesGender(CreatureObject* vendor) {
	if (vendor == nullptr || vendor->isPlayerCreature())
		return "";

	if (dynamic_cast<VendorCreatureTemplate*>(vendor->getObjectTemplate()) == nullptr)
		return "";

	String speciesGender = ImageDesignManager::instance()->getSpeciesGenderString(vendor);

	if (speciesGender == "unknown" || speciesGender.beginsWith("_"))
		return "";

	uint32 templateCRC = String::hashCode("object/creature/player/" + speciesGender + ".iff");
	PlayerCreatureTemplate* tmpl = dynamic_cast<PlayerCreatureTemplate*>(TemplateManager::instance()->getTemplate(templateCRC));

	if (tmpl == nullptr || tmpl->getCustomizationDataMap().size() == 0)
		return "";

	return speciesGender;
}
}

void VendorImageDesignSessionImplementation::initializeTransientMembers() {
	FacadeImplementation::initializeTransientMembers();
}

bool VendorImageDesignSessionImplementation::isVendorSessionValid(bool notifyPlayer) {
	ManagedReference<CreatureObject*> designer = designerCreature.get();
	ManagedReference<CreatureObject*> vendor = vendorCreature.get();

	if (designer == nullptr || !sessionActive)
		return false;

	bool valid = vendor != nullptr &&
		vendor->getObjectID() == vendorObjectId &&
		vendor->isVendor() &&
		!vendor->isPlayerCreature() &&
		vendor->getZone() != nullptr &&
		vendor->getZone() == designer->getZone() &&
		vendor->getRootParent() == designer->getRootParent() &&
		vendor->getDistanceTo(designer) <= kVendorDesignRange;

	if (valid) {
		VendorDataComponent* vendorData = getVendorData(vendor);

		valid = vendorData != nullptr &&
			vendorData->getOwnerId() == vendorOwnerId &&
			vendorOwnerId == designer->getObjectID();
	}

	if (!valid && notifyPlayer)
		designer->sendSystemMessage("This vendor cannot be customized.");

	return valid;
}

bool VendorImageDesignSessionImplementation::startVendorImageDesign(CreatureObject* designer, CreatureObject* vendor) {
	if (designer == nullptr || vendor == nullptr || !designer->isPlayerCreature())
		return false;

	PlayerObject* ghost = designer->getPlayerObject();

	if (ghost == nullptr)
		return false;

	if (!vendor->isVendor() || vendor->isPlayerCreature()) {
		designer->sendSystemMessage("This vendor cannot be customized.");
		return false;
	}

	VendorDataComponent* vendorData = getVendorData(vendor);

	if (vendorData == nullptr) {
		designer->sendSystemMessage("This vendor cannot be customized.");
		return false;
	}

	if (vendorData->getOwnerId() != designer->getObjectID()) {
		designer->sendSystemMessage("You do not have permission to customize this vendor.");
		return false;
	}

	if (getDesignableSpeciesGender(vendor).isEmpty()) {
		designer->sendSystemMessage("This vendor cannot be customized.");
		return false;
	}

	if (vendor->getZone() == nullptr || vendor->getZone() != designer->getZone() ||
			vendor->getRootParent() != designer->getRootParent() ||
			vendor->getDistanceTo(designer) > kVendorDesignRange) {
		designer->sendSystemMessage("You are too far away from the vendor to customize it.");
		return false;
	}

	if (designer->containsActiveSession(SessionFacadeType::IMAGEDESIGN)) {
		designer->sendSystemMessage("@image_designer:already_image_designing");
		return false;
	}

	uint64 designerId = designer->getObjectID();
	uint64 vendorId = vendor->getObjectID();

	{
		Locker lock(&getVendorLockMutex());
		VectorMap<uint64, uint64>& locks = getVendorLocks();

		if (locks.contains(vendorId)) {
			uint64 lockHolder = locks.get(vendorId);
			bool stale = true;

			if (lockHolder != designerId) {
				ManagedReference<SceneObject*> holder = designer->getZoneServer()->getObject(lockHolder);
				stale = holder == nullptr || !holder->isCreatureObject() ||
					dynamic_cast<VendorImageDesignSession*>(holder->getActiveSession(SessionFacadeType::IMAGEDESIGN).get()) == nullptr;
			}

			if (!stale) {
				designer->sendSystemMessage("This vendor is already being customized.");
				return false;
			}

			locks.drop(vendorId);
		}

		locks.put(vendorId, designerId);
	}

	designerCreature = designer;
	vendorCreature = vendor;
	vendorObjectId = vendorId;
	vendorOwnerId = designerId;
	sessionActive = true;
	sessionStartTime.updateToCurrentTime();

	// Grant only the Image Designer skill mods the stock UI reads, topped up to
	// master level under a dedicated transient mod type. No skill boxes, skill
	// points, abilities, schematics or XP caps are touched.
	VectorMap<String, int> masterMods;
	SkillManager* skillManager = SkillManager::instance();

	for (const char* skillName : kImageDesignerSkills) {
		Skill* skill = skillManager->getSkill(String(skillName));

		if (skill == nullptr)
			continue;

		auto modifiers = skill->getSkillModifiers();

		if (modifiers == nullptr)
			continue;

		for (int i = 0; i < modifiers->size(); ++i) {
			const String& modName = modifiers->elementAt(i).getKey();
			int value = modifiers->elementAt(i).getValue();
			bool isImageDesignerMod = false;

			for (const char* idMod : kImageDesignerModNames) {
				if (modName == idMod)
					isImageDesignerMod = true;
			}

			if (!isImageDesignerMod)
				continue;

			int current = masterMods.contains(modName) ? masterMods.get(modName) : 0;
			masterMods.drop(modName);
			masterMods.put(modName, current + value);
		}
	}

	designer->removeAllSkillModsOfType(SkillModManager::VENDORIMAGEDESIGN, true);

	for (int i = 0; i < masterMods.size(); ++i) {
		const String& modName = masterMods.elementAt(i).getKey();
		int delta = masterMods.elementAt(i).getValue() - designer->getSkillMod(modName);

		if (delta > 0)
			designer->addSkillMod(SkillModManager::VENDORIMAGEDESIGN, modName, delta, true);
	}

	designer->addActiveSession(SessionFacadeType::IMAGEDESIGN, _this.getReferenceUnsafeStaticCast());

	sessionObserver = new VendorImageDesignObserver(_this.getReferenceUnsafeStaticCast());
	designer->registerObserver(ObserverEventType::POSITIONCHANGED, sessionObserver);
	designer->registerObserver(ObserverEventType::LOGGEDOUT, sessionObserver);

	// Session timeout. The start timestamp guards against a later session
	// reusing this object being closed by a stale task.
	ManagedWeakReference<VendorImageDesignSession*> weakSession = _this.getReferenceUnsafeStaticCast();
	uint64 startTimestamp = sessionStartTime.getMiliTime();

	Core::getTaskManager()->scheduleTask([weakSession, startTimestamp]() {
		// get() is non-const, so take a local copy of the captured weak reference.
		ManagedWeakReference<VendorImageDesignSession*> sessionRef = weakSession;
		ManagedReference<VendorImageDesignSession*> session = sessionRef.get();

		if (session != nullptr)
			session->checkSessionTimeout(startTimestamp);
	}, "VendorImageDesignTimeoutTask", kVendorDesignTimeoutMs);

	// Tent id 0 disables the stat migration option; the vendor is the target so
	// the client builds its preview from the vendor's current appearance,
	// customization variables and scale.
	ImageDesignStartMessage* msg = new ImageDesignStartMessage(designer, designer, vendor, 0, "");
	designer->sendMessage(msg);

	return true;
}

void VendorImageDesignSessionImplementation::checkSessionTimeout(uint64 startTimestamp) {
	if (!sessionActive || sessionStartTime.getMiliTime() != startTimestamp)
		return;

	forceCloseVendorSession("Vendor design session has timed out. Changes aborted.");
}

int VendorImageDesignSessionImplementation::cancelSession() {
	ManagedReference<CreatureObject*> designer = designerCreature.get();

	if (designer != nullptr) {
		Locker locker(designer);

		if (sessionObserver != nullptr) {
			designer->dropObserver(ObserverEventType::POSITIONCHANGED, sessionObserver);
			designer->dropObserver(ObserverEventType::LOGGEDOUT, sessionObserver);
		}

		designer->removeAllSkillModsOfType(SkillModManager::VENDORIMAGEDESIGN, true);

		ManagedReference<Facade*> active = designer->getActiveSession(SessionFacadeType::IMAGEDESIGN);

		if (active.get() == _this.getReferenceUnsafeStaticCast())
			designer->dropActiveSession(SessionFacadeType::IMAGEDESIGN);
	}

	sessionObserver = nullptr;

	if (vendorObjectId != 0) {
		Locker lock(&getVendorLockMutex());
		VectorMap<uint64, uint64>& locks = getVendorLocks();

		if (locks.contains(vendorObjectId) && locks.get(vendorObjectId) == vendorOwnerId)
			locks.drop(vendorObjectId);
	}

	sessionActive = false;

	return 0;
}

void VendorImageDesignSessionImplementation::forceCloseVendorSession(const String& reason) {
	ManagedReference<CreatureObject*> designer = designerCreature.get();

	if (designer == nullptr) {
		cancelSession();
		return;
	}

	Locker locker(designer);

	if (sessionActive) {
		ImageDesignRejectMessage* message = new ImageDesignRejectMessage(designer->getObjectID(), designer->getObjectID(), vendorObjectId, 0, 0);
		imageDesignData.insertToMessage(message);
		designer->sendMessage(message);

		if (!reason.isEmpty())
			designer->sendSystemMessage(reason);
	}

	cancelSession();
}

void VendorImageDesignSessionImplementation::cancelVendorImageDesign(uint64 designer, uint64 targetPlayer, uint64 tent, int type, const ImageDesignData& data) {
	ManagedReference<CreatureObject*> designerObject = designerCreature.get();

	if (designerObject == nullptr) {
		cancelSession();
		return;
	}

	Locker locker(designerObject);

	// Client cancelled: nothing has been applied to the vendor, so there is
	// nothing to restore. Echo the reject so the UI closes, then clean up.
	ImageDesignRejectMessage* message = new ImageDesignRejectMessage(designerObject->getObjectID(), designerObject->getObjectID(), vendorObjectId, 0, type);
	imageDesignData.insertToMessage(message);
	designerObject->sendMessage(message);

	cancelSession();
}

void VendorImageDesignSessionImplementation::updateVendorImageDesign(CreatureObject* updater, uint64 designer, uint64 targetPlayer, uint64 tent, int type, const ImageDesignData& data) {
	ManagedReference<CreatureObject*> designerObject = designerCreature.get();

	if (designerObject == nullptr || updater == nullptr) {
		cancelSession();
		return;
	}

	if (!sessionActive)
		return;

	// Only the owning designer may drive the session, and only against the
	// vendor captured at session start. Anything else is a forged message.
	if (updater != designerObject || designer != designerObject->getObjectID() || targetPlayer != vendorObjectId) {
		designerObject->error() << "VendorImageDesignSession: rejected mismatched update designer=" << designer << " target=" << targetPlayer << " expectedTarget=" << vendorObjectId;
		forceCloseVendorSession("This vendor cannot be customized.");
		return;
	}

	ManagedReference<CreatureObject*> vendor = vendorCreature.get();

	Locker locker(designerObject);

	if (vendor == nullptr || !isVendorSessionValid(false)) {
		forceCloseVendorSession("This vendor cannot be customized.");
		return;
	}

	Locker clocker(vendor, designerObject);

	imageDesignData = data;

	// Preview updates are client-side only; nothing is relayed to the NPC and
	// nothing is applied until the designer commits.
	if (!imageDesignData.isAcceptedByDesigner())
		return;

	ImageDesignManager* imageDesignManager = ImageDesignManager::instance();

	if (imageDesignManager == nullptr) {
		forceCloseVendorSession("This vendor cannot be customized.");
		return;
	}

	String speciesGender = getDesignableSpeciesGender(vendor);

	if (speciesGender.isEmpty()) {
		forceCloseVendorSession("This vendor cannot be customized.");
		return;
	}

	VectorMap<String, float>* bodyAttributes = imageDesignData.getBodyAttributesMap();
	VectorMap<String, uint32>* colorAttributes = imageDesignData.getColorAttributesMap();

	// Validate the whole request before touching the vendor so an invalid
	// request can never leave a partially applied appearance.
	bool validRequest = true;
	String invalidField;

	for (int i = 0; i < bodyAttributes->size() && validRequest; ++i) {
		const String& name = bodyAttributes->elementAt(i).getKey();
		float value = bodyAttributes->elementAt(i).getValue();
		const Vector<CustomizationData>* customData = imageDesignManager->getCustomizationData(speciesGender, name);

		if (customData == nullptr || customData->size() == 0 || !(value >= 0.f && value <= 1.f)) {
			validRequest = false;
			invalidField = "body:" + name;
		}
	}

	for (int i = 0; i < colorAttributes->size() && validRequest; ++i) {
		const String& name = colorAttributes->elementAt(i).getKey();
		uint32 value = colorAttributes->elementAt(i).getValue();
		const Vector<CustomizationData>* customData = imageDesignManager->getCustomizationData(speciesGender, name);

		if (customData == nullptr || customData->size() == 0 || value > 255) {
			validRequest = false;
			invalidField = "color:" + name;
		}
	}

	String hairTemplate = imageDesignData.getHairTemplate();

	if (validRequest && type == 1) {
		if (hairTemplate.isEmpty()) {
			validRequest = CustomizationIdManager::instance()->canBeBald(speciesGender);
		} else {
			HairAssetData* hairAssetData = CustomizationIdManager::instance()->getHairAssetData(hairTemplate);

			validRequest = hairAssetData != nullptr &&
				hairAssetData->getServerPlayerTemplate() == "object/creature/player/" + speciesGender + ".iff";
		}

		if (!validRequest)
			invalidField = "hair:" + hairTemplate;
	}

	if (!validRequest) {
		error() << "Rejected vendor design for vendor " << vendorObjectId << " (" << speciesGender << ") by " << designerObject->getObjectID() << ": invalid " << invalidField;
		designerObject->sendSystemMessage("The selected appearance options are not valid for this vendor.");
		forceCloseVendorSession("");
		return;
	}

	ManagedReference<TangibleObject*> hairObject = vendor->getSlottedObject("hair").castTo<TangibleObject*>();

	// Hair style change. Mirrors ImageDesignSession: the old hair's colour
	// customization is carried onto the new style.
	if (type == 1) {
		ManagedReference<TangibleObject*> currentHair = hairObject;
		String oldCustomization;

		if (currentHair != nullptr) {
			hairObject = nullptr;

			Locker hlock(currentHair);
			currentHair->getCustomizationString(oldCustomization);

			currentHair->destroyObjectFromWorld(true);
			currentHair->destroyObjectFromDatabase();
		}

		hairObject = imageDesignManager->createHairObject(designerObject, vendor, hairTemplate, oldCustomization);
	}

	int modificationType = ImageDesignManager::NONE;

	for (int i = 0; i < bodyAttributes->size(); ++i) {
		VectorMapEntry<String, float>* entry = &bodyAttributes->elementAt(i);
		imageDesignManager->updateCustomization(designerObject, entry->getKey(), entry->getValue(), modificationType, vendor);
	}

	for (int i = 0; i < colorAttributes->size(); ++i) {
		VectorMapEntry<String, uint32>* entry = &colorAttributes->elementAt(i);
		imageDesignManager->updateColorCustomization(designerObject, entry->getKey(), entry->getValue(), hairObject, modificationType, vendor);
	}

	if (type == 1 && hairObject != nullptr)
		imageDesignManager->updateHairObject(vendor, hairObject);

	// Payment, tips, XP, holo-emotes and stat migration are deliberately not
	// processed in the vendor context.

	info(true) << "Vendor " << vendorObjectId << " appearance updated by owner " << designerObject->getObjectID() << " (" << speciesGender << ", type " << type << ", body " << bodyAttributes->size() << ", color " << colorAttributes->size() << ")";

	designerObject->sendSystemMessage("Your vendor's appearance has been updated successfully.");

	// Report the change as accepted by the target so the designer's client
	// treats the session as completed, as it would for a player target.
	imageDesignData.setAcceptedByTarget(true);

	ImageDesignChangeMessage* message = new ImageDesignChangeMessage(designerObject->getObjectID(), designer, targetPlayer, 0, type);
	imageDesignData.insertToMessage(message);
	designerObject->sendMessage(message);

	cancelSession();
}
