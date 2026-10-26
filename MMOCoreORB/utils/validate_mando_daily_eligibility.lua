-- Run from the repository root: lua MMOCoreORB/utils/validate_mando_daily_eligibility.lua
-- Engine boundaries are mocked; the production screenplay and menu are loaded intact.
ScreenPlay = { new = function(_, value) return value end }
registerScreenPlay = function() end
printf = function() end
logLua = function() end
local data = {}
readData = function(key) return data[key] or 0 end
writeData = function(key, value) data[key] = value end
deleteData = function(key) data[key] = nil end
SceneObject = function(object) return object end
CreatureObject = SceneObject
LuaObjectMenuResponse = SceneObject
local base = "MMOCoreORB/bin/scripts/screenplays/bellum/"
dofile(base .. "mando_way_of_life.lua")
dofile(base .. "mando_daily_bounty_fob_menu.lua")
package.preload["utils.spawn_mobiles"] = function() return {} end
local camp = dofile(base .. "bounty_camp_theater_helpers.lua")
local way = MandoWayOfLife
way.readInt = function(_, player, key) return player[key] or 0 end
way.isAccountMandoWayComplete = function() return true end
way.logDiagPlayer = function() end
local helmet = { getTemplateObjectPath = function() return "object/tangible/wearables/armor/mandalorian/custom/tribesman_helmet.iff" end }
local player = {
    chapter5Complete = 1, bh = true, helmet = helmet,
    getObjectID = function() return 1 end,
    hasSkill = function(self, skill) assert(skill == "combat_bountyhunter_novice"); return self.bh end,
    getSlottedObject = function(self, slot) if slot == "hat" then return self.helmet end end,
    getPlayerObject = function(self) return self end,
    isPlayerCreature = function() return true end,
    sendSystemMessage = function(self, message) self.message = message end,
    addCashCredits = function() error("Ineligible camp paid credits") end,
}
local menu = { count = 0, addRadialMenuItem = function(self) self.count = self.count + 1 end }
local function reset()
    data = {}
    player.chapter5Complete, player.bh, player.helmet = 1, true, helmet
    menu.count = 0
end
-- Every missing requirement denies even with account-wide completion.
for completed = 0, 1 do
    for _, bh in ipairs({false, true}) do
        for _, equipped in ipairs({false, true}) do
            reset()
            player.chapter5Complete, player.bh = completed, bh
            player.helmet = equipped and helmet or nil
            local expected = completed == 1 and bh and equipped
            assert(way:checkDailyBountyEligibility(player) == expected)
            MandoDailyBountyFobMenuComponent:fillObjectMenuResponse({}, menu, player)
            assert((menu.count > 0) == expected)
            if not expected then
                for _, source in ipairs({"fob", "holo", "auto"}) do
                    assert(not way:tryAcceptDailyBountyMission(player, source))
                end
                assert(not way:resyncDailyBountyWaypoint(player))
                assert(not way:tryGrantDailyBountyFob(player))
                assert(way:getDailyBountyCount(player) == 0)
                for id = 120, 123 do
                    player.message = nil
                    MandoDailyBountyFobMenuComponent:handleObjectMenuSelect({}, player, id)
                    assert(player.message ~= nil)
                end
            end
        end
    end
end
assert(not way:checkDailyBountyEligibility(nil))
-- Inventory-only and unrelated helmets do not count; quest helmet tiers do.
reset()
player.helmet = { getTemplateObjectPath = function() return "object/tangible/wearables/armor/mandalorian/armor_mandalorian_helmet.iff" end }
assert(not way:checkDailyBountyEligibility(player))
for _, tier in ipairs({"foundling", "initiate", "hunter", "verdika", "clanbound", "tribesman"}) do
    player.helmet = { getTemplateObjectPath = function() return "object/tangible/wearables/armor/mandalorian/custom/" .. tier .. "_helmet.iff" end }
    assert(way:checkDailyBountyEligibility(player))
end
-- Eligible first mission and auto continuation start theaters and consume one count each.
reset()
local starts = 0
for tier = 1, 5 do
    _G["BellumBountyDailyTier" .. tier .. "Theater"] = {start = function() starts = starts + 1; return true end}
end
assert(way:tryAcceptDailyBountyMission(player, "fob"))
assert(starts == 1 and way:getDailyBountyCount(player) == 1)
assert(way:markDailyBountyTierComplete(player, 1))
player.helmet = nil
assert(not way:tryAcceptDailyBountyMission(player, "auto"))
assert(starts == 1 and way:getDailyBountyReadyTier(player) == 1)
player.helmet = helmet
assert(way:tryAcceptDailyBountyMission(player, "auto"))
assert(starts == 2 and way:getDailyBountyCount(player) == 2)
-- A stale FOB menu is revalidated at selection time.
reset()
MandoDailyBountyFobMenuComponent:fillObjectMenuResponse({}, menu, player)
assert(menu.count > 0)
player.bh = false
MandoDailyBountyFobMenuComponent:handleObjectMenuSelect({}, player, 121)
assert(starts == 2 and way:getDailyBountyCount(player) == 0)
-- Losing any requirement at a camp kill cancels before credits, loot, or completion.
getSceneObject = function(id) if id == 1 then return player end end
local victim = { getObjectID = function() return 2 end }
createLoot = function() error("Ineligible camp awarded loot") end
local cleaned, removed = 0, 0
way.cleanupDailyBountyTheater = function() cleaned = cleaned + 1 end
for tier = 1, 5 do
    for _, missing in ipairs({"chapter5Complete", "bh", "helmet"}) do
        reset()
        player[missing] = ({chapter5Complete = 0, bh = false})[missing]
        local task = "BellumBountyDailyTier" .. tier .. "Theater"
        local theater = {
            taskName = task, dailyBountyTier = tier,
            removeTheaterWaypoint = function() removed = removed + 1 end,
            onSpynetMarkDown = function() error("Ineligible camp advanced") end,
        }
        data["2" .. task .. ":bountyOwner"] = 1
        data["2" .. task .. ":isMark"] = 1
        assert(camp.notifyBountyMobileKilled(theater, victim, player) == 1)
        assert(way:getDailyBountyReadyTier(player) == 0)
    end
end
assert(cleaned == 15 and removed == 15)
print("PASS: daily eligibility combinations, FOB selection, acceptance, auto advancement, recovery/grant denial, and five-tier combat gates")
