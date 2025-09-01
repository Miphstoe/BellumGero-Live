ForceRun3Command = {
    name = "forcerun3",
    forceCost = 600,
    duration = 10000000000000,  -- until toggled off
    clientEffect = "clienteffect/pl_force_run_self.cef",
    toggle = true,
    speedMod = 3.5,

    drPercent = 90,  -- tune: 0..90
}

function ForceRun3Command:onStart(creature, target, args)
    local dr = self.drPercent or 30
    if dr > 90 then dr = 90 end
    -- Defensive only:
    creature:addSkillMod("force_armor", dr)   -- reduces non-Force damage
    creature:addSkillMod("force_shield", dr)  -- reduces Force damage
end

function ForceRun3Command:onStop(creature)
    local dr = self.drPercent or 30
    if dr > 90 then dr = 90 end
    creature:removeSkillMod("force_armor", dr)
    creature:removeSkillMod("force_shield", dr)
end

AddCommand(ForceRun3Command)
