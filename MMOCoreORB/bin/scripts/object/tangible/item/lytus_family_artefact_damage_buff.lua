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


-- Lytus Family Artifact: consumable trinket granting a temporary +10%
-- outgoing damage buff to non-Jedi players. Uses the same shared client
-- appearance as the existing quest reward item (shared_lytus_family_artefact.iff)
-- but is registered under its own template path since it is a distinct,
-- independently-usable object with its own radial "use" behavior.
--
-- Jedi gating: LytusFamilyArtefactMenuComponent.cpp (C++)
-- 10% multiplier + lightsaber exclusion: CombatManager::applyDamageModifiers (C++)
object_tangible_item_lytus_family_artefact_damage_buff = object_tangible_item_shared_lytus_family_artefact:new {
	templateType = SKILLBUFF,
	objectMenuComponent = "LytusFamilyArtefactMenuComponent",
	attributeListComponent = "SkillBuffObjectAttributeListComponent",

	-- Buff duration in seconds -- single source of truth for how long the
	-- +10% damage buff lasts. 900 = 15 minutes.
	duration = 900,
	useCount = 1,
	modifiers = { "private_damage_percent_bonus", 10 },
	buffName = "lytus_family_artefact_damage_buff",
	-- buffCRC is unused here -- LytusFamilyArtefactMenuComponent.cpp computes
	-- it at runtime as hashCode(buffName) instead. This is intentional: every
	-- client-visible buff icon comes from a small, closed, fixed table of
	-- pre-existing base-game buffs keyed by buffCRC (BuffCRC.h). Reusing one
	-- of those CRCs (tried during development, e.g. the melee_accuracy
	-- skill_buff trinket) gets a working icon, but ALSO borrows that buff's
	-- displayed name/tooltip -- none of which say anything like "damage
	-- increase", since the whole reusable set is accuracy/speed/defense/food
	-- named. Decision: no icon at all is less misleading than a wrong one.
	-- A truly correct icon+label needs a new client-side asset, outside the
	-- scope of this server-only change.
	buffCRC = 0
}

ObjectTemplates:addTemplate(object_tangible_item_lytus_family_artefact_damage_buff, "object/tangible/item/lytus_family_artefact_damage_buff.iff")
