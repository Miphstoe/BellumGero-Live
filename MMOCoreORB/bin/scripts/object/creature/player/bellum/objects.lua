--Copyright (C) 2010 <SWGEmu>


--This File is part of Core3.

--This program is free software; you can redistribute
--it and/or modify it under the terms of the GNU Lesser
--General Public License as published by the Free Software
--Foundation; either version 2 of the License,
--or (at your option) any later version.

--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--See the GNU Lesser General Public License for
--more details.

--You should have received a copy of the GNU Lesser General
--Public License along with this program; if not, write to
--the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--Linking Engine3 statically or dynamically with other modules
--is making a combined work based on Engine3.
--Thus, the terms and conditions of the GNU Lesser General Public License
--cover the whole combination.

--In addition, as a special exception, the copyright holders of Engine3
--give you permission to combine Engine3 program with free software
--programs or libraries that are released under the GNU LGPL and with
--code included in the standard release of Core3 under the GNU LGPL
--license (or modified versions of such code, with unchanged license).
--You may copy and distribute such a system following the terms of the
--GNU LGPL for Engine3 and the licenses of the other code concerned,
--provided that you include the source code of that other code when
--and as the GNU LGPL requires distribution of source code.

--Note that people who make modified versions of Engine3 are not obligated
--to grant this special exception for their modified versions;
--it is their choice whether to do so. The GNU Lesser General Public License
--gives permission to release a modified version without this exception;
--this exception also makes it possible to release a modified version

--Bellum Gero: bg_species1.tre custom playable species support.
--baseHAM sourced from datatables/creation/racial_mods.iff in bg_species1.tre where a row
--exists for the species; species with no curated row in that table fall back to the flat
--{100,100,100,100,100,100,100,100,100} baseline (matching the TRE's own convention for
--other undifferentiated custom species, and PlayerCreationManager's own human_male fallback).


object_creature_player_shared_aqualish_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_aqualish_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_aqualish_male, "object/creature/player/shared_aqualish_male.iff")

object_creature_player_shared_aqualish_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_aqualish_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_aqualish_female, "object/creature/player/shared_aqualish_female.iff")

object_creature_player_shared_bith_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_bith_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_bith_male, "object/creature/player/shared_bith_male.iff")

object_creature_player_shared_bith_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_bith_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_bith_female, "object/creature/player/shared_bith_female.iff")

object_creature_player_shared_chadra_fan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_chadra_fan_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_chadra_fan_male, "object/creature/player/shared_chadra_fan_male.iff")

object_creature_player_shared_chadra_fan_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_chadra_fan_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_chadra_fan_female, "object/creature/player/shared_chadra_fan_female.iff")

object_creature_player_shared_chiss_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_chiss_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_chiss_male, "object/creature/player/shared_chiss_male.iff")

object_creature_player_shared_chiss_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_chiss_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_chiss_female, "object/creature/player/shared_chiss_female.iff")

object_creature_player_shared_devaronian_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_devaronian_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_devaronian_male, "object/creature/player/shared_devaronian_male.iff")

object_creature_player_shared_devaronian_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_devaronian_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_devaronian_female, "object/creature/player/shared_devaronian_female.iff")

object_creature_player_shared_ewok_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_ewok_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_ewok_male, "object/creature/player/shared_ewok_male.iff")

object_creature_player_shared_ewok_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_ewok_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_ewok_female, "object/creature/player/shared_ewok_female.iff")

object_creature_player_shared_hutt_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_hutt_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_hutt_male, "object/creature/player/shared_hutt_male.iff")

object_creature_player_shared_hutt_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_hutt_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_hutt_female, "object/creature/player/shared_hutt_female.iff")

object_creature_player_shared_mirialan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_mirialan_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_mirialan_male, "object/creature/player/shared_mirialan_male.iff")

object_creature_player_shared_mirialan_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_mirialan_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_mirialan_female, "object/creature/player/shared_mirialan_female.iff")

object_creature_player_shared_sanyassan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_sanyassan_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_sanyassan_male, "object/creature/player/shared_sanyassan_male.iff")

object_creature_player_shared_sanyassan_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_sanyassan_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_sanyassan_female, "object/creature/player/shared_sanyassan_female.iff")

object_creature_player_shared_zeltron_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_zeltron_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_zeltron_male, "object/creature/player/shared_zeltron_male.iff")

object_creature_player_shared_zeltron_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_zeltron_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_zeltron_female, "object/creature/player/shared_zeltron_female.iff")

object_creature_player_shared_abyssin_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_abyssin_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_abyssin_male, "object/creature/player/shared_abyssin_male.iff")

object_creature_player_shared_arcona_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_arcona_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_arcona_male, "object/creature/player/shared_arcona_male.iff")

object_creature_player_shared_cerean_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_cerean_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_cerean_male, "object/creature/player/shared_cerean_male.iff")

object_creature_player_shared_droid_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_droid_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_droid_male, "object/creature/player/shared_droid_male.iff")

object_creature_player_shared_dug_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_dug_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_dug_male, "object/creature/player/shared_dug_male.iff")

object_creature_player_shared_duros_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_duros_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_duros_male, "object/creature/player/shared_duros_male.iff")

object_creature_player_shared_feeorin_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_feeorin_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_feeorin_male, "object/creature/player/shared_feeorin_male.iff")

object_creature_player_shared_geonosian_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_geonosian_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_geonosian_male, "object/creature/player/shared_geonosian_male.iff")

object_creature_player_shared_gotal_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_gotal_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_gotal_male, "object/creature/player/shared_gotal_male.iff")

object_creature_player_shared_gran_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_gran_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_gran_male, "object/creature/player/shared_gran_male.iff")

object_creature_player_shared_gungan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_gungan_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_gungan_male, "object/creature/player/shared_gungan_male.iff")

object_creature_player_shared_iktotchi_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_iktotchi_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_iktotchi_male, "object/creature/player/shared_iktotchi_male.iff")

object_creature_player_shared_ishi_tib_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_ishi_tib_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_ishi_tib_male, "object/creature/player/shared_ishi_tib_male.iff")

object_creature_player_shared_jenet_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_jenet_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_jenet_male, "object/creature/player/shared_jenet_male.iff")

object_creature_player_shared_kel_dor_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_kel_dor_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_kel_dor_male, "object/creature/player/shared_kel_dor_male.iff")

object_creature_player_shared_kubaz_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_kubaz_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_kubaz_male, "object/creature/player/shared_kubaz_male.iff")

object_creature_player_shared_nautolan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_nautolan_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_nautolan_male, "object/creature/player/shared_nautolan_male.iff")

object_creature_player_shared_nikto_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_nikto_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_nikto_male, "object/creature/player/shared_nikto_male.iff")

object_creature_player_shared_ortolan_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_ortolan_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_ortolan_male, "object/creature/player/shared_ortolan_male.iff")

object_creature_player_shared_quarren_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_quarren_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_quarren_male, "object/creature/player/shared_quarren_male.iff")

object_creature_player_shared_talz_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_talz_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_talz_male, "object/creature/player/shared_talz_male.iff")

object_creature_player_shared_togorian_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_togorian_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_togorian_male, "object/creature/player/shared_togorian_male.iff")

object_creature_player_shared_toydarian_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_toydarian_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_toydarian_male, "object/creature/player/shared_toydarian_male.iff")

object_creature_player_shared_weequay_male = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_weequay_male.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_weequay_male, "object/creature/player/shared_weequay_male.iff")

object_creature_player_shared_nightsister_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_nightsister_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_nightsister_female, "object/creature/player/shared_nightsister_female.iff")

object_creature_player_shared_togruta_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_togruta_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_togruta_female, "object/creature/player/shared_togruta_female.iff")

object_creature_player_shared_smc_female = SharedCreatureObjectTemplate:new {
	clientTemplateFileName = "object/creature/player/shared_smc_female.iff"
}

ObjectTemplates:addClientTemplate(object_creature_player_shared_smc_female, "object/creature/player/shared_smc_female.iff")
