-- The Rebel Forward Base starport lost its shuttle when the outposts were moved (2026-10-04): the stored shuttle was
-- still at the old site, competed with the new Generator Ridge shuttleport's shuttle and was deleted from the database.
-- A starport only gets its shuttle when the building is first created, so it never came back and tickets to Rebel
-- Forward Base failed. This spawns a (non-persistent) shuttle at the starport on every boot; ScheduleShuttleTask links it
-- to the "Rebel Forward Base" travel point. If a stored shuttle ever shows up again, the duplicate is removed there.
HothRebelShuttle = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "HothRebelShuttle",
	planet = "hoth",
	template = "object/mobile/player_transport.iff",
	-- the starport's own shuttle child: building centre, z + 7, turned 90 degrees (outpost_starport.lua)
	x = -420.0, z = 34.76, y = 600.0, qw = 0.707107, qy = 0.707107,
}

registerScreenPlay("HothRebelShuttle", true)

function HothRebelShuttle:start()
	if (isZoneEnabled(self.planet)) then
		spawnSceneObject(self.planet, self.template, self.x, self.z, self.y, 0, self.qw, 0, self.qy, 0)
	end
end
