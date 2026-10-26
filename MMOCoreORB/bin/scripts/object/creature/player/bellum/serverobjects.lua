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

includeFile("creature/player/bellum/aqualish_male.lua")
includeFile("creature/player/bellum/aqualish_female.lua")
includeFile("creature/player/bellum/bith_male.lua")
includeFile("creature/player/bellum/bith_female.lua")
includeFile("creature/player/bellum/chadra_fan_male.lua")
includeFile("creature/player/bellum/chadra_fan_female.lua")
includeFile("creature/player/bellum/chiss_male.lua")
includeFile("creature/player/bellum/chiss_female.lua")
includeFile("creature/player/bellum/devaronian_male.lua")
includeFile("creature/player/bellum/devaronian_female.lua")
includeFile("creature/player/bellum/ewok_male.lua")
includeFile("creature/player/bellum/ewok_female.lua")
includeFile("creature/player/bellum/hutt_male.lua")
includeFile("creature/player/bellum/hutt_female.lua")
includeFile("creature/player/bellum/mirialan_male.lua")
includeFile("creature/player/bellum/mirialan_female.lua")
includeFile("creature/player/bellum/sanyassan_male.lua")
includeFile("creature/player/bellum/sanyassan_female.lua")
includeFile("creature/player/bellum/zeltron_male.lua")
includeFile("creature/player/bellum/zeltron_female.lua")
includeFile("creature/player/bellum/abyssin_male.lua")
includeFile("creature/player/bellum/arcona_male.lua")
includeFile("creature/player/bellum/cerean_male.lua")
includeFile("creature/player/bellum/droid_male.lua")
includeFile("creature/player/bellum/dug_male.lua")
includeFile("creature/player/bellum/duros_male.lua")
includeFile("creature/player/bellum/feeorin_male.lua")
includeFile("creature/player/bellum/geonosian_male.lua")
includeFile("creature/player/bellum/gotal_male.lua")
includeFile("creature/player/bellum/gran_male.lua")
includeFile("creature/player/bellum/gungan_male.lua")
includeFile("creature/player/bellum/iktotchi_male.lua")
includeFile("creature/player/bellum/ishi_tib_male.lua")
includeFile("creature/player/bellum/jenet_male.lua")
includeFile("creature/player/bellum/kel_dor_male.lua")
includeFile("creature/player/bellum/kubaz_male.lua")
includeFile("creature/player/bellum/nautolan_male.lua")
includeFile("creature/player/bellum/nikto_male.lua")
includeFile("creature/player/bellum/ortolan_male.lua")
includeFile("creature/player/bellum/quarren_male.lua")
includeFile("creature/player/bellum/talz_male.lua")
includeFile("creature/player/bellum/togorian_male.lua")
includeFile("creature/player/bellum/toydarian_male.lua")
includeFile("creature/player/bellum/weequay_male.lua")
includeFile("creature/player/bellum/nightsister_female.lua")
includeFile("creature/player/bellum/togruta_female.lua")
includeFile("creature/player/bellum/smc_female.lua")
