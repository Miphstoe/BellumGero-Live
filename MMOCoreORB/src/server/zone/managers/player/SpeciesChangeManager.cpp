/*
 * SpeciesChangeManager.cpp
 *
 * Bellum Gero: Species Change Token support. See SpeciesChangeManager.h for the overall design
 * rationale and docs/species_change_token.md for the full writeup.
 */

#include "server/zone/managers/player/SpeciesChangeManager.h"

#include "server/db/ServerDatabase.h"
#include "server/ServerCore.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/ZoneClientSession.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/Races.h"
#include "server/zone/managers/player/creation/PlayerCreationManager.h"
#include "server/zone/packets/player/LogoutMessage.h"
#include "templates/manager/TemplateManager.h"
#include "templates/creature/PlayerCreatureTemplate.h"
#include "templates/creature/SharedCreatureObjectTemplate.h"

SpeciesChangeManager::SpeciesChangeManager() : Logger("SpeciesChangeManager") {
	setLogging(true);
	setGlobalLogging(true);
}

SpeciesChangeManager::~SpeciesChangeManager() {
}

// -- Species Change Token destination allowlist -----------------------------------------------
//
// Races.h remains the authoritative TEMPLATE registry (character creation, hair/customization
// compatibility, everything else) and is unmodified by this feature. This list is a narrower,
// Species-Change-Token-specific POLICY on top of it: some bg_species1.tre custom species are
// registered, playable-at-creation templates that are nonetheless known not to work correctly and
// have been intentionally excluded from this feature by Bellum Gero staff. Their templates/assets
// are left completely untouched elsewhere; they simply cannot be reached as a Species Change Token
// destination. Values are Races::Species[] strings (matched exactly, case-sensitive).
//
// Current policy:
//  - All 10 original SWG species remain approved: human, trandoshan, twilek, bothan, zabrak,
//    rodian, moncal, wookiee, sullustan, ithorian.
//  - Of the 37 bg_species1.tre custom species, these 8 are NOT approved destinations (known not to
//    work correctly -- do not add back without an explicit decision to do so): cerean, droid, dug,
//    iktotchi, jenet, mirialan, togorian, zeltron.
//  - Every other bg_species1.tre custom species remains approved, explicitly including talz
//    (male-only), and nightsister/togruta/smc (all three female-only).
static const char* SPECIES_CHANGE_APPROVED_SPECIES[] = {
	// Original 10 SWG species
	"human", "trandoshan", "twilek", "bothan", "zabrak", "rodian", "moncal", "wookiee", "sullustan", "ithorian",

	// bg_species1.tre custom species -- approved (29 of the 37; see exclusions below)
	"aqualish", "bith", "chadra_fan", "chiss", "devaronian", "ewok", "hutt", "sanyassan",
	"abyssin", "arcona", "duros", "feeorin", "geonosian", "gotal", "gran", "gungan",
	"ishi_tib", "kel_dor", "kubaz", "nautolan", "nikto", "ortolan", "quarren", "talz",
	"toydarian", "weequay", "nightsister", "togruta", "smc",

	// NOT included -- intentionally excluded (not working correctly): cerean, droid, dug, iktotchi,
	// jenet, mirialan, togorian, zeltron.

	nullptr
};

bool SpeciesChangeManager::isApprovedDestinationSpecies(const String& speciesName) const {
	for (int i = 0; SPECIES_CHANGE_APPROVED_SPECIES[i] != nullptr; ++i) {
		if (speciesName == SPECIES_CHANGE_APPROVED_SPECIES[i])
			return true;
	}

	return false;
}

SceneObject* SpeciesChangeManager::findBlockingEquipment(CreatureObject* creature) const {
	if (creature == nullptr)
		return nullptr;

	// Every CreatureObject always has an innate, never-removable unarmed weapon slotted under the
	// fixed name "default_weapon" (CreatureObjectImplementation::getDefaultWeapon() ==
	// getSlottedObject("default_weapon")) -- it is a genuine WeaponObject, so isWeaponObject() on it
	// returns true even on a character wearing/holding absolutely nothing else. This was the root
	// cause of a fully naked character always failing this check: it must be excluded by object
	// identity, exactly like the only other place in this codebase that walks a creature's slotted
	// objects looking for real wearables/weapons (MannequinMenuComponent.cpp) already does via its
	// own defaultWeaponID comparison.
	WeaponObject* defaultWeapon = creature->getDefaultWeapon();
	uint64 defaultWeaponID = defaultWeapon != nullptr ? defaultWeapon->getObjectID() : 0;

	for (int i = 0; i < creature->getSlottedObjectsSize(); ++i) {
		SceneObject* slotted = creature->getSlottedObject(i);

		if (slotted == nullptr)
			continue;

		if (slotted->getObjectID() == defaultWeaponID)
			continue;

		// Armor/clothing/robes/jewelry are all WearableObject; backpacks are
		// WearableContainerObject (not WearableObject); real (non-innate) weapons are WeaponObject.
		// Hair is a plain TangibleObject (neither), and inventory/bank/datapad/mission_bag are plain
		// containers (neither either), so both are correctly excluded from this check automatically.
		if (slotted->isWearableObject() || slotted->isWeaponObject() || slotted->isWearableContainerObject())
			return slotted;
	}

	return nullptr;
}

void SpeciesChangeManager::logBlockingEquipment(CreatureObject* creature, SceneObject* blocker) const {
	if (creature == nullptr || blocker == nullptr)
		return;

	String templatePath = "unknown";
	uint32 templateCRC = 0;

	if (blocker->getObjectTemplate() != nullptr) {
		templatePath = blocker->getObjectTemplate()->getFullTemplateString();
		templateCRC = blocker->getServerObjectCRC();
	}

	// getSlottedObject(int)/getSlottedObjectsSize() (used by findBlockingEquipment above) only index
	// positionally; the actual slot NAME(s) an object occupies come from its own containment type
	// (containmentType - 4 == the arrangement group index into its own template's arrangement
	// descriptor list) rather than from the parent, so ask the object itself for logging purposes.
	String slotInfo = "containmentType=" + String::valueOf(blocker->getContainmentType());

	if (blocker->getContainmentType() >= 4) {
		const Vector<String>* arrangement = blocker->getArrangementDescriptor(blocker->getContainmentType() - 4);

		if (arrangement != nullptr) {
			StringBuffer slots;

			for (int i = 0; i < arrangement->size(); ++i) {
				if (i > 0)
					slots << ",";

				slots << arrangement->get(i);
			}

			if (!slots.toString().isEmpty())
				slotInfo = slots.toString();
		}
	}

	String parentInfo = "none";
	SceneObject* parent = blocker->getParent().get();

	if (parent != nullptr)
		parentInfo = parent->getDisplayedName() + " [" + String::valueOf(parent->getObjectID()) + "]";

	error() << "SpeciesChange: equipment validation failed for " << creature->getFirstName()
			<< " [" << creature->getObjectID() << "]";

	error() << "Blocking equipment: " << templatePath << " OID=" << blocker->getObjectID()
			<< " templateCRC=" << templateCRC << " slot=" << slotInfo
			<< " name=\"" << blocker->getDisplayedName() << "\""
			<< " isWearable=" << blocker->isWearableObject()
			<< " isWeapon=" << blocker->isWeaponObject()
			<< " isWearableContainer=" << blocker->isWearableContainerObject()
			<< " isTangible=" << blocker->isTangibleObject()
			<< " parent=" << parentInfo;
}

bool SpeciesChangeManager::isNaked(CreatureObject* creature) const {
	SceneObject* blocker = findBlockingEquipment(creature);

	if (blocker != nullptr) {
		logBlockingEquipment(creature, blocker);
		return false;
	}

	return true;
}

String SpeciesChangeManager::getBlockedReason(CreatureObject* creature) const {
	if (creature == nullptr || !creature->isPlayerCreature())
		return "You cannot use a Species Change Token.";

	if (creature->isDead())
		return "You cannot use a Species Change Token while dead.";

	if (creature->isIncapacitated())
		return "You cannot use a Species Change Token while incapacitated.";

	if (creature->isInCombat())
		return "You cannot use a Species Change Token while in combat.";

	if (creature->isRidingMount() || creature->hasRidingCreature())
		return "You cannot use a Species Change Token while mounted.";

	if (creature->isPilotingShip())
		return "You cannot use a Species Change Token while piloting a ship.";

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return "You cannot use a Species Change Token.";

	if (ghost->isLoggingOut())
		return "You cannot use a Species Change Token while logging out.";

	if (ghost->isLinkDead())
		return "You cannot use a Species Change Token right now. Please try again in a moment.";

	if (ghost->isTeleporting())
		return "You cannot use a Species Change Token while traveling.";

	return "";
}

Vector<String> SpeciesChangeManager::getEligibleSpeciesNames(CreatureObject* creature) const {
	Vector<String> result;

	if (creature == nullptr || creature->getObjectTemplate() == nullptr)
		return result;

	String currentFullTemplate = creature->getObjectTemplate()->getFullTemplateString();
	int currentRaceId = Races::getRaceID(currentFullTemplate);
	String currentGender = Races::getGender(currentRaceId);
	String currentSpeciesName = creature->getSpeciesName();

	for (int i = 0; i < TotalRaces; ++i) {
		String species = Races::getSpecies(i);
		String gender = Races::getGender(i);

		if (gender != currentGender)
			continue;

		if (species == currentSpeciesName)
			continue;

		if (!isApprovedDestinationSpecies(species))
			continue;

		if (!result.contains(species))
			result.add(species);
	}

	return result;
}

String SpeciesChangeManager::validateTargetSpecies(CreatureObject* creature, const String& newSpeciesName) const {
	if (creature == nullptr || creature->getObjectTemplate() == nullptr)
		return "Invalid character.";

	if (newSpeciesName.isEmpty())
		return "You must select a species.";

	if (newSpeciesName == creature->getSpeciesName())
		return "You are already that species.";

	// Authoritative, final gate against the Species Change Token's own destination allowlist. This
	// runs unconditionally on every call -- including from applySpeciesChange() immediately before
	// committing -- so a stale, manipulated, or otherwise unexpected SUI callback can never submit
	// an unapproved species and have it accepted, even one that was never offered in the SUI list.
	if (!isApprovedDestinationSpecies(newSpeciesName)) {
		error() << "SpeciesChange: rejected unsupported destination species '" << newSpeciesName
				<< "' for " << creature->getFirstName() << " [" << creature->getObjectID() << "]";

		return "That species is not currently available for species change.";
	}

	String currentFullTemplate = creature->getObjectTemplate()->getFullTemplateString();
	int currentRaceId = Races::getRaceID(currentFullTemplate);
	String currentGender = Races::getGender(currentRaceId);

	int newRaceId = Races::getRaceIDForSpeciesGender(newSpeciesName, currentGender);

	if (newRaceId < 0)
		return "That species is not available for your character's gender.";

	return "";
}

String SpeciesChangeManager::applySpeciesChange(CreatureObject* creature, const String& newSpeciesName) const {
	if (creature == nullptr)
		return "Invalid character.";

	Locker locker(creature);

	// Re-validate everything from scratch -- this is the "immediately before commit" safety check.
	// Nothing above this point in the overall workflow (naked check, species selection,
	// confirmation dialog) can be trusted, since time has passed and the player could have equipped
	// an item, entered combat, traded the token away, etc. since any earlier check ran.
	String blockedReason = getBlockedReason(creature);

	if (!blockedReason.isEmpty())
		return blockedReason;

	if (!isNaked(creature))
		return "You must remove all equipped items before using a Species Change Token. Place all weapons, armor, clothing, jewelry, backpacks, and other equipped items into your inventory, then try again.";

	String speciesError = validateTargetSpecies(creature, newSpeciesName);

	if (!speciesError.isEmpty())
		return speciesError;

	SharedObjectTemplate* oldTemplate = creature->getObjectTemplate();

	if (oldTemplate == nullptr)
		return "Your character's current template could not be read.";

	String oldFullTemplate = oldTemplate->getFullTemplateString();
	int oldRaceId = Races::getRaceID(oldFullTemplate);
	String oldSpeciesName = creature->getSpeciesName();
	String gender = Races::getGender(oldRaceId);

	int newRaceId = Races::getRaceIDForSpeciesGender(newSpeciesName, gender);

	if (newRaceId < 0)
		return "That species is not available for your character's gender.";

	String newFullTemplate = Races::getCCRace(newRaceId);

	if (newFullTemplate.isEmpty())
		return "That species could not be resolved to a template.";

	uint32 newCRC = newFullTemplate.hashCode();

	SharedObjectTemplate* newTemplate = TemplateManager::instance()->getTemplate(newCRC);

	if (newTemplate == nullptr) {
		error("Species Change: target template not registered: " + newFullTemplate);
		return "That species is not currently available on this server. Please contact staff.";
	}

	if (dynamic_cast<PlayerCreatureTemplate*>(newTemplate) == nullptr) {
		error("Species Change: target template is not a player template: " + newFullTemplate);
		return "That species is not currently available on this server. Please contact staff.";
	}

	SharedCreatureObjectTemplate* oldCreoTemplate = dynamic_cast<SharedCreatureObjectTemplate*>(oldTemplate);
	SharedCreatureObjectTemplate* newCreoTemplate = dynamic_cast<SharedCreatureObjectTemplate*>(newTemplate);

	if (oldCreoTemplate == nullptr || newCreoTemplate == nullptr) {
		error("Species Change: template is not a creature template (old=" + oldFullTemplate + " new=" + newFullTemplate + ")");
		return "Your species could not be changed due to a server data error. Please contact staff.";
	}

	String oldRacialKey = oldTemplate->getTemplateFileName();
	String newRacialKey = newTemplate->getTemplateFileName();

	PlayerCreationManager* pcm = PlayerCreationManager::instance();

	RacialCreationData* oldRacialData = pcm->getRacialCreationData(oldRacialKey);
	RacialCreationData* newRacialData = pcm->getRacialCreationData(newRacialKey);

	if (oldRacialData == nullptr || newRacialData == nullptr) {
		error("Species Change: missing racial creation data (old=" + oldRacialKey + " new=" + newRacialKey + ")");
		return "Your species could not be changed due to a server data error. Please contact staff.";
	}

	const Vector<int>& oldBaseHAM = oldCreoTemplate->getBaseHAM();
	const Vector<int>& newBaseHAM = newCreoTemplate->getBaseHAM();

	// Capture everything that must survive the template swap BEFORE calling loadTemplateData(),
	// which unconditionally resets a CreatureObject's species-derived fields (HAM, height, speed) to
	// the NEW template's raw defaults, and -- much less obviously -- also resets
	// SceneObject::customName (the character's actual chosen name!) from the template's own,
	// normally-empty-for-player-templates customName field. Both are manually reinstated below.
	UnicodeString originalFullName = creature->getCustomObjectName();

	int currentBaseHAM[9];

	for (int i = 0; i < 9; ++i)
		currentBaseHAM[i] = creature->getBaseHAM(i);

	// -- Point of no return: actually swap the underlying player template. --
	//
	// This is the one, novel, unprecedented part of this feature: Core3 has no existing code path
	// that changes a live, already-observed CreatureObject's template. Every existing call to
	// loadTemplateData() happens immediately after createObject(), before the object is ever shown
	// to any client. We deliberately do not attempt to live-rebroadcast the resulting appearance
	// change to nearby observers (Core3 has no supported mechanism for that either); instead we
	// force a clean disconnect right after (see forceRelog below) so the next login re-derives
	// everything -- species, appearance, template -- through the exact same, already-trusted
	// character-login code path used for every other character, instead of a bespoke one.
	creature->setServerObjectCRC(newCRC);
	creature->loadTemplateData(newTemplate);

	// Restore the character's actual name (see comment above).
	creature->setCustomObjectName(originalFullName, false);

	// Recompute HAM: preserve every point of legitimate progression (skills, prior stat migration,
	// etc.) by shifting the player's EXISTING base HAM by the delta between the two species'
	// (template baseline + racial modifier) instead of overwriting it with the new template's raw
	// starting values, which would silently erase a played character's entire HAM growth. Then
	// clamp into the new species' attribute_limits.iff min/max so the result can never be invalid,
	// even though the total may not exactly match the new species' total cap -- the player can use
	// the existing stat migration tool (Image Designer) afterward to rebalance if they want to.
	for (int i = 0; i < 9; ++i) {
		int oldStarting = (i < oldBaseHAM.size() ? oldBaseHAM.get(i) : 0) + oldRacialData->getAttributeMod(i);
		int newStarting = (i < newBaseHAM.size() ? newBaseHAM.get(i) : 0) + newRacialData->getAttributeMod(i);

		int delta = newStarting - oldStarting;
		int adjusted = currentBaseHAM[i] + delta;

		int minLimit = pcm->getMinimumAttributeLimit(newSpeciesName, i);
		int maxLimit = pcm->getMaximumAttributeLimit(newSpeciesName, i);

		if (adjusted < minLimit)
			adjusted = minLimit;
		else if (adjusted > maxLimit)
			adjusted = maxLimit;

		creature->setBaseHAM(i, adjusted, false);
		creature->setHAM(i, adjusted, false);
		creature->setMaxHAM(i, adjusted, false);
	}

	// Appearance: there is no existing Core3 mechanism to synthesize a valid randomized default
	// appearance for an arbitrary template (Image Designer only ever nudges an EXISTING, already
	// valid customization within the SAME species -- it never resets to a template default). An
	// empty customization string sets zero variables, so it is guaranteed valid for any species, and
	// matches the state of a template that has never been customized. The player can fully
	// re-customize via any Image Designer terminal afterward.
	creature->setCustomizationString("");

	// Hair: the old hair object is tied to the old species/gender's appearance file and is not valid
	// for the new one (PlayerCreationManager::addHair() gates on exactly this via
	// HairAssetData::getServerPlayerTemplate() at character creation). There is no reverse lookup
	// ("valid hairstyles for species X") anywhere in Core3 to automatically pick a new one, so --
	// exactly like an already-bald character -- we remove the old hair object entirely rather than
	// risk attaching one that is invalid for the new species. The player can pick a new hairstyle via
	// any Image Designer terminal afterward.
	ManagedReference<SceneObject*> oldHair = creature->getSlottedObject("hair");

	if (oldHair != nullptr) {
		Locker hairLocker(oldHair, creature);

		oldHair->destroyObjectFromWorld(true);
		oldHair->destroyObjectFromDatabase(true);
	}

	updateCharacterListRecord(creature, newFullTemplate, newCreoTemplate->getRace());

	info(true) << "SpeciesChange: " << creature->getFirstName() << " [" << creature->getObjectID()
			<< "] changed " << oldSpeciesName << " -> " << newSpeciesName;

	forceRelog(creature);

	return "";
}

void SpeciesChangeManager::updateCharacterListRecord(CreatureObject* creature, const String& newTemplatePath, int newRace) const {
	// Mirrors PlayerManagerImplementation::setFirstName/setLastName's existing pattern for updating
	// the character-list side tables after a change to an already-created character: both
	// `characters` (the flushed/authoritative table) and `characters_dirty` (the not-yet-flushed
	// write-behind cache -- see ObjectManager's periodic REPLACE INTO characters ... FROM
	// characters_dirty) must be updated, or the login character-select screen (and the existing
	// custom-species CRC substitution fix in CharacterList.h, which is keyed off this exact
	// `template` column) will keep showing the character's old species after this change.
	ZoneServer* zoneServer = ServerCore::getZoneServer();

	if (zoneServer == nullptr) {
		error("Species Change: could not update character list record for [" + String::valueOf(creature->getObjectID()) + "], zone server unavailable");
		return;
	}

	int galaxyID = zoneServer->getGalaxyID();

	String escapedTemplate = newTemplatePath;
	Database::escapeString(escapedTemplate);

	StringBuffer dirtyQuery;
	dirtyQuery << "UPDATE `characters_dirty` SET `template` = '" << escapedTemplate << "', `race` = " << newRace
			<< " WHERE `character_oid` = '" << creature->getObjectID() << "' AND `galaxy_id` = '" << galaxyID << "'";

	ServerDatabase::instance()->executeStatement(dirtyQuery);

	StringBuffer query;
	query << "UPDATE `characters` SET `template` = '" << escapedTemplate << "', `race` = " << newRace
			<< " WHERE `character_oid` = '" << creature->getObjectID() << "' AND `galaxy_id` = '" << galaxyID << "'";

	ServerDatabase::instance()->executeStatement(query);
}

void SpeciesChangeManager::forceRelog(CreatureObject* creature) const {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost != nullptr)
		ghost->setLoggingOut();

	creature->sendSystemMessage("Your species change is complete. You will now be disconnected -- log back in to see your new character.");
	creature->sendMessage(new LogoutMessage());

	Reference<CreatureObject*> playerCreo = creature;

	Core::getTaskManager()->scheduleTask([playerCreo] {
		Reference<ZoneClientSession*> session = playerCreo->getClient();

		if (session != nullptr)
			session->disconnect(true);
	}, "speciesChangeRelogTask", 1000);
}
