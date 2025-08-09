----------------------------------------
--  ForceCrystalCaveScreenPlay
--  Rewards Force-Rank XP on cave mob kills
----------------------------------------
ForceCrystalCaveScreenPlay = ScreenPlay:new {
    numberOfActs       = 1,
    screenplayName     = "ForceCrystalCaveScreenPlay",

    lootContainers     = { 200335, 200336, 8535511 },
    lootLevel          = 100,
    lootGroups         = {
        {
            groups = {
                { group = "color_crystals",       			   chance = 3500000 },
                { group = "power_crystals",                    chance = 3500000 },
                { group = "weapon_component_advanced",         chance = 2000000 },
                { group = "clothing_attachments",              chance =  500000 },
                { group = "armor_attachments",                 chance =  500000 }
            },
            lootChance = 8000000
        }
    },
    lootContainerRespawn = 1800  -- 30 minutes
}

registerScreenPlay("ForceCrystalCaveScreenPlay", true)

function ForceCrystalCaveScreenPlay:start()
    if isZoneEnabled("dantooine") then
        self:spawnMobiles()
        self:initializeLootContainers()
    end
end

function ForceCrystalCaveScreenPlay:spawnMobiles()
    local spawnPoints = {
        { "dark_jedi_master",  89, -62,   -13.4, -139, 8535485 },
        { "dark_jedi_knight",  52.5, -67.9, -42.9,   32, 8535484 },
        { "dark_jedi_knight",  76.3, -77,   -89.3,  -81, 8535486 },
        { "dark_jedi_knight",  26.1, -43,   -68.3,   84, 8535484 },
        { "dark_jedi_knight",  64.1, -68.9, -36.8,   86, 8535485 },
        { "dark_jedi_knight",  85.3, -77.2, -62.9,  -57, 8535486 },
        { "dark_jedi_knight",  69.3, -75.7, -65.4,   30, 8535486 },
        { "dark_jedi_master",  0.7,  -13.6,  -6.9,  -82, 8535483 },
        { "dark_jedi_knight", 65.6, -77,   -78.4,  -10, 8535486 },
        { "dark_jedi_master", 23.8, -38.4, -32.8,   -2, 8535484 },
        { "dark_jedi_knight", 22.4, -42.1, -64.1,   38, 8535484 },
        { "dark_jedi_master", 49.8, -48.5, -65.6,  -51, 8535484 },
        { "dark_jedi_master", 49.7, -48,   -17.7,  167, 8535484 },
        { "dark_jedi_master", 52.1, -48.7, -104.0,  -7, 8535492 },
        { "dark_jedi_master", 91.1, -46.6, -110.8,  -80, 8535487 },
        { "dark_jedi_knight", 75.6, -46.5, -141.9,  50, 8535493 },
        { "dark_jedi_knight", 84.3, -46.9, -145.7,  21, 8535493 },
        { "dark_jedi_knight", 54, -73.5, -108.5,  -2, 8535488 },
        { "dark_jedi_knight", 62.9, -66.4, -136.5,  18, 8535488 },
        { "dark_jedi_master", 92.8, -66.2, -126.4,  -150, 8535489 },
        { "dark_jedi_knight", 117.4, -66, -107.8,  -89, 8535490 },
        { "dark_jedi_knight", 141.3, -66.6, -87.5,  -138, 8535490 },
        { "dark_jedi_knight", 150.1, -66.6, -126,  -50, 8535490 },
    }

    for i, data in ipairs(spawnPoints) do
        local tpl     = data[1]
        local x, y, z = data[2], data[3], data[4]
        local heading = data[5]
        local cell    = data[6]

        local pMob = spawnMobile("dantooine", tpl, 1800, x, y, z, heading, cell)
        if pMob then
            Logger:log(
              string.format("ForceCrystalCaveScreenPlay: spawned '%s' #%d at [%.1f,%.1f,%.1f] cell %d",
                            tpl, i, x, y, z, cell),
              LT_INFO
            )
            createObserver(OBJECTDESTRUCTION,
                           "ForceCrystalCaveScreenPlay",
                           "onCaveMobDied",
                           pMob)
        else
            Logger:log(
              string.format("ForceCrystalCaveScreenPlay: FAILED to spawn '%s' #%d", tpl, i),
              LT_ERROR
            )
        end
    end
end

function ForceCrystalCaveScreenPlay:onCaveMobDied(pMob, pKiller)
    -- only proceed for real player killers
    if not (pKiller and SceneObject(pKiller):isPlayerCreature()) then
        return 1
    end

    local co = CreatureObject(pKiller)
    -- ONLY Jedi Knight: requires the Knight title/skill
    if co and co.hasSkill and co:hasSkill("force_title_jedi_rank_03") then
        co:awardExperience("force_rank_xp", 100, true)
    end

    return 1
end