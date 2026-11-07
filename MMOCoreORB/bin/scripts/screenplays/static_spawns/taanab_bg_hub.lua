-- BG Hub vendor (myswg_vendor) at Pandath, beside the mission and bounty terminals by the starport. Same NPC, bark
-- loop and pet enhancement menu as the other planets (screenplays/tasks/naboo/myswg_vendor.lua), spawned from here
-- like hoth_bg_hub.lua. Each spot is clear of snapshot objects and TaanabStaticSpawnsScreenPlay and faces the town's
-- mission terminal (Pandath 2100.3, 5362.8; Starhunter 3598.4, -5401.6). Height comes from getWorldFloor.
TaanabBgHub = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "TaanabBgHub",

	planet = "taanab",
	npcs = {
		{x = 2105.1, z = 45.0, y = 5355.9, heading = -35},   -- Pandath, by the mission terminals
		{x = 3601.5, z = 31.7, y = -5398.5, heading = -132},  -- Starhunter Station, by the mission terminal
	},
}

registerScreenPlay("TaanabBgHub", true)

function TaanabBgHub:start()
	if (isZoneEnabled(self.planet)) then
		local spawned = 0
		for _, n in ipairs(self.npcs) do
			local z = n.z
			pcall(function() z = getWorldFloor(n.x, n.y, self.planet) or z end)
			local pNpc = spawnMobile(self.planet, "myswg_vendor", 1, n.x, z, n.y, n.heading, 0)
			if (pNpc ~= nil) then
				spawned = spawned + 1
				local randomDelay = math.random(0, 30) * 1000
				createEvent(randomDelay, "myswg_vendor", "performBark", pNpc, "")
			end
		end
		print(string.format("[TAANAB-BGHUB] spawned %d of %d BG Hub NPCs", spawned, #self.npcs))
	end
end
