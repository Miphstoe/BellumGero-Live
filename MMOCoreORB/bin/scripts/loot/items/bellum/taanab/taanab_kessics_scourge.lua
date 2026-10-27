-- Taanab boss loot (Norulac raiders / Old Thunderhorn).
taanab_kessics_scourge = {
	minimumLevel = 0,
	maximumLevel = -1,
	customObjectName = "Kessic's Scourge",
	directObjectTemplate = "object/weapon/ranged/pistol/pistol_dl44_metal.iff",
	craftingValues = {
		{"mindamage",100,160,0},
		{"maxdamage",200,280,0},
		{"attackspeed",4.2,2.6,1},
		{"woundchance",10,20,0},
		{"roundsused",18,55,0},
		{"hitpoints",600,1300,0},
		{"zerorangemod",5,5,0},
		{"maxrangemod",-70,-70,0},
		{"midrange",18,18,0},
		{"midrangemod",12,32,0},
		{"maxrange",64,64,0},
		{"attackhealthcost",28,12,0},
		{"attackactioncost",38,18,0},
		{"attackmindcost",16,6,0},
		{"zerorange",0,0,0},
	},
	customizationStringNames = {},
	customizationValues = {}
}

addLootItemTemplate("taanab_kessics_scourge", taanab_kessics_scourge)
