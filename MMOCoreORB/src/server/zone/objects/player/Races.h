/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef RACES_H_
#define RACES_H_

#include "system/lang.h"

const static char* Species[] = {
    "human", // human male
    "trandoshan", // trandoshan male
    "twilek", // twilek male
    "bothan", // bothan male
    "zabrak", // zabrak male
    "rodian", // rodian male
    "moncal", // moncal male
    "wookiee", // wookiee male
    "sullustan", // sullustan male
    "ithorian", // ithorian male
    "human", // human female
    "trandoshan", // trandoshan female
    "twilek", // twilek female
    "bothan", // bothan female
    "zabrak", // zabrak female
    "rodian", // rodian female
    "moncal", // moncal female
    "wookiee", // wookiee female
    "sullustan", // sullustan female
    "ithorian", // DA E7   -   ithorian female

    //-- Begin Bellum Gero bg_species1.tre custom species (raceid 20-66) --
    //-- Data extracted directly from bg_species1.tre (client IFFs + datatables/creation/*.iff). See
    //-- docs/bellum_species1_mapping.md for the full source mapping table and documented discrepancies.
    "aqualish", // aqualish male
    "aqualish", // aqualish female
    "bith", // bith male  -- species id COLLIDES with togorian (12), TRE did not assign unique ids
    "bith", // bith female  -- species id COLLIDES with togorian (12), TRE did not assign unique ids
    "chadra_fan", // chadra_fan male
    "chadra_fan", // chadra_fan female
    "chiss", // chiss male
    "chiss", // chiss female
    "devaronian", // devaronian male
    "devaronian", // devaronian female
    "ewok", // ewok male
    "ewok", // ewok female
    "hutt", // hutt male
    "hutt", // hutt female
    "mirialan", // mirialan male
    "mirialan", // mirialan female
    "sanyassan", // sanyassan male
    "sanyassan", // sanyassan female
    "zeltron", // zeltron male
    "zeltron", // zeltron female
    "abyssin", // abyssin male
    "arcona", // arcona male  -- species id COLLIDES with kel_dor/kubaz (10)
    "cerean", // cerean male
    "droid", // droid male
    "dug", // dug male
    "duros", // duros male
    "feeorin", // feeorin male  -- species id COLLIDES with human (0), TRE did not assign a unique id
    "geonosian", // geonosian male  -- species id COLLIDES with wookiee (4), TRE did not assign a unique id
    "gotal", // gotal male
    "gran", // gran male
    "gungan", // gungan male
    "iktotchi", // iktotchi male
    "ishi_tib", // ishi_tib male
    "jenet", // jenet male  -- species id COLLIDES with human (0), TRE did not assign a unique id
    "kel_dor", // kel_dor male  -- species id COLLIDES with arcona/kubaz (10)
    "kubaz", // kubaz male  -- species id COLLIDES with arcona/kel_dor (10)
    "nautolan", // nautolan male
    "nikto", // nikto male
    "ortolan", // ortolan male
    "quarren", // quarren male
    "talz", // talz male
    "togorian", // togorian male  -- species id COLLIDES with bith (12)
    "toydarian", // toydarian male
    "weequay", // weequay male
    "nightsister", // nightsister female  -- species id COLLIDES with human (0), TRE did not assign a unique id
    "togruta", // togruta female
    "smc" // smc female (Shadow Mountain Clan)  -- species id COLLIDES with human (0), TRE did not assign a unique id
    //-- End Bellum Gero bg_species1.tre custom species --
};

const static int TemplateSpecies[] = {
		0,
		2,
		6,
		5,
		7,
		1,
		3,
		4,
		0x31,
		0x21,
		0,
		2,
		6,
		5,
		7,
		1,
		3,
		4,
		0x31,
		0x21,

		//-- Begin Bellum Gero bg_species1.tre custom species (raceid 20-66) --
		//-- Raw "species" int field parsed directly out of each shared_<name>_<gender>.iff in bg_species1.tre.
		//-- Several values collide with each other and/or with the original 10 species (see Species[] comments
		//-- above and docs/bellum_species1_mapping.md); those collisions are baked into the TRE's binary data
		//-- and were NOT invented or altered here.
		9, // aqualish male
		9, // aqualish female
		12, // bith male
		12, // bith female
		14, // chadra_fan male
		14, // chadra_fan female
		11, // chiss male
		11, // chiss female
		17, // devaronian male
		17, // devaronian female
		22, // ewok male
		22, // ewok female
		31, // hutt male
		31, // hutt female
		21, // mirialan male
		21, // mirialan female
		25, // sanyassan male
		25, // sanyassan female
		24, // zeltron male
		24, // zeltron female
		8, // abyssin male
		10, // arcona male
		38, // cerean male
		44, // droid male
		19, // dug male
		20, // duros male
		0, // feeorin male
		4, // geonosian male
		27, // gotal male
		28, // gran male
		29, // gungan male
		45, // iktotchi male
		32, // ishi_tib male
		0, // jenet male
		10, // kel_dor male
		10, // kubaz male
		51, // nautolan male
		42, // nikto male
		43, // ortolan male
		46, // quarren male
		50, // talz male
		12, // togorian male
		53, // toydarian male
		55, // weequay male
		0, // nightsister female
		52, // togruta female
		0 // smc female
		//-- End Bellum Gero bg_species1.tre custom species --
};

const static char* Gender[] = {
    "male", // human male
    "male", // trandoshan male
    "male", // twilek male
    "male", // bothan male
    "male", // zabrak male
    "male", // rodian male
    "male", // moncal male
    "male", // wookiee male
    "male", // sullustan male
    "male", // ithorian male
    "female", // human female
    "female", // trandoshan female
    "female", // twilek female
    "female", // bothan female
    "female", // zabrak female
    "female", // rodian female
    "female", // moncal female
    "female", // wookiee female
    "female", // sullustan female
    "female", // DA E7   -   ithorian female

    //-- Begin Bellum Gero bg_species1.tre custom species (raceid 20-66) --
    "male", "female", // aqualish
    "male", "female", // bith
    "male", "female", // chadra_fan
    "male", "female", // chiss
    "male", "female", // devaronian
    "male", "female", // ewok
    "male", "female", // hutt
    "male", "female", // mirialan
    "male", "female", // sanyassan
    "male", "female", // zeltron
    "male", // abyssin
    "male", // arcona
    "male", // cerean
    "male", // droid
    "male", // dug
    "male", // duros
    "male", // feeorin
    "male", // geonosian
    "male", // gotal
    "male", // gran
    "male", // gungan
    "male", // iktotchi
    "male", // ishi_tib
    "male", // jenet
    "male", // kel_dor
    "male", // kubaz
    "male", // nautolan
    "male", // nikto
    "male", // ortolan
    "male", // quarren
    "male", // talz
    "male", // togorian
    "male", // toydarian
    "male", // weequay
    "female", // nightsister
    "female", // togruta
    "female" // smc
    //-- End Bellum Gero bg_species1.tre custom species --
};

const static char* RaceStrs[] = {
    "object/creature/player/shared_human_male.iff", // human male
    "object/creature/player/shared_trandoshan_male.iff", // trandoshan male
    "object/creature/player/shared_twilek_male.iff", // twilek male
    "object/creature/player/shared_bothan_male.iff", // bothan male
    "object/creature/player/shared_zabrak_male.iff", // zabrak male
    "object/creature/player/shared_rodian_male.iff", // rodian male
    "object/creature/player/shared_moncal_male.iff", // moncal male
    "object/creature/player/shared_wookiee_male.iff", // wookiee male
    "object/creature/player/shared_sullustan_male.iff", // sullustan male
    "object/creature/player/shared_ithorian_male.iff", // ithorian male
    "object/creature/player/shared_human_female.iff", // human female
    "object/creature/player/shared_trandoshan_female.iff", // trandoshan female
    "object/creature/player/shared_twilek_female.iff", // twilek female
    "object/creature/player/shared_bothan_female.iff", // bothan female
    "object/creature/player/shared_zabrak_female.iff", // zabrak female
    "object/creature/player/shared_rodian_female.iff", // rodian female
    "object/creature/player/shared_moncal_female.iff", // moncal female
    "object/creature/player/shared_wookiee_female.iff", // wookiee female
    "object/creature/player/shared_sullustan_female.iff", // sullustan female
    "object/creature/player/shared_ithorian_female.iff", // DA E7   -   ithorian female

    //-- Begin Bellum Gero bg_species1.tre custom species (raceid 20-66) --
    "object/creature/player/shared_aqualish_male.iff",
    "object/creature/player/shared_aqualish_female.iff",
    "object/creature/player/shared_bith_male.iff",
    "object/creature/player/shared_bith_female.iff",
    "object/creature/player/shared_chadra_fan_male.iff",
    "object/creature/player/shared_chadra_fan_female.iff",
    "object/creature/player/shared_chiss_male.iff",
    "object/creature/player/shared_chiss_female.iff",
    "object/creature/player/shared_devaronian_male.iff",
    "object/creature/player/shared_devaronian_female.iff",
    "object/creature/player/shared_ewok_male.iff",
    "object/creature/player/shared_ewok_female.iff",
    "object/creature/player/shared_hutt_male.iff",
    "object/creature/player/shared_hutt_female.iff",
    "object/creature/player/shared_mirialan_male.iff",
    "object/creature/player/shared_mirialan_female.iff",
    "object/creature/player/shared_sanyassan_male.iff",
    "object/creature/player/shared_sanyassan_female.iff",
    "object/creature/player/shared_zeltron_male.iff",
    "object/creature/player/shared_zeltron_female.iff",
    "object/creature/player/shared_abyssin_male.iff",
    "object/creature/player/shared_arcona_male.iff",
    "object/creature/player/shared_cerean_male.iff",
    "object/creature/player/shared_droid_male.iff",
    "object/creature/player/shared_dug_male.iff",
    "object/creature/player/shared_duros_male.iff",
    "object/creature/player/shared_feeorin_male.iff",
    "object/creature/player/shared_geonosian_male.iff",
    "object/creature/player/shared_gotal_male.iff",
    "object/creature/player/shared_gran_male.iff",
    "object/creature/player/shared_gungan_male.iff",
    "object/creature/player/shared_iktotchi_male.iff",
    "object/creature/player/shared_ishi_tib_male.iff",
    "object/creature/player/shared_jenet_male.iff",
    "object/creature/player/shared_kel_dor_male.iff",
    "object/creature/player/shared_kubaz_male.iff",
    "object/creature/player/shared_nautolan_male.iff",
    "object/creature/player/shared_nikto_male.iff",
    "object/creature/player/shared_ortolan_male.iff",
    "object/creature/player/shared_quarren_male.iff",
    "object/creature/player/shared_talz_male.iff",
    "object/creature/player/shared_togorian_male.iff",
    "object/creature/player/shared_toydarian_male.iff",
    "object/creature/player/shared_weequay_male.iff",
    "object/creature/player/shared_nightsister_female.iff",
    "object/creature/player/shared_togruta_female.iff",
    "object/creature/player/shared_smc_female.iff"
    //-- End Bellum Gero bg_species1.tre custom species --
};

const static char* CCRaceStrs[] = {
    "object/creature/player/human_male.iff", // human male
    "object/creature/player/trandoshan_male.iff", // trandoshan male
    "object/creature/player/twilek_male.iff", // twilek male
    "object/creature/player/bothan_male.iff", // bothan male
    "object/creature/player/zabrak_male.iff", // zabrak male
    "object/creature/player/rodian_male.iff", // rodian male
    "object/creature/player/moncal_male.iff", // moncal male
    "object/creature/player/wookiee_male.iff", // wookiee male
    "object/creature/player/sullustan_male.iff", // sullustan male
    "object/creature/player/ithorian_male.iff", // ithorian male
    "object/creature/player/human_female.iff", // human female
    "object/creature/player/trandoshan_female.iff", // trandoshan female
    "object/creature/player/twilek_female.iff", // twilek female
    "object/creature/player/bothan_female.iff", // bothan female
    "object/creature/player/zabrak_female.iff", // zabrak female
    "object/creature/player/rodian_female.iff", // rodian female
    "object/creature/player/moncal_female.iff", // moncal female
    "object/creature/player/wookiee_female.iff", // wookiee female
    "object/creature/player/sullustan_female.iff", // sullustan female
    "object/creature/player/ithorian_female.iff", // DA E7   -   ithorian female

    //-- Begin Bellum Gero bg_species1.tre custom species (raceid 20-66) --
    "object/creature/player/aqualish_male.iff",
    "object/creature/player/aqualish_female.iff",
    "object/creature/player/bith_male.iff",
    "object/creature/player/bith_female.iff",
    "object/creature/player/chadra_fan_male.iff",
    "object/creature/player/chadra_fan_female.iff",
    "object/creature/player/chiss_male.iff",
    "object/creature/player/chiss_female.iff",
    "object/creature/player/devaronian_male.iff",
    "object/creature/player/devaronian_female.iff",
    "object/creature/player/ewok_male.iff",
    "object/creature/player/ewok_female.iff",
    "object/creature/player/hutt_male.iff",
    "object/creature/player/hutt_female.iff",
    "object/creature/player/mirialan_male.iff",
    "object/creature/player/mirialan_female.iff",
    "object/creature/player/sanyassan_male.iff",
    "object/creature/player/sanyassan_female.iff",
    "object/creature/player/zeltron_male.iff",
    "object/creature/player/zeltron_female.iff",
    "object/creature/player/abyssin_male.iff",
    "object/creature/player/arcona_male.iff",
    "object/creature/player/cerean_male.iff",
    "object/creature/player/droid_male.iff",
    "object/creature/player/dug_male.iff",
    "object/creature/player/duros_male.iff",
    "object/creature/player/feeorin_male.iff",
    "object/creature/player/geonosian_male.iff",
    "object/creature/player/gotal_male.iff",
    "object/creature/player/gran_male.iff",
    "object/creature/player/gungan_male.iff",
    "object/creature/player/iktotchi_male.iff",
    "object/creature/player/ishi_tib_male.iff",
    "object/creature/player/jenet_male.iff",
    "object/creature/player/kel_dor_male.iff",
    "object/creature/player/kubaz_male.iff",
    "object/creature/player/nautolan_male.iff",
    "object/creature/player/nikto_male.iff",
    "object/creature/player/ortolan_male.iff",
    "object/creature/player/quarren_male.iff",
    "object/creature/player/talz_male.iff",
    "object/creature/player/togorian_male.iff",
    "object/creature/player/toydarian_male.iff",
    "object/creature/player/weequay_male.iff",
    "object/creature/player/nightsister_female.iff",
    "object/creature/player/togruta_female.iff",
    "object/creature/player/smc_female.iff"
    //-- End Bellum Gero bg_species1.tre custom species --
};

static uint32 SharedRace[] = {
    0xAF1DC1A1,
    0x50C45B8F,
    0xF280E27B,
    0x5BF77F33,
    0xE204A556,
    0x0BF9CD9C,
    0xB9C855A8,
    0x0564791D,
    0x0B9399A4,
    0x38BAC7C4,
    0xFFFFBBE9,
    0x183C24C6,
    0x849752DC,
    0x1D52730E,
    0xA9E35FFD,
    0xC264245B,
    0x982FBFDE,
    0x0DAB65E2,
    0x1573341A,
    0xB3E08013,

    //-- Begin Bellum Gero bg_species1.tre custom species (raceid 20-66) --
    //-- These are the TreeFileRecord "checksum" values read directly out of bg_species1.tre for each
    //-- shared_<name>_<gender>.iff (verified to be the same CRC convention as clientObjectCRC above,
    //-- e.g. human male's 0xAF1DC1A1 matches exactly).
    0xCEF4B4A1, // aqualish male
    0xDE63F629, // aqualish female
    0x73C992FF, // bith male
    0xB2C9CBE0, // bith female
    0xF9504963, // chadra_fan male
    0xC6B705B4, // chadra_fan female
    0x02F60EAC, // chiss male
    0x614A1B68, // chiss female
    0x68731058, // devaronian male
    0x4A2817DA, // devaronian female
    0x4B39AD7D, // ewok male
    0xBE49D88E, // ewok female
    0x916443F9, // hutt male
    0xE0B607C0, // hutt female
    0xD7349684, // mirialan male
    0xE9CC7F2D, // mirialan female
    0x57A4EC3E, // sanyassan male
    0x34E79C2B, // sanyassan female
    0xE8975526, // zeltron male
    0x5B779FE7, // zeltron female
    0xB0960636, // abyssin male
    0xA2A87F6E, // arcona male
    0x62EAF6FB, // cerean male
    0xDE6FB2E5, // droid male
    0x696718D6, // dug male
    0xA9BFEBF0, // duros male
    0x60EDEA05, // feeorin male
    0x0D506AEA, // geonosian male
    0x30CFFED2, // gotal male
    0xC2872D34, // gran male
    0x3A7F5790, // gungan male
    0xF9B11C30, // iktotchi male
    0x809EF398, // ishi_tib male
    0x48B04347, // jenet male
    0x66DCE6EE, // kel_dor male
    0x6BB072FA, // kubaz male
    0xAB03ACB1, // nautolan male
    0x59ECB38B, // nikto male
    0x65FBE4A7, // ortolan male
    0x3435F686, // quarren male
    0xDBA89F7C, // talz male
    0xA4478797, // togorian male
    0x3E751C09, // toydarian male
    0x4F0718B5, // weequay male
    0xC56D9790, // nightsister female
    0x3D953B50, // togruta female
    0x82A138F9 // smc female
    //-- End Bellum Gero bg_species1.tre custom species --
};

const static int TotalRaces = 67; // 20 original (10 species x 2 genders) + 47 Bellum Gero bg_species1.tre custom player templates

static unsigned int attributeLimits[10][19] = {
		{400, 1100,	400, 1100,  400, 1100, 400, 1100, 400, 1100, 400, 1100,	400, 1100, 400,	1100, 400, 1100, 5400},
		{550, 1250,	600,  800,	700,  800, 300,	1000, 300,  450, 300,  400,	300, 1000, 300,	 500, 300,	600, 5550},
		{300, 1000,	300,  500,	550,  650, 550,	1250, 600,	750, 300,  400,	400, 1100, 300,	 500, 300,	500, 5400},
		{300, 1000,	300,  500,	300,  400, 600,	1300, 600,	750, 400,  500,	400, 1100, 400,	 600, 300,	500, 5400},
		{500, 1200,	300,  500,	300,  400, 600,	1300, 300,	450, 300,  400,	300, 1000, 300,	 500, 700,	900, 5400},
		{300, 1000,	300,  500,	300,  400, 300,	1200, 300,	650, 450,  850,	300, 1000, 300,	 500, 350,	550, 5400},
		{300, 1000,	300,  500,	300,  400, 300,	1000, 300,	450, 450,  550,	600, 1300, 600,	 800, 450,	650, 5400},
		{650, 1350,	650,  850,	450,  550, 500,	1200, 400,	550, 400,  500,	400, 1100, 450,	 650, 400,	600, 6100},
		{300, 1200,	300,  500,	300,  400, 600,	1400, 300,	750, 300,  500,	400, 1200, 400,	 600, 300,	600, 5400},
		{300, 1400,	300,  600,	300,  500, 600,	1100, 300,	750, 300,  500,	400, 1300, 400,	 600, 300,	500, 5400}
};

class Races {
public:
	inline const static char* getRace(int raceid) {
		if (raceid < 0 || raceid >= TotalRaces)
			return "";

		return RaceStrs[raceid];
	}

	// BG: complete/CC (non-shared) template path for raceid, e.g. "object/creature/player/human_male.iff".
	// Mirrors getRace() (which returns the shared/client path) but for CCRaceStrs.
	inline const static char* getCCRace(int raceid) {
		if (raceid < 0 || raceid >= TotalRaces)
			return "";

		return CCRaceStrs[raceid];
	}

	inline static int getSpeciesID(int raceid) {
		if (raceid < 0 || raceid >= TotalRaces)
			return 0;

		return TemplateSpecies[raceid];
	}

	inline const static char* getSpecies(int raceid) {
		if (raceid < 0 || raceid >= TotalRaces)
			return "";

		return Species[raceid];
	}

	inline const static char* getGender(int raceid) {
		if (raceid < 0 || raceid >= TotalRaces)
			return "";

		return Gender[raceid];
	}

	inline static uint32 getRaceCRC(int raceid) {
		if (raceid < 0 || raceid >= TotalRaces)
			return 0;

		return SharedRace[raceid];
	}

	inline static const char* getCompleteRace(uint32 sharedRaceCRC) {
		int race = -1;
		for (int i = 0; i < TotalRaces; ++i) {
			if (SharedRace[i] == sharedRaceCRC) {
				race = i;
				break;
			}
		}

		if (race == -1)
			return "";
		else
			return CCRaceStrs[race];
	}

	inline static int getRaceID(const String& name) {
    	for (int i = 0; i < TotalRaces; i++) {
        	if (strcmp(name.toCharArray(), CCRaceStrs[i]) == 0)
            	return i;
    	}

    	return 0;
	}

	// BG: Species Change Token support -- given a species name (a Species[] value, e.g. "chiss") and
	// a desired gender ("male"/"female"), returns the matching raceid, or -1 if that species has no
	// template for that gender. Do not assume every species has both genders: most bg_species1.tre
	// custom species are male-only, and Nightsister/Togruta/SMC are female-only. See
	// docs/bellum_species1_mapping.md for the full list. Unlike getRaceID() above, this returns -1
	// (not 0/human) on no match, since a caller here needs to distinguish "no such species/gender
	// combination" from "human male".
	inline static int getRaceIDForSpeciesGender(const String& speciesName, const String& gender) {
		for (int i = 0; i < TotalRaces; ++i) {
			if (speciesName == Species[i] && gender == Gender[i])
				return i;
		}

		return -1;
	}

	//-- attributeLimits[10][19] only ever held data for the original 10 species; raceid % 10 was already a
	//-- deliberate male/female-mirroring hack for that fixed 20-entry layout. It is unused anywhere in the
	//-- codebase (real per-species attribute caps are loaded at runtime from datatables/creation/attribute_limits.iff
	//-- via PlayerCreationManager, keyed by template name string, not through this array/raceid). Left unmodified
	//-- for raceid 0-19; for raceid >= 20 (Bellum Gero custom species) this still safely returns one of the
	//-- original 10 rows via modulo rather than crashing, but it is NOT meaningful data for those species -- do
	//-- not use this method for the new species without extending attributeLimits[][] with real data first.
	inline static unsigned int * getAttribLimits(int raceid) {
		return attributeLimits[raceid % 10];
	}

};

#endif /*RACES_H_*/
