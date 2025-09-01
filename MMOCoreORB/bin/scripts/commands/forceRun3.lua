-- forceRun3.lua

ForceRun3Command = {
    name = "forcerun3",
    forceCost = 600,
    duration = 10000000000000,  -- until toggled off
    clientEffect = "clienteffect/pl_force_run_self.cef",
    toggle = true,
    speedMod = 3.5,

    drPercent = 90,  -- 0..90
}

local function disableBasicAttack(creature)
    if not creature or not creature:isPlayerCreature() then return end
    local ghost = creature:getPlayerObject()
    if not ghost then return end

    -- Remove basic attack; server will reject attempts to use it
    if ghost.removeAbility then
        ghost:removeAbility("attack")
    end

    -- (Optional) tell the player why
    if creature.sendSystemMessage then
        creature:sendSystemMessage("@jedi_spam:force_run_cannot_attack")
        -- fallback if you don't have that string:
        -- creature:sendSystemMessage("You cannot attack while Force Run is active.")
    end
end

local function enableBasicAttack(creature)
    if not creature or not creature:isPlayerCreature() then return end
    local ghost = creature:getPlayerObject()
    if not ghost then return end

    -- Re-grant basic attack on toggle off
    if ghost.addAbility then
        ghost:addAbility("attack")
    end
end

function ForceRun3Command:onStart(creature, target, args)
    local dr = self.drPercent or 30
    if dr > 90 then dr = 90 end

    -- Defensive only (incoming DR)
    creature:addSkillMod("force_armor", dr)   -- non-Force damage
    creature:addSkillMod("force_shield", dr)  -- Force damage

    -- Block basic attack while FR3 is active
    disableBasicAttack(creature)
end

function ForceRun3Command:onStop(creature)
    local dr = self.drPercent or 30
    if dr > 90 then dr = 90 end

    creature:removeSkillMod("force_armor", dr)
    creature:removeSkillMod("force_shield", dr)

    -- Restore basic attack when FR3 ends
    enableBasicAttack(creature)
end

AddCommand(ForceRun3Command)
