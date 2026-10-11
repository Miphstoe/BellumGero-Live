-- BG Hub vendor (myswg_vendor) at the three Hoth outposts, next to each terminal row. Same NPC, bark loop and pet
-- enhancement menu as the other planets (screenplays/tasks/naboo/myswg_vendor.lua); spawned from here so that file
-- stays untouched. Heading: Scavenger and Imperial rows are unrotated (0); the Rebel row faces the starport (315).
HothBgHub = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "HothBgHub",

	planet = "hoth",
	npcs = {
		{x = -4034.0, z = 23.3, y = -2094.0, heading = 0},   -- Scavenger Outpost, east end of the terminal row
		{x = 3813.0, z = 29.0, y = -3094.0, heading = 0},    -- Imperial Forward Base, east end of the terminal row
		{x = -399.7, z = 27.8, y = 592.3, heading = 315},    -- Rebel Forward Base, end of the terminal row
	},
}

registerScreenPlay("HothBgHub", true)

function HothBgHub:start()
	if (isZoneEnabled(self.planet)) then
		for _, n in ipairs(self.npcs) do
			local pNpc = spawnMobile(self.planet, "myswg_vendor", 1, n.x, n.z, n.y, n.heading, 0)
			if (pNpc ~= nil) then
				local randomDelay = math.random(0, 30) * 1000
				createEvent(randomDelay, "myswg_vendor", "performBark", pNpc, "")
			end
		end
	end
end
