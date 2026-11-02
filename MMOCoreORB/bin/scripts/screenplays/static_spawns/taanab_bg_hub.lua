-- BG Hub vendor (myswg_vendor) at Pandath, beside the mission and bounty terminals by the starport. Same NPC, bark
-- loop and pet enhancement menu as the other planets (screenplays/tasks/naboo/myswg_vendor.lua), spawned from here
-- like hoth_bg_hub.lua. The spot is clear of snapshot objects and TaanabStaticSpawnsScreenPlay; heading faces the
-- mission terminal at (2100.3, 5362.8).
TaanabBgHub = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "TaanabBgHub",

	planet = "taanab",
	npcs = {
		{x = 2105.1, z = 45.0, y = 5355.9, heading = -35},   -- Pandath, by the mission terminals
	},
}

registerScreenPlay("TaanabBgHub", true)

function TaanabBgHub:start()
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
