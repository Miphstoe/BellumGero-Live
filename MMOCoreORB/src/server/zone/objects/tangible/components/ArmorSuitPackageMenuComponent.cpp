/*
 * ArmorSuitPackageMenuComponent.cpp
 *
 * Bellum Gero full-suit crafting.
 *
 * Suit-specific content lives in ArmorSuitDefinition records below while the
 * assembly path is shared. This keeps normal armor crafting unchanged and lets
 * future armor suits reuse the same package radial, validation, stat copying,
 * slicing propagation, and rollback behavior.
 */

#include "ArmorSuitPackageMenuComponent.h"

#include "server/zone/ZoneServer.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/tangible/wearables/ArmorObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"

namespace {
	const byte ASSEMBLE_SUIT = 100;

	struct ArmorSuitPieceDefinition {
		const char* templatePath;
		bool mitigatingArmor;
		int healthWorst;
		int healthBest;
		int actionWorst;
		int actionBest;
		int mindWorst;
		int mindBest;
	};

	struct ArmorSuitDefinition {
		const char* packageTemplatePath;
		const char* displayName;
		const ArmorSuitPieceDefinition* pieces;
		int pieceCount;
		int healthWorst;
		int healthBest;
		int actionWorst;
		int actionBest;
		int mindWorst;
		int mindBest;
	};

	const ArmorSuitPieceDefinition COMPOSITE_PIECES[] = {
		{"object/tangible/wearables/armor/composite/armor_composite_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/composite/armor_composite_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/composite/armor_composite_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition PADDED_PIECES[] = {
		{"object/tangible/wearables/armor/padded/armor_padded_s01_belt.iff", false, 0, 0, 0, 0, 0, 0},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/padded/armor_padded_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition CHITIN_PIECES[] = {
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/chitin/armor_chitin_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition BONE_PIECES[] = {
		{"object/tangible/wearables/armor/bone/armor_bone_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/bone/armor_bone_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition UBESE_PIECES[] = {
		{"object/tangible/wearables/armor/ubese/armor_ubese_bandolier.iff", false, 0, 0, 0, 0, 0, 0},
		{"object/tangible/wearables/armor/ubese/armor_ubese_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/ubese/armor_ubese_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ubese/armor_ubese_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ubese/armor_ubese_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ubese/armor_ubese_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/ubese/armor_ubese_jacket.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/ubese/armor_ubese_pants.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition ITHORIAN_GUARDIAN_PIECES[] = {
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/ithorian_guardian/ith_armor_s02_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition ITHORIAN_DEFENDER_PIECES[] = {
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/ithorian_defender/ith_armor_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition ITHORIAN_SENTINEL_PIECES[] = {
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition KASHYYYKIAN_CEREMONIAL_PIECES[] = {
		{"object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_chest_plate.iff", true, 350, 210, 157, 93, 400, 240},
		{"object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition KASHYYYKIAN_HUNTING_PIECES[] = {
		{"object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_chest_plate.iff", true, 350, 210, 157, 93, 400, 240},
		{"object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition KASHYYYKIAN_BLACK_MTN_PIECES[] = {
		{"object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_chest_plate.iff", true, 350, 210, 157, 93, 400, 240},
		{"object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition CLONETROOPER_PIECES[] = {
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_imperial_s01_belt.iff", false, 0, 0, 0, 0, 0, 0},
	};

	const ArmorSuitPieceDefinition CLONE_501ST_PIECES[] = {
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_neutral_s01_belt.iff", false, 0, 0, 0, 0, 0, 0},
	};

	const ArmorSuitPieceDefinition CLONE_CORUSCANT_PIECES[] = {
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_leggings.iff", true, 75, 45, 175, 105, 25, 15},
		{"object/tangible/wearables/armor/clone_trooper/armor_clone_trooper_rebel_s01_belt.iff", false, 0, 0, 0, 0, 0, 0},
	};

	const ArmorSuitPieceDefinition BOUNTY_HUNTER_PIECES[] = {
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_belt.iff", false, 0, 0, 0, 0, 0, 0},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitPieceDefinition STORMTROOPER_PIECES[] = {
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_bracer_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_bracer_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_gloves.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_leggings.iff", true, 75, 45, 175, 105, 25, 15},
		{"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_utility_belt.iff", false, 0, 0, 0, 0, 0, 0},
	};

	const ArmorSuitPieceDefinition MARINE_PIECES[] = {
		{"object/tangible/wearables/armor/marine/armor_marine_bicep_l.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/marine/armor_marine_bicep_r.iff", true, 25, 15, 22, 13, 25, 15},
		{"object/tangible/wearables/armor/marine/armor_marine_boots.iff", true, 25, 15, 44, 26, 25, 15},
		{"object/tangible/wearables/armor/marine/armor_marine_chest_plate.iff", true, 250, 150, 66, 39, 25, 15},
		{"object/tangible/wearables/armor/marine/armor_marine_helmet.iff", true, 25, 15, 22, 13, 300, 180},
		{"object/tangible/wearables/armor/marine/armor_marine_leggings.iff", true, 75, 45, 175, 105, 25, 15},
	};

	const ArmorSuitDefinition SUIT_DEFINITIONS[] = {
		{
			"object/tangible/wearables/armor/composite/armor_composite_suit_package.iff",
			"Composite Armor Suit",
			COMPOSITE_PIECES,
			sizeof(COMPOSITE_PIECES) / sizeof(COMPOSITE_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/padded/armor_padded_suit_package.iff",
			"Padded Armor Suit",
			PADDED_PIECES,
			sizeof(PADDED_PIECES) / sizeof(PADDED_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/chitin/armor_chitin_suit_package.iff",
			"Chitin Armor Suit",
			CHITIN_PIECES,
			sizeof(CHITIN_PIECES) / sizeof(CHITIN_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/bone/armor_bone_suit_package.iff",
			"Bone Armor Suit",
			BONE_PIECES,
			sizeof(BONE_PIECES) / sizeof(BONE_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/ubese/armor_ubese_suit_package.iff",
			"Ubese Armor Suit",
			UBESE_PIECES,
			sizeof(UBESE_PIECES) / sizeof(UBESE_PIECES[0]),
			450, 270,
			373, 222,
			450, 270
		},
		{
			"object/tangible/wearables/armor/ithorian_guardian/armor_ithorian_guardian_suit_package.iff",
			"Ithorian Guardian Armor Suit",
			ITHORIAN_GUARDIAN_PIECES,
			sizeof(ITHORIAN_GUARDIAN_PIECES) / sizeof(ITHORIAN_GUARDIAN_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/ithorian_defender/armor_ithorian_defender_suit_package.iff",
			"Ithorian Defender Armor Suit",
			ITHORIAN_DEFENDER_PIECES,
			sizeof(ITHORIAN_DEFENDER_PIECES) / sizeof(ITHORIAN_DEFENDER_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/ithorian_sentinel/armor_ithorian_sentinel_suit_package.iff",
			"Ithorian Sentinel Armor Suit",
			ITHORIAN_SENTINEL_PIECES,
			sizeof(ITHORIAN_SENTINEL_PIECES) / sizeof(ITHORIAN_SENTINEL_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/kashyyykian_ceremonial/armor_kashyyykian_ceremonial_suit_package.iff",
			"Kashyyykian Ceremonial Armor Suit",
			KASHYYYKIAN_CEREMONIAL_PIECES,
			sizeof(KASHYYYKIAN_CEREMONIAL_PIECES) / sizeof(KASHYYYKIAN_CEREMONIAL_PIECES[0]),
			475, 285,
			376, 224,
			475, 285
		},
		{
			"object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_suit_package.iff",
			"Kashyyykian Hunting Armor Suit",
			KASHYYYKIAN_HUNTING_PIECES,
			sizeof(KASHYYYKIAN_HUNTING_PIECES) / sizeof(KASHYYYKIAN_HUNTING_PIECES[0]),
			475, 285,
			376, 224,
			475, 285
		},
		{
			"object/tangible/wearables/armor/kashyyykian_black_mtn/armor_kashyyykian_black_mtn_suit_package.iff",
			"Kashyyykian Black Mountain Armor Suit",
			KASHYYYKIAN_BLACK_MTN_PIECES,
			sizeof(KASHYYYKIAN_BLACK_MTN_PIECES) / sizeof(KASHYYYKIAN_BLACK_MTN_PIECES[0]),
			475, 285,
			376, 224,
			475, 285
		},
		{
			"object/tangible/wearables/armor/clone_trooper/armor_clonetrooper_suit_package.iff",
			"Phase II Clone Trooper Armor Suit",
			CLONETROOPER_PIECES,
			sizeof(CLONETROOPER_PIECES) / sizeof(CLONETROOPER_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/clone_trooper/armor_501st_clonetrooper_suit_package.iff",
			"501st Clone Trooper Armor Suit",
			CLONE_501ST_PIECES,
			sizeof(CLONE_501ST_PIECES) / sizeof(CLONE_501ST_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/clone_trooper/armor_coruscant_clonetrooper_suit_package.iff",
			"Coruscant Guard Clone Trooper Armor Suit",
			CLONE_CORUSCANT_PIECES,
			sizeof(CLONE_CORUSCANT_PIECES) / sizeof(CLONE_CORUSCANT_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/bounty_hunter/armor_bounty_hunter_suit_package.iff",
			"Bounty Hunter Armor Suit",
			BOUNTY_HUNTER_PIECES,
			sizeof(BOUNTY_HUNTER_PIECES) / sizeof(BOUNTY_HUNTER_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/stormtrooper/armor_stormtrooper_suit_package.iff",
			"Stormtrooper Armor Suit",
			STORMTROOPER_PIECES,
			sizeof(STORMTROOPER_PIECES) / sizeof(STORMTROOPER_PIECES[0]),
			500, 300,
			417, 248,
			500, 300
		},
		{
			"object/tangible/wearables/armor/marine/armor_marine_suit_package.iff",
			"Marine Armor Suit",
			MARINE_PIECES,
			sizeof(MARINE_PIECES) / sizeof(MARINE_PIECES[0]),
			425, 255,
			351, 209,
			425, 255
		},
	};

	const int SUIT_DEFINITION_COUNT =
		sizeof(SUIT_DEFINITIONS) / sizeof(SUIT_DEFINITIONS[0]);

	float qualityFromEncumbrance(int value, int worst, int best) {
		if (worst <= best)
			return 0.f;

		float quality = static_cast<float>(worst - value) /
			static_cast<float>(worst - best);

		if (quality < 0.f)
			quality = 0.f;
		else if (quality > 1.f)
			quality = 1.f;

		return quality;
	}

	int mapPieceEncumbrance(float quality, int worst, int best) {
		float value = static_cast<float>(worst) -
			quality * static_cast<float>(worst - best);

		return static_cast<int>(value + 0.5f);
	}

	const ArmorSuitDefinition* getSuitDefinition(SceneObject* object) {
		if (object == nullptr || object->getObjectTemplate() == nullptr)
			return nullptr;

		String templatePath = object->getObjectTemplate()->getFullTemplateString();

		for (int i = 0; i < SUIT_DEFINITION_COUNT; ++i) {
			const ArmorSuitDefinition& definition = SUIT_DEFINITIONS[i];

			if (templatePath == definition.packageTemplatePath)
				return &definition;
		}

		return nullptr;
	}

	bool validateSuitDefinition(const ArmorSuitDefinition& definition) {
		if (definition.packageTemplatePath == nullptr ||
				definition.displayName == nullptr ||
				definition.pieces == nullptr ||
				definition.pieceCount <= 0)
			return false;

		if (definition.healthWorst <= definition.healthBest ||
				definition.actionWorst <= definition.actionBest ||
				definition.mindWorst <= definition.mindBest)
			return false;

		for (int i = 0; i < definition.pieceCount; ++i) {
			const ArmorSuitPieceDefinition& piece = definition.pieces[i];

			if (piece.templatePath == nullptr)
				return false;

			if (!piece.mitigatingArmor)
				continue;

			if (piece.healthWorst < piece.healthBest ||
					piece.actionWorst < piece.actionBest ||
					piece.mindWorst < piece.mindBest)
				return false;
		}

		return true;
	}

	void destroyGenerated(Vector<ManagedReference<ArmorObject*> >& generated) {
		for (int i = 0; i < generated.size(); ++i) {
			ManagedReference<ArmorObject*> piece = generated.get(i);

			if (piece == nullptr)
				continue;

			Locker locker(piece);
			piece->destroyObjectFromWorld(true);
			piece->destroyObjectFromDatabase(true);
		}

		generated.removeAll();
	}
}

void ArmorSuitPackageMenuComponent::fillObjectMenuResponse(
		SceneObject* sceneObject, ObjectMenuResponse* menuResponse,
		CreatureObject* player) const {

	TangibleObjectMenuComponent::fillObjectMenuResponse(
		sceneObject, menuResponse, player);

	if (sceneObject == nullptr || menuResponse == nullptr || player == nullptr)
		return;

	const ArmorSuitDefinition* definition = getSuitDefinition(sceneObject);

	if (definition == nullptr || !sceneObject->isASubChildOf(player))
		return;

	menuResponse->addRadialMenuItem(ASSEMBLE_SUIT, 3, "Assemble Armor Suit");
}

int ArmorSuitPackageMenuComponent::handleObjectMenuSelect(
		SceneObject* sceneObject, CreatureObject* player,
		byte selectedID) const {

	if (sceneObject == nullptr || player == nullptr)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(
			sceneObject, player, selectedID);

	const ArmorSuitDefinition* definition = getSuitDefinition(sceneObject);

	if (definition == nullptr)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(
			sceneObject, player, selectedID);

	ArmorObject* package = cast<ArmorObject*>(sceneObject);

	if (package == nullptr)
		return 0;

	if (selectedID == 69)
		return package->handleObjectMenuSelect(player, selectedID);

	if (selectedID != ASSEMBLE_SUIT)
		return TangibleObjectMenuComponent::handleObjectMenuSelect(
			sceneObject, player, selectedID);

	if (!validateSuitDefinition(*definition)) {
		player->sendSystemMessage(
			"This armor suit package has an invalid server definition. Please report this item to staff.");
		return 0;
	}

	ManagedReference<SceneObject*> inventory =
		player->getSlottedObject("inventory");

	if (inventory == nullptr ||
			!inventory->hasObjectInContainer(package->getObjectID())) {

		player->sendSystemMessage(
			"The armor suit package must be in your inventory to assemble it.");
		return 0;
	}

	int freeSlots =
		inventory->getContainerVolumeLimit() -
		inventory->getContainerObjectsSize();

	if (freeSlots < definition->pieceCount) {
		player->sendSystemMessage(
			"You need at least " +
			String::valueOf(definition->pieceCount) +
			" free inventory slots to assemble this " +
			String(definition->displayName) + ".");
		return 0;
	}

	Locker packageLocker(package);

	const int rawHealth = package->getBellumRawHealthEncumbrance();
	const int rawAction = package->getBellumRawActionEncumbrance();
	const int rawMind = package->getBellumRawMindEncumbrance();

	const float healthQuality =
		qualityFromEncumbrance(
			rawHealth,
			definition->healthWorst,
			definition->healthBest);

	const float actionQuality =
		qualityFromEncumbrance(
			rawAction,
			definition->actionWorst,
			definition->actionBest);

	const float mindQuality =
		qualityFromEncumbrance(
			rawMind,
			definition->mindWorst,
			definition->mindBest);

	Vector<ManagedReference<ArmorObject*> > generated;

	for (int i = 0; i < definition->pieceCount; ++i) {
		const ArmorSuitPieceDefinition& pieceDefinition =
			definition->pieces[i];

		String templatePath = pieceDefinition.templatePath;

		ManagedReference<ArmorObject*> piece =
			(player->getZoneServer()->createObject(
				templatePath.hashCode(), 1)).castTo<ArmorObject*>();

		if (piece == nullptr) {
			destroyGenerated(generated);

			player->sendSystemMessage(
				"Armor suit assembly failed while creating a piece. The package was not consumed.");
			return 0;
		}

		{
			Locker pieceLocker(piece);

			if (pieceDefinition.mitigatingArmor) {
				const int health =
					mapPieceEncumbrance(
						healthQuality,
						pieceDefinition.healthWorst,
						pieceDefinition.healthBest);

				const int action =
					mapPieceEncumbrance(
						actionQuality,
						pieceDefinition.actionWorst,
						pieceDefinition.actionBest);

				const int mind =
					mapPieceEncumbrance(
						mindQuality,
						pieceDefinition.mindWorst,
						pieceDefinition.mindBest);

				piece->initializeBellumSuitPieceFrom(
					package, health, action, mind);
			} else {
				// Non-mitigating armor-set accessories (currently Padded belt)
				// must remain normal accessory pieces.
				piece->setMaxSockets(4);

				String crafterName = package->getCraftersName();
				piece->setCraftersName(crafterName);
				piece->setCraftersID(package->getCraftersID());
			}
		}

		generated.add(piece);
	}

	for (int i = 0; i < generated.size(); ++i) {
		ManagedReference<ArmorObject*> piece = generated.get(i);

		if (piece == nullptr ||
				!inventory->transferObject(piece, -1, true)) {

			destroyGenerated(generated);

			player->sendSystemMessage(
				"Armor suit assembly could not transfer every piece. The package was not consumed.");
			return 0;
		}

		piece->sendTo(player, true);
	}

	package->destroyObjectFromWorld(true);
	package->destroyObjectFromDatabase(true);

	player->sendSystemMessage(
		String(definition->displayName) +
		" assembled: " +
		String::valueOf(definition->pieceCount) +
		" full-stat armor pieces have been placed in your inventory.");

	return 0;
}
