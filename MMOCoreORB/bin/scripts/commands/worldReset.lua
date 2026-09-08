-- /worldreset
-- Bellum Gero highly protected administrative reset of DEPLOYED player structures
-- and PLAYER-CREATED cities. Requires Admin Level 15 PLUS a server-side secret,
-- a clean dry run, an armed window and the exact confirmation phrase.
--
--   /worldreset authenticate <secret>
--   /worldreset dryrun
--   /worldreset status
--   /worldreset arm
--   /worldreset execute RESET-HOUSING-AND-CITIES
--   /worldreset cancel
--
-- All logic and every safeguard live in the C++ handler (WorldResetCommand /
-- WorldResetManager). This entry only registers the slash command.

WorldResetCommand = {
	name = "worldreset",
	characterAbility = "admin",
}

AddCommand(WorldResetCommand)
