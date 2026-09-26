/*
 * SpeciesChangeManager.h
 *
 * Bellum Gero: Species Change Token support.
 *
 * Core3 stores a player CreatureObject's species/gender/race entirely inside its (transient,
 * template-derived) SharedCreatureObjectTemplate -- there is no mutable "species" field to just
 * set. Changing an existing, already-created character's species therefore means swapping the
 * underlying player template on a live object, which nothing in Core3 has ever done before (every
 * existing call to CreatureObject::loadTemplateData() happens immediately after creating a brand
 * new object, before it is ever shown to a client). This manager centralizes that operation --
 * validation, the template swap itself, and the species-dependent state that must be rebuilt
 * afterward (HAM, appearance, hair) -- separately from the Species Change Token item's Lua radial
 * handler, so the logic can be reused later (e.g. by a GM command) without duplicating it.
 *
 * See MMOCoreORB/docs/species_change_token.md for the full design writeup, the reasoning behind
 * each safety decision made here, and known limitations.
 */

#ifndef SPECIESCHANGEMANAGER_H_
#define SPECIESCHANGEMANAGER_H_

#include "engine/engine.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
	class CreatureObject;
}
}
}
}

namespace server {
namespace zone {
namespace objects {
namespace scene {
	class SceneObject;
}
}
}
}

namespace server {
namespace zone {
namespace managers {
namespace player {
namespace creation {
	class RacialCreationData;
}
}
}
}
}

using namespace server::zone::objects::creature;
using namespace server::zone::objects::scene;
using namespace server::zone::managers::player::creation;

namespace server {
namespace zone {
namespace managers {
namespace player {

class SpeciesChangeManager : public Singleton<SpeciesChangeManager>, public Logger, public Object {
public:
	SpeciesChangeManager();
	~SpeciesChangeManager();

	/**
	 * Returns true if creature has no player-equippable wearable, weapon, or wearable-container
	 * (backpack) item slotted -- i.e. armor, clothing, robes, jewelry, weapons, and backpacks are
	 * all absent. Hair and the standard containers (inventory/bank/datapad/mission_bag) are plain
	 * SceneObjects/TangibleObjects, not wearables or weapons, so they never block this check. The
	 * innate "default_weapon" (every creature's unarmed fists, always slotted, never removable) is
	 * explicitly excluded -- see findBlockingEquipment(). Logs full diagnostic detail about the
	 * blocking item, if any, via logBlockingEquipment().
	 */
	bool isNaked(CreatureObject* creature) const;

	/**
	 * Checks every non-species, non-naked safety precondition (is an actual player character; not
	 * dead/incapacitated/in combat/mounted/piloting; not logging out, link-dead, or teleporting; does
	 * not have an active stat-migration session open -- see applySpeciesChange()'s HAM-reset comment
	 * for why). Returns an empty string if creature may proceed, otherwise a player-facing reason the
	 * attempt was blocked.
	 */
	String getBlockedReason(CreatureObject* creature) const;

	/**
	 * Returns the species names creature's character may change into: every species in Races.h
	 * (the authoritative TEMPLATE registry used by character creation and everything else -- not
	 * modified by this feature) that (a) is on the Species Change Token's own destination allowlist
	 * (see isApprovedDestinationSpecies()), (b) has a template for creature's CURRENT gender, and
	 * (c) isn't creature's current species. Races.h continuing to register every template it always
	 * has is intentional -- some of those species are simply not approved as Species Change Token
	 * destinations. Do not maintain a second, parallel copy of this filtering anywhere else; both
	 * this method and validateTargetSpecies() below call the same isApprovedDestinationSpecies().
	 */
	Vector<String> getEligibleSpeciesNames(CreatureObject* creature) const;

	/**
	 * Validates newSpeciesName alone (it is on the Species Change Token destination allowlist, it
	 * names a real species, that species has a template for creature's current gender, and it isn't
	 * creature's current species) without checking naked/state and without changing anything.
	 * Returns an empty string if valid, else a player-facing reason. This is the authoritative,
	 * final check -- it is always re-run from applySpeciesChange() immediately before committing, so
	 * a stale, manipulated, or unexpected SUI callback can never submit an unapproved species and
	 * have it accepted, even if it was never offered in the SUI list to begin with.
	 */
	String validateTargetSpecies(CreatureObject* creature, const String& newSpeciesName) const;

	/**
	 * Re-validates everything (blocked-reason state checks, naked check, target species) and, only
	 * if every check passes, performs the actual species change:
	 *
	 *  - swaps creature's underlying player template (species/gender/race/appearance filename all
	 *    come from this template, so this is the only way to actually change them);
	 *  - restores the character's name, which the template swap would otherwise clobber;
	 *  - adjusts base/current/max HAM by swapping out the old species' racial modifier for the new
	 *    species' (see resetSpeciesStats()'s comment for the full reasoning, including a hard-won
	 *    correction: the profession-derived baseline underneath the racial modifier is
	 *    species-independent and is deliberately left untouched, not reset to a species-only value);
	 *  - clears removable buffs and zeroes wounds/shock wounds first, so no temporary or stale
	 *    old-species HAM contribution leaks into the reset baseline or double-subtracts later;
	 *  - resets appearance customization to a valid empty/default state and removes the now
	 *    species-incompatible hair object;
	 *  - updates the `characters`/`characters_dirty` character-list database record so the login
	 *    character-select screen reflects the new species;
	 *  - logs the change; schedules a forced, clean disconnect so the new template is picked up
	 *    through the normal, already-trusted login code path rather than attempting to
	 *    live-rebroadcast a template change to already-connected observers (which Core3 has no
	 *    existing support for at all).
	 *
	 * Returns an empty string on success. Returns a player-facing failure reason on failure, in
	 * which case NOTHING is changed and the caller must not consume the token.
	 */
	String applySpeciesChange(CreatureObject* creature, const String& newSpeciesName) const;

private:
	/**
	 * Resets creature's base/current/max HAM (all 9 attributes) so that ONLY the species-dependent
	 * racial modifier component changes -- the old species' contribution is subtracted out and the
	 * new species' is added in, leaving everything else about the character's current allocation
	 * untouched:
	 *
	 *     newBaseHAM[i] = currentBaseHAM[i] - oldRacialData->getAttributeMod(i)
	 *                                       + newRacialData->getAttributeMod(i)
	 *
	 * clamped into the new species' attribute_limits.iff min/max.
	 *
	 * IMPORTANT, hard-won correction: an earlier version of this method reset HAM to
	 * "newTemplateBaseHAM[i] + newRacialData->getAttributeMod(i)" (the new player TEMPLATE's own raw
	 * baseHAM plus the racial modifier), believing that to be the formula
	 * PlayerCreationManager::addRacialMods() uses for a brand-new character. Tracing the actual
	 * createCharacter() call order proved that wrong: addProfessionStartingItems() runs
	 * IMMEDIATELY BEFORE addRacialMods() and unconditionally OVERWRITES base/current/max HAM with
	 * the chosen starting profession's own attribute_mod row (datatables/creation/profession_mods.iff,
	 * keyed by profession, NOT by species) -- so addRacialMods()'s "beforeRacial" is that profession
	 * baseline, and the player TEMPLATE's own baseHAM array is never actually read for this purpose
	 * at all. Using it here produced a flat, species-uniform, profession-blind result (verified: every
	 * converted-to-Human character ended up with base/max HAM = attribute_limits.iff's flat minimum
	 * on all 9 attributes, regardless of profession) that does not correspond to anything a real
	 * character creation flow produces.
	 *
	 * The racial-delta-only approach here sidesteps the problem instead of replicating it: an
	 * existing character has no single "starting profession" to fall back on (they may have mastered
	 * several), so rather than guess one, this preserves whatever profession-derived baseline (and
	 * any legitimate stat-migration redistribution since creation) is already present in
	 * currentBaseHAM -- since profession_mods.iff is species-independent, none of that needs to
	 * change for a species conversion -- and swaps out only the one component that Core3 actually
	 * ties to species: the racial modifier.
	 *
	 * Skill/profession HAM bonuses beyond the creation-time baseline are never written into base/max
	 * HAM at all regardless (SkillManager::awardSkill() applies them via the entirely separate
	 * CreatureObject::addSkillMod()/skillModList layer, retrieved live via getSkillMod()), so this
	 * method never needs to touch that layer either way.
	 *
	 * Before writing the adjustment, clears removable buffs (CreatureObject::clearBuffs(true, false)
	 * -- the same call Character Builder's "reset_buffs" option already uses, which properly reverses
	 * each buff's own HAM contribution via Buff::deactivate() rather than just deleting buff records)
	 * and zeroes wounds/shock wounds (mirroring Character Builder's "cleanse_character" option), so
	 * the resulting current HAM is a clean, fully-healed, un-buffed baseline with no stale
	 * old-species-derived damage/wound/buff arithmetic surviving into the new species.
	 */
	void resetSpeciesStats(CreatureObject* creature, const int (&currentBaseHAM)[9], RacialCreationData* oldRacialData, RacialCreationData* newRacialData, bool usingCuratedRacialData, const String& oldSpeciesName, const String& newSpeciesName) const;

	/**
	 * Species Change Token destination allowlist. Not every species Races.h registers a template
	 * for is currently approved as a destination for this feature -- several bg_species1.tre custom
	 * species are known not to work correctly (see the list in SpeciesChangeManager.cpp) and have
	 * been intentionally excluded by Bellum Gero staff, without removing their underlying templates/
	 * assets, which remain used elsewhere (e.g. character creation). This is the single place that
	 * policy is encoded; both getEligibleSpeciesNames() and validateTargetSpecies() call this, so
	 * the SUI list and final server-side validation can never disagree.
	 */
	bool isApprovedDestinationSpecies(const String& speciesName) const;

	/**
	 * Walks creature's slotted objects looking for the first genuine player-equipped item (armor,
	 * clothing, robe, jewelry, weapon, or wearable container/backpack), explicitly excluding the
	 * innate "default_weapon" slot (CreatureObject::getDefaultWeapon() -- the always-present,
	 * never-removable unarmed weapon every creature has, real or not equipped by the player). This
	 * exclusion mirrors the only other place in this codebase that walks a creature's slotted
	 * objects the same way, MannequinMenuComponent.cpp, which guards against the identical object
	 * via its own defaultWeaponID comparison. Returns nullptr if creature is fully naked.
	 */
	SceneObject* findBlockingEquipment(CreatureObject* creature) const;

	/** Logs full diagnostic detail (template, OID, slot/containment, name, type flags, parent) about
	 * a blocking equipment item found by findBlockingEquipment(), for Test Center troubleshooting. */
	void logBlockingEquipment(CreatureObject* creature, SceneObject* blocker) const;

	void forceRelog(CreatureObject* creature) const;
	void updateCharacterListRecord(CreatureObject* creature, const String& newTemplatePath, int newRace) const;
};

}
}
}
}

using namespace server::zone::managers::player;

#endif // SPECIESCHANGEMANAGER_H_
