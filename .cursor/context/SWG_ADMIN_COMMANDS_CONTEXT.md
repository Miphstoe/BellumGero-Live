# SWGEmu Admin Commands (Context)

Source: `SWGEMU-Admin Commands booklet draft 5.pdf` (compiled by Silurian, verified 2012-04-23)  
Local copy: `C:\Users\DatJe\Downloads\SWGEMU-Admin Commands booklet draft 5.pdf`

This file captures the **admin commands section** (the portion of the booklet before the appendices).

## Notes for BG local dev

- **“God mode”** for a character is typically available once the account has **admin privileges** (e.g., `accounts.admin_level = 1`). The booklet lists `/invulnerable` (aka `/invuln`) as a related command.
- The rest of this document is the extracted command list as-is.

## Extracted command list (verbatim)

```text
Administrator Commands list
Compiled by Silurian
Each command verified 4/23/2012
Green = Working as intended
Red = none functioning
Orange = unable to verify working status
or not completely working

-- 1 of 94 --

Section 1.
Confirmed working Commands
/adjustlotcount <player name> (X)
This command adjusts the players lot count by the value entered.
This can be a positive to grant extra lots or a negitive to remove lots
Example 1: /adjustlotcount 10 will increase the lot count to 20
Example 2: /adjustlotcount -10 will adjust the lot count back down to 10
This value can go negetive so becarefull when using.
/credits <first name> <add/subtract> <amount> <bank/cash>
Example 1: /credits silurain add 50000 cash
This will add 50000 credits to the players cash amount
Example 2: /credits silurian subtract 5000 bank
This will subtract 5000 credits from the players bank account
Note/bug at this time you can with draw more cash then the player has
/getAccountInfo [accountName] - Looks up the account information for the current target, or
specified account username. Use /findPlayer to locate player you wish to get the
account information for.
/findPlayer {playerName} - Reports back the location, direction, and other pertinent
information about the player specified by playerName.
/freezePlayer [playerName] {reason} - Freezes the targeted, or named, player, not allowing
them to move.
/unfreezePlayer -unfreezes player
/getPlayerId [playerName] - Returns the targeted, or optionally named, player's objectId via
system message
/gmRevive [healthPercentage]- Allows a GameMaster to revive a target, optionally restoring a
percentage of health, wounds, and battle fatigue. Percentage defaults to 100%.
(note) at this time you must use command twice to restore the health bar
/kill – Kills the target creature or player
/kick [playerName] {duration} {reason} - Kicks the player, and all connected clients on the
same account, from the server, banning their account for the specified duration in minutes.
If duration is -1, then the player is banned indefinitely. See /removeBannedPlayer to
remove a ban from a player.

-- 2 of 94 --

/removeBannedPlayer {accountName} {reason} - Removes a ban on a player's account. Notice,
this takes an account name as a parameter.(note unable to verify due to /kick command
not starting a ban timer)
/getStationName [accountName] - Returns the station name associated with the targeted player,
or optionally specified account username.
/grantTitle {title}(note find title list)
/grantBadge <badgeID> - Grants the specified badge to the targeted player.(note find badge list)
/revokeBadge {badgeId} - Revokes a badge from the targeted player.
/teleportTo <targetName> - Teleports to the specified player's location.
Example: /teleportto Silurian
/teleportTarget <targetName> [<planet> <x> <y>] [<z> <parentID>] - Teleports the targeted
player to specified location.
Example: /teleporttarget 0,0 Corellia
/teleport <planet> <x> <y> - Teleports yourself to the location specified.
Example: /teleport naboo 0,0
/SetFaction {faction} [overt|covert|onleave] - Sets the targeted object's faction to neutral, rebel,
or imperial as specified. Optionally, may specify the faction state as overt, covert, or
onleave.
/snoop - Allows the player to look at the contents of a targeted object's inventory, and all
containers within.
/wipeItems - Wipes all items in the targeted player's inventory.
/invulnerable - Makes the target invulnerable to all attacks. Notice, they can still attack back.
Can also abbreviate with /invuln . This is also a self only command at this time.
/setSpeed <speedModifier> [<duration>] - Sets your movement speed for the duration.
Duration defaults to 30 minutes.
/BroadcastGalaxy {message} - Broadcasts a system message to all players currently logged on
the server.
/listGuilds [guildFilter] - Lists all guilds on the server that match the specified guild filter. The
guild filter is a search term based on name and/or guild tag.

-- 3 of 94 --

/resendLoginMessageToAll - Re-broadcasts the login message that is initially sent at player
login.
/grantSkill <skillBox> - Awards the specified skill box to the targeted player to include all
prereqisites (/revokeskill box command does not work so players must unlearn any
granted skill boxes by hand)(See Appendix I Skill Box Tables)
Example: /grantskill social_entertainer_master – this would give the target Master
Entertainer with all prereqisite skills,
Admin Create item commands
(See Appedix II Generate Items/Creature/NPC lists)
/object – This command is broken down into three parts.
/object createitem <path> <quantity>
/object createresource <resourcename> <quanity>
/object createloot <path> <level>
/generatecrafteditem {script} – command accepts many paths to generate ingame items and
resources
/gmCreateClassResource {resourceClass} - Creates a new resource based on the specified
class.
Example: /gmCreateClassResource copper this will add a random type of copper
to the planets resource table
/createCreature {creatureScript} [{x} {z} {y}] [planet] [cellid] - Creates the creature specified
at the player's current location, or at a location specified.
Example: /
/createNPC {npcScript} [{x} {z} {y}] [planet] [cellid] - Creates the NPC specified at the
player's current location, or at a location specified.

-- 4 of 94 --

Jedi Specific Administrator comands
This section is incomplete use at your own risk
these commands may bug your character at this time
(See Jedi Skill Box Tables Appendix III)
At this time after invoking any of these comands you may need to soft log and reopen skill panels and click on difrent
windows to get changes to show on the character skill windows.
/gmJediState <target>/<player name> (X)
arguments
0= nonforce sensitive
1 = Force Sensitive
2 = Jedi Initiate
4 = light force rank Jedi
8 = dark force rank Jedi
This command only determines which boxes under the all professions tab are visible in
reference to Jedi
/grantPadawanTrialsEligibility – this comand grants you the padawan trails completion and
allows for you to obtain padawan robes from force shrines(Note not completely
implimented)
/overridePadawanTrialsEligibility [true|false] - Overrides the targeted players eligibility to
participate in the padawan trials. The argument is optional, and defaults to true.
/resetJedi – removes all Force Sensitive and Jedi skills and resets their progressions to none
/gmForceRank – not implemented place holder
/gmFsVillage – not implemented place holder
Steps to make a jedi
invoke the gmjedistate command with either 4 or 8
now you can use the /grantskills command with the difrent skill trees listed below to get
you jedi or FS skill trees.
/grantPadawanTrialsEligibility targeting your self or another player
meditate at a force shrine for your padawan robes

-- 5 of 94 --

Confirmed NonFunctional Commands
/setFactionStanding {faction} {amount} - Sets the amount of faction points for the specified
faction - this faction can range from any known faction (i.e. Janta, Kunga,
Mook, etc.).
/clearVeteranReward {veteranReward} - Resets a used veteran reward, so that it may be
selected again.
This is the path to the script for the veteran(note need vertern rewards list)
/getGameTime - Looks up how many hours the current target has actively played.
/emptyMailTarget - Deletes all mail from the server belonging to the targeted player.
/editStats - Allows the player to adjust the stats of the target, setting Maximum and Current
values
/setTEF [duration] - Sets the target to be TEF'd to everyone. Specifying -1 for duration will give
this target a permanent TEF until incapacitated, or killed.
/setLastName {lastName} - Sets the last name of the targeted object.
(Note:Command executes but no name change takes place.)
/setName {name} - Sets the name of the targeted object. If used on a player, this effectively
changes the first and last name of the player.
/addBannedPlayer {name} {duration} {reason} - Bans a player's account without disconnecting
the player from the server.
/editAppearance - Allows the player to enter into an image design mode with the current target,
without the need for target consent.
/hasVeteranReward {veteranReward} - Checks to see if the targeted player has used the
specified veteran reward option. (Note need verteran rewards list)

-- 6 of 94 --

/setFirstName {firstName} - Attempts to set the target's first name. If the target is a player, it
must pass naming filter checks. (Note :Command executes but no name change
takes place.)
/harmful - Enables the target to enter combat mode.
/harmless - Disables the target from entering combat mode. Notice, they can still be attacked.
/broadcastArea {range} {message} - Broadcasts a system message within the range specified.
/revokeSkill {skillBox} - Revokes a skill from the targeted player.
/broadcastPlanet {planet} {message} - Broadcasts a system message to all players on the planet
specified. See Planet Names and IDs below for a listing of accetable values.
/setLoginMessage {message} - Sets the login message that is displayed when a player logs on to
the server for the first time that session.(currently deliniated to a configure file so unable to
change from in game)
/setLoginTitle {title} - Sets the login title that is displayed with the login message when a player
logs on to the server for the first time that session.(currently deliniated to a configure file so
unable to change from in game)
/setPlanetLimit {amount} - Sets the maximum allowed players to be on this planet. When
this limit is reached, travel to this planet is prohibited, and players attempted to logon
to this planet are blocked.

-- 7 of 94 --

Untested, Unverifiable,Partially working and Debug
commands
/cityInfo [cityFilter] - Displays the city status report for the current city without needing to
use the city management terminal. Optionally searches for a city by name, based
on a filter. This filter uses the same rules as the /listGuilds command.
/planetwarp {planet} - Warps to the specified planet.
/planetwarpTarget [playerName] {planet} - Warps the targeted, or optionally
specified, player to the planet indicated.'
/gmCreateSpecificResource {specifiedResource} {amount} - Creates a resource container of a
specific resource. (Note Functions the same as /gmCreateClassResource)
/getRank-no information on functions or syntax
/activateQuest –
/deactivateQuest –
/completeQuest - Marks a quest as completed.
/clearCompletedQuest – reward.
/ListActiveQuests -
/listCompletedQuests -
/setExperience {experienceName} {amount} - Sets the type of experience to the specified
amount on the targeted player. (Functions but puts a string type for the Experience)
/cityban – bans targeted player from current city

-- 8 of 94 --

/unCityBan - Removes a city ban in the current city on the targeted player.
/combat - Debug command used for combat testing. Arguments to be determined, but
should accept many.
/craft - Debug command used for crafting testing. Arguments to be determined, but should
accept many.
/createMissionElement -
/database {query} - Debug command used to send a raw query to the server database.
Arguments to be determined, but most likely accepts RAW SQL queries, or some type of
query language to interface with the database.
/destroy [destroyChildren] - Debug command used to do a hard destroy on an object. Calls
internal cpp command
/SceneObject::destroyObjectFromDatabase(bool destroyChildren). Argument
destroyChildren defaults to true.
/dumpTargetInformation - Dumps debug information about the targeted object, and emails
a copy of the information to the player using the command.
/dumpZoneInformation [zoneId] - Dumps debug information about the current zone, and
emails a copy of the information to the player using the command.
/findObject {objectId} - Reports back the location, direction, and other pertinent
information about the object specified by the objectId.

-- 9 of 94 --

/ForceCommand {commandName} [arguments] - Debug command used to execute
commands on the target, or self even if the target does not have sufficient abilities to
perform the command.
/getObjVars - Debug command. Dumps a list of all object variables on the target object,
and their specified values.
/getSpawnDelays - Returns the amount of time in between spawning waves on the
targeted SpawningElement.
/GetVeteranRewardTimeCs -
/gmForceCommand - alias of /forceCommand perhaps with a lesser accessibility level.
/lag {delay} - Debug command that simulates lag with the specified ms delay.
/manufacture {draftSchematic} - Debug command used to produce manufactured items.
/overrideActiveMonths {months} - Overrides the targeted players active months, setting it
to the new value specified.
/resource - Debug command to perform some type of raw command with the resource
manager.
/ResourceSetName -

-- 10 of 94 --

/script {scriptPath} [arguments] - Debug command to execute a server side script.
/searchCorpse -
/secretSpawnSpam -
/server {command} - Debug command to interface with the server's command line from
in-game.
/setMaximumSpawnTime {miliseconds} - Sets the maximum spawn time on the
SpawningElement in miliseconds.
/createSpawningElement {spawnerScript} [on|off] - Creates a spawning element based on a
predefined script at the player's current location. Optional parameter to automatically start the
spawner object defaults to off.
/createSpawningElementWithDifficulty {spawnerScript} {difficulty} [on|off] - Creates a
spawning element based on a predefined script, with a defined difficulty level at the
player's current location. Optional parameter to automatically start the spawner object
defaults to off.
/setMinimumSpawnTime {miliseconds} - Sets the minimum spawn time on the
SpawningElement in miliseconds.
/setPlayerAppearance -
/setPlayerState -
/setPublicState -

-- 11 of 94 --

/setRank -
/setVeteranReward -
/showFactionInformation - Displays information about the faction of the targeted object.
/showSpawnRegion - Some type of debug command that either lists the range of the
spawning region, and it's center point, or visibly displays some type of boundary.
/skill - Debug command. TBD.
/spawnStatus -
/startCitySpawner -
/startSpawner {namedSpawningElement} - Starts a named SpawningElement's spawn
cycle.
/startTargetSpawner - Starts the targeted SpawningElement's spawn cycle.
/startTraceLogging -
/stopCitySpawner -
/stopSpawner {namedSpawningElement} - Stops the named SpawningElement's spawn
cycle.

-- 12 of 94 --

/stopTraceLogging
/stopTargetSpawner - Stops the targeted SpawningElement's spawn cycle.
```
