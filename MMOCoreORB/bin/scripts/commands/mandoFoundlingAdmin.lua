-- /mandoFoundlingAdmin [partialCharacterName] [fixdone]
-- Privileged admin only (C++ gate). Reports MandoWayOfLife Foundling quota + chapter flags.

MandoFoundlingAdminCommand = {
	name = "mandoFoundlingAdmin",
	-- Must match staff skills (admin_player_management_01, etc.). Blocks non-staff on server.
	characterAbility = "mandoFoundlingAdmin",
}

AddCommand(MandoFoundlingAdminCommand)
