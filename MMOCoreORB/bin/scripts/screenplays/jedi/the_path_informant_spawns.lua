ThePathInformantSpawns = ScreenPlay:new {
	numberOfActs = 1
}

registerScreenPlay("ThePathInformantSpawns", true)

function ThePathInformantSpawns:start()
	-- NOTE:
	-- Planet name stays the same even for interiors (e.g. "tatooine").
	-- To spawn inside a cantina, pass the *cell object id* as the last argument (cellId).
	-- If cellId is omitted or 0, it spawns outside in the world.

	-- Example OUTSIDE spawns (your original ones)
	if isZoneEnabled("lok") then
		self:spawnOne("lok", -23.7, -0.9, 0.5, 90, 8145386) 
	end

	-- Example INSIDE cantina spawns (replace cellId + coords with your cantina interior values)
	-- You can get cellId from existing city screenplay spawns (last numeric arg), or by using /loc and matching.
	-- Example pattern:
	-- self:spawnOne("tatooine", 10.65, -0.89, 1.91, 330, 1082877)

	if isZoneEnabled("tatooine") then
		-- Mos Eisley Cantina example (cellId is placeholder; replace with the real one)
		 self:spawnOne("tatooine", -23.4, -0.9, 0.5, 90, 1082885)
	end

	if isZoneEnabled("naboo") then
		-- Theed Cantina example (cellId is placeholder; replace with the real one)
		-- self:spawnOne("naboo", 5.0, -0.9, -3.0, 180, 1234567)
	end

	return true
end

-- cellId is optional:
--   - 0 or nil => outside world spawn
--   - non-zero => interior spawn inside that building cell
function ThePathInformantSpawns:spawnOne(planet, x, z, y, heading, cellId)
	cellId = cellId or 0

	local pNpc = spawnMobile(planet, "the_path_informant", 0, x, z, y, heading, cellId)
	if pNpc ~= nil then
		AiAgent(pNpc):setConvoTemplate("the_path_conv_template")
	end
end
