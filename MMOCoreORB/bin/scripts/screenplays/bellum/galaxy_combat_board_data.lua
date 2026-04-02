GalaxyCombatBoardData = {
	tiers = {
		[1] = {
			title = "Tier 1 - Local Threat Contracts",
			kills = 50,
			reward = 25000,
		},
		[2] = {
			title = "Tier 2 - Frontier Hunt Contracts",
			kills = 35,
			reward = 35000,
		},
		[3] = {
			title = "Tier 3 - Dangerous Prey Contracts",
			kills = 30,
			reward = 45000,
		},
		[4] = {
			title = "Tier 4 - Elite Target Contracts",
			kills = 20,
			reward = 75000,
		},
		[5] = {
			title = "Tier 5 - Apex Threat Contracts",
			kills = 10,
			reward = 150000,
		},
	},

	contracts = {
		[1] = {
			{
				key = "meatlumps",
				targetName = "Meatlumps",
				locationHint = "Corellia",
				allowedSocialGroups = { "meatlump" },
				allowedFactions = { "meatlump" },
				allowedTemplates = {
					"meatlump_buffoon",
					"meatlump_clod",
					"meatlump_cretin",
					"meatlump_fool",
					"meatlump_loon",
					"meatlump_oaf",
					"meatlump_stooge",
				},
			},
			{
				key = "valarians",
				targetName = "Valarians",
				locationHint = "Tatooine",
				allowedSocialGroups = { "valarian" },
				allowedFactions = { "valarian" },
				allowedTemplates = {
					"valarian_assassin",
					"valarian_chief_assassin",
					"valarian_compound_guard",
					"valarian_compound_guard_quest",
					"valarian_courier",
					"valarian_enforcer",
					"valarian_henchman",
					"valarian_scout",
					"valarian_swooper",
					"valarian_swooper_leader",
					"valarian_thief",
					"valarian_thug",
				},
			},
			{
				key = "swoop_gangers",
				targetName = "Swoop Gangers",
				locationHint = "Corellia / Talus",
				allowedSocialGroups = { "cor_swoop", "swoop" },
				allowedFactions = { "cor_swoop", "swoop" },
				allowedTemplates = {
					"swooper",
					"swooper_corellia",
					"swooper_gangmember",
					"swooper_leader",
				},
			},
			{
				key = "lord_nyax_followers",
				targetName = "Lord Nyax Followers",
				locationHint = "Corellia",
				allowedSocialGroups = { "followers_of_lord_nyax" },
				allowedFactions = { "followers_of_lord_nyax" },
				allowedTemplates = {
					"disciple_of_lord_nyax",
					"fanatic_of_lord_nyax",
					"fiend_of_lord_nyax",
					"minion_of_lord_nyax",
					"servant_of_lord_nyax",
					"visionary_of_lord_nyax",
					"zealot_of_lord_nyax",
				},
			},
		},
		[2] = {
			{
				key = "tusken_raiders",
				targetName = "Tusken Raiders",
				locationHint = "Tatooine",
				allowedSocialGroups = { "tusken_raider" },
				allowedFactions = { "tusken_raider" },
				allowedTemplates = {
					"tusken_avenger",
					"tusken_berserker",
					"tusken_brute",
					"tusken_captain",
					"tusken_chief",
					"tusken_executioner",
					"tusken_fighter",
					"tusken_guard",
					"tusken_observer",
					"tusken_raider",
					"tusken_savage",
					"tusken_sniper",
					"tusken_wanderer",
					"tusken_warrior",
				},
			},
			{
				key = "imperial_troopers",
				targetName = "Imperial Troopers",
				locationHint = "Various",
				allowedSocialGroups = { "imperial" },
				allowedFactions = { "imperial" },
				allowedTemplates = {
					"imperial_trooper",
					"stormtrooper",
					"stormtrooper_bombardier",
					"stormtrooper_captain",
					"stormtrooper_colonel",
					"stormtrooper_commando",
					"stormtrooper_major",
					"stormtrooper_medic",
					"stormtrooper_rifleman",
					"stormtrooper_sniper",
					"stormtrooper_squad_leader",
				},
			},
			{
				key = "rebel_troopers",
				targetName = "Rebel Troopers",
				locationHint = "Various",
				allowedSocialGroups = { "rebel" },
				allowedFactions = { "rebel" },
				allowedTemplates = {
					"rebel_trooper",
					"specforce_lieutenant",
					"specforce_marine",
					"specforce_technician",
				},
			},
			{
				key = "war_droid_scouts",
				targetName = "War Droid Scouts",
				locationHint = "Lok / Talus",
				allowedTemplates = {
					-- PLACEHOLDER: Replace these with your confirmed Lok/Talus scout droid templates.
					"PLACEHOLDER_war_droid_scout_lok",
					"PLACEHOLDER_war_droid_scout_talus",
				},
			},
			{
				key = "sand_beetle_clicks",
				targetName = "Monstrous Giant Sand Beetles",
				locationHint = "Tatooine",
				allowedSocialGroups = { "beetle" },
				allowedTemplates = {
					"giant_sand_beetle",
					"monstrous_sand_beetle",
				},
			},
		},
		[3] = {
			{
				key = "nightsisters",
				targetName = "Nightsisters",
				locationHint = "Dathomir",
				allowedSocialGroups = { "nightsister" },
				allowedFactions = { "nightsister" },
				allowedTemplates = {
					"nightsister_hex_weaver",
					"nightsister_initiate",
					"nightsister_outcast",
					"nightsister_protector",
					"nightsister_rancor_tamer",
					"nightsister_ranger",
					"nightsister_sentinel",
					"nightsister_sentry",
					"nightsister_shaman",
					"nightsister_slave",
					"nightsister_spell_weaver",
					"nightsister_stalker",
				},
			},
			{
				key = "kimogilas",
				targetName = "Kimogilas",
				locationHint = "Lok",
				allowedSocialGroups = { "kimogila" },
				allowedFactions = { "kimogila" },
				allowedTemplates = {
					"dune_kimogila",
					"enraged_kimogila",
					"giant_kimogila",
					"kimogila",
				},
			},
			{
				key = "dark_troopers",
				targetName = "Dark Troopers",
				locationHint = "Various",
				allowedSocialGroups = { "dark_trooper" },
				allowedFactions = { "imperial" },
				allowedTemplates = {
					"dark_trooper",
					"dark_trooper_novatrooper",
				},
			},
			{
				key = "singing_mountain_clan",
				targetName = "Singing Mountain Clan",
				locationHint = "Dathomir",
				allowedSocialGroups = { "mtn_clan" },
				allowedFactions = { "mtn_clan" },
				allowedTemplates = {
					"singing_mountain_clan_arch_witch",
					"singing_mountain_clan_councilwoman",
					"singing_mountain_clan_dragoon",
					"singing_mountain_clan_guardian",
					"singing_mountain_clan_huntress",
					"singing_mountain_clan_initiate",
					"singing_mountain_clan_outcast",
					"singing_mountain_clan_scout",
					"singing_mountain_clan_sentry",
					"singing_mountain_clan_slave",
				},
			},
			{
				key = "imperial_war_droids",
				targetName = "Imperial War Droids",
				locationHint = "Various",
				allowedTemplates = {
					-- Safe default using stock droids. Replace if you want a broader pool later.
					"imperial_battle_droid",
					"imperial_probe_drone",
				},
			},
		},
		[4] = {
			{
				key = "rancors",
				targetName = "Rancors",
				locationHint = "Dathomir",
				allowedSocialGroups = { "rancor" },
				allowedFactions = { "rancor" },
				allowedTemplates = {
					"rancor",
				},
			},
			{
				key = "bull_rancors",
				targetName = "Bull Rancors",
				locationHint = "Dathomir",
				allowedSocialGroups = { "rancor" },
				allowedFactions = { "rancor" },
				allowedTemplates = {
					"bull_rancor",
				},
			},
			{
				key = "giant_spiders",
				targetName = "Giant Spiders",
				locationHint = "Endor / Dathomir",
				allowedTemplates = {
					-- PLACEHOLDER: Replace these with your confirmed giant spider templates only.
					"PLACEHOLDER_endor_giant_spider",
					"PLACEHOLDER_dathomir_giant_spider",
				},
			},
		},
		[5] = {
			{
				key = "krayt_dragons",
				targetName = "Krayt Dragons",
				locationHint = "Tatooine",
				allowedSocialGroups = { "krayt" },
				allowedFactions = { "krayt" },
				allowedTemplates = {
					"canyon_krayt_dragon",
					"giant_canyon_krayt_dragon",
					"krayt_dragon_adolescent",
					"krayt_dragon_ancient",
					"krayt_dragon_grand",
				},
			},
			{
				key = "high_end_rancors",
				targetName = "High-end Rancors",
				locationHint = "Dathomir",
				allowedSocialGroups = { "rancor" },
				allowedFactions = { "rancor" },
				allowedTemplates = {
					"ancient_bull_rancor",
					"enraged_bull_rancor",
					"enraged_rancor",
					"nightsister_enraged_bull_rancor",
					"nightsister_enraged_rancor",
				},
			},
			{
				key = "nightsister_elders",
				targetName = "Nightsister Elders",
				locationHint = "Dathomir",
				allowedSocialGroups = { "nightsister" },
				allowedFactions = { "nightsister" },
				allowedTemplates = {
					"nightsister_boss",
					"nightsister_elder",
				},
			},
		},
	},
}

GalaxyCombatBoardData.contractsByKey = {}

for tier, contractList in pairs(GalaxyCombatBoardData.contracts) do
	for i = 1, #contractList, 1 do
		local contract = contractList[i]
		contract.tier = tier
		contract.requiredKills = GalaxyCombatBoardData.tiers[tier].kills
		contract.rewardCredits = GalaxyCombatBoardData.tiers[tier].reward
		GalaxyCombatBoardData.contractsByKey[contract.key] = contract
	end
end
