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
#include "server/zone/objects/scene/SessionFacadeType.h"
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

	// MigrateStatsSession is a purely transient, in-memory session (holds only the player's pending,
	// not-yet-committed attribute redistribution) -- it has no persisted state, so nothing about it
	// needs to be "reset" by a species change. But if one is left open while a species change
	// commits, a subsequent migrateStats() call on it would apply a pending allocation computed
	// against the OLD species' limits directly on top of the freshly-reset NEW species baseline,
	// producing an invalid mixed result. Simplest safe fix: just don't allow both at once.
	if (creature->containsActiveSession(SessionFacadeType::MIGRATESTATS))
		return "You cannot use a Species Change Token while a stat migration is in progress. Please finish or cancel it first.";

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
		// In practice this only happens if even the human_male fallback row itself is missing --
		// getRacialCreationData() falls back to human_male for any template with no curated row of
		// its own, so a true nullptr here means the racial creation data table failed to load at all.
		error("Species Change: missing racial creation data entirely (old=" + oldRacialKey + " new=" + newRacialKey + ") -- aborting, character unchanged");
		return "Your species could not be changed due to a server data error. Please contact staff.";
	}

	// BG: unlike character creation (which silently falls back to Human's numbers for the ~8
	// approved species missing a curated datatables/creation/racial_mods.iff/attribute_limits.iff
	// row -- an accepted, pre-existing, documented limitation), a permanent Species Change Token
	// conversion is held to a stricter bar: we do NOT abort for this (doing so would make Talz, one
	// of the four species this feature was explicitly extended to support, permanently unusable as a
	// destination), but we DO log it plainly so it is never silently mistaken for curated data.
	bool usingCuratedRacialData = pcm->hasCuratedRacialCreationData(newRacialKey);

	if (!usingCuratedRacialData) {
		error() << "SpeciesChange: destination species '" << newSpeciesName << "' (" << newRacialKey
				<< ") has no curated racial_mods.iff/attribute_limits.iff row -- using Human's numbers"
				<< " via PlayerCreationManager's existing character-creation fallback, exactly as a"
				<< " brand-new character of this species would get.";
	}

	// Capture everything that must survive the template swap BEFORE calling loadTemplateData(),
	// which unconditionally resets a CreatureObject's species-derived fields (HAM, height, speed) to
	// the NEW template's raw defaults, and -- much less obviously -- also resets
	// SceneObject::customName (the character's actual chosen name!) from the template's own,
	// normally-empty-for-player-templates customName field. Both are manually reinstated below.
	// currentBaseHAM specifically must be captured here too: it is the character's actual current
	// allocation (profession-derived baseline, plus whatever they have since stat-migrated), and
	// resetSpeciesStats() needs it as-is, not the raw values loadTemplateData() is about to overwrite
	// it with.
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

	resetSpeciesStats(creature, currentBaseHAM, oldRacialData, newRacialData, usingCuratedRacialData, oldSpeciesName, newSpeciesName);

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

void SpeciesChangeManager::resetSpeciesStats(CreatureObject* creature, const int (&currentBaseHAM)[9], RacialCreationData* oldRacialData, RacialCreationData* newRacialData, bool usingCuratedRacialData, const String& oldSpeciesName, const String& newSpeciesName) const {
	if (creature == nullptr || oldRacialData == nullptr || newRacialData == nullptr)
		return;

	PlayerCreationManager* pcm = PlayerCreationManager::instance();

	// Clear buffs BEFORE touching HAM. Buff::deactivate() (invoked by clearBuffs(), via each buff's
	// own removal path) is the only safe way to reverse whatever a buff already added to maxHAM --
	// resetting maxHAM first and letting a still-active buff be removed afterward on its own would
	// have it subtract its bonus from a maxHAM value it never actually contributed to, silently
	// corrupting the result. removeAll=false mirrors the exact call Character Builder's
	// "reset_buffs" option already uses (SuiManager.cpp) -- it respects each buff's own
	// removeOnClearBuffs() flag rather than force-clearing everything.
	creature->clearBuffs(true, false);

	// Zero current damage/wounds/battle fatigue so the character enters the new species in a clean,
	// fully-healed state rather than carrying old-species-relative damage forward. Mirrors Character
	// Builder's "cleanse_character" option exactly (SuiManager.cpp).
	for (int i = 0; i < 9; ++i)
		creature->setWounds(i, 0);

	creature->setShockWounds(0);

	// Purely for the diagnostic log line below -- not used for any game logic. Standard SWG HAM
	// attribute order, matching PlayerCreationManager::addRacialMods()'s 0-8 indexing.
	static const char* attributeNames[9] = {
			"health", "strength", "constitution",
			"action", "quickness", "stamina",
			"mind", "focus", "willpower"
	};

	StringBuffer hamLog;

	// Adjust base/current/max HAM by swapping the OLD species' racial modifier out for the NEW
	// species' -- everything else about the character's current allocation (profession-derived
	// baseline from creation, plus any legitimate stat-migration redistribution since) is preserved
	// as-is, because none of it is actually species-dependent (see the design comment on this method
	// in SpeciesChangeManager.h for the full reasoning and the incorrect formula this replaces).
	int bgSumBefore = 0;
	int bgSumAfter = 0;
	bool bgAnyClamped = false;

	for (int i = 0; i < 9; ++i) {
		int oldRacialMod = oldRacialData->getAttributeMod(i);
		int newRacialMod = newRacialData->getAttributeMod(i);
		int delta = newRacialMod - oldRacialMod;

		int adjusted = currentBaseHAM[i] + delta;
		int preClampHAM = adjusted;

		int minLimit = pcm->getMinimumAttributeLimit(newSpeciesName, i);
		int maxLimit = pcm->getMaximumAttributeLimit(newSpeciesName, i);

		// Clamp into the new species' declared range -- necessary in the general case (e.g. a
		// character who stat-migrated heavily toward one attribute under a species with a much wider
		// range than the destination species could otherwise end up above the new max). The
		// resulting total may not exactly match the new species' total cap either way; the existing
		// stat migration tool remains available afterward for the player to rebalance exactly if
		// they want to.
		if (adjusted < minLimit)
			adjusted = minLimit;
		else if (adjusted > maxLimit)
			adjusted = maxLimit;

		if (adjusted != preClampHAM)
			bgAnyClamped = true;

		bgSumBefore += currentBaseHAM[i];
		bgSumAfter += adjusted;

		creature->setBaseHAM(i, adjusted, false);
		creature->setHAM(i, adjusted, false);
		creature->setMaxHAM(i, adjusted, false);

		hamLog << " " << attributeNames[i] << "=" << adjusted << "(was=" << currentBaseHAM[i]
				<< ",oldRacialMod=" << oldRacialMod << ",newRacialMod=" << newRacialMod
				<< ",min=" << minLimit << ",max=" << maxLimit << ")";
	}

	int bgTotalAttributeLimit = pcm->getTotalAttributeLimit(newSpeciesName);

	// MigrateStatsSession (the stat migration UI's backing session) is purely transient/in-memory --
	// see getBlockedReason()'s comment -- so there is no persisted migration state to reset here.
	// Future stat migration sessions will read creature->getSpeciesName() (now the new species) and
	// creature->getBaseHAM() (now the values just set above) fresh, so the new species' min/max/total
	// limits are automatically what's enforced from this point on with no further action needed.
	// sumAfter is expected to still roughly track sumBefore (only the racial-modifier delta should
	// have moved it) -- it is not expected to equal totalAttributeLimit exactly (a character rarely
	// has every point allocated; that's what stat migration is for), so no SUM_MATCHES_TOTAL check is
	// meaningful here the way it was in the (incorrect) template-baseline formula this replaces.
	info(true) << "SpeciesChange: resetting base stats for " << creature->getFirstName() << " ["
			<< creature->getObjectID() << "]: " << oldSpeciesName << " -> " << newSpeciesName
			<< " | curatedRacialData=" << usingCuratedRacialData
			<< " | totalAttributeLimit=" << bgTotalAttributeLimit
			<< " | sumBeforeConversion=" << bgSumBefore
			<< " | sumAfterConversion=" << bgSumAfter
			<< " | anyAttributeClamped=" << bgAnyClamped
			<< " |" << hamLog.toString();

	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost != nullptr)
		ghost->recalculateForcePower();
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
