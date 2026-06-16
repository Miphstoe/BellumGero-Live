--Copyright (C) 2007 <SWGEmu>
 
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
--which carries forward this exception.



--------------------------
-- Skill Mod Manager
--------------------------
-- These mods match values with the constant in SkillModManager.h

skillModLimits = {

	-- Permanent Mods - No limits, so no entries
	--{257, x, x}, --TEMPLATE - All mods from LUA skillMods
	--{258, x, x}, -- SKILLBOX

	-- Bonus Mods Wearables / Structure
	{4097, -25, 25},  --WEARABLE
	{4098, -125, 125}, -- STRUCTUREMOD

	-- Temp mods, not displayed (on timers or ability bonus)
	{2711, -125, 125}, -- BUFFMOD
	{2712, -125, 125}, -- ABILITYBONUSMOD
}

-- Per-mod-name overrides: checked before skillModLimits type caps.
-- Format: { "modName", modType, minValue, maxValue }
--
-- jedi_force_power_regen SEA cap:
--   WEARABLE (4097) sources — clothing attachments and SEAs — are capped at ±25 total.
--   Multiple clothing pieces with Force Power Regen SEAs cannot stack beyond +25 combined.
--   Robe template mods use TEMPLATE type (0x101 = 257), which has no cap entry here and
--   is therefore uncapped; robe innate Force Power Regen adds on top of the +25 SEA cap.
--   Example: two +25 SEAs = +25; one +25 SEA + robe +10 = +35; two +25 SEAs + robe +10 = +35.
skillModNameLimits = {
	{"jedi_force_power_regen", 4097, -25, 25},
}

disabledWearableSkillMods = {
	"combat_healing_ability",
	"healing_ability",
	"keep_creature",
	"stored_pets",
	"combat_medic_effectiveness",
}
