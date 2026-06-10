-- Jedi Robe loot pool — 18 robes, equal weight
-- 17 robes at 555,556 + Revan's Robe at 555,548 = 10,000,000 total

jedi_robe = {
	description = "",
	minimumLevel = 0,
	maximumLevel = -1,
	lootItems = {
		{itemTemplate = "cloak_of_hate_hood_down", weight = 555556},
		{itemTemplate = "cloak_of_hate_hood_up",   weight = 555556},
		{itemTemplate = "shatterpoint",             weight = 555556},
		{itemTemplate = "robe_jedi_black_01",       weight = 555556},
		{itemTemplate = "robe_jedi_black_02",       weight = 555556},
		{itemTemplate = "robe_jedi_grey_s01",       weight = 555556},
		{itemTemplate = "robe_jedi_grey_s02",       weight = 555556},
		{itemTemplate = "robe_jedi_grey_s03",       weight = 555556},
		{itemTemplate = "robe_jedi_grey_s04",       weight = 555556},
		{itemTemplate = "robe_jedi_grey_s05",       weight = 555556},
		{itemTemplate = "robe_jedi_grey2_s01",      weight = 555556},
		{itemTemplate = "robe_jedi_grey2_s02",      weight = 555556},
		{itemTemplate = "robe_jedi_grey2_s03",      weight = 555556},
		{itemTemplate = "robe_jedi_grey2_s04",      weight = 555556},
		{itemTemplate = "robe_jedi_grey2_s05",      weight = 555556},
		{itemTemplate = "robe_jedi_tan_01",         weight = 555556},
		{itemTemplate = "robe_jedi_tan_02",         weight = 555556},
		{itemTemplate = "robe_revan",               weight = 555548},
	}
}

addLootGroupTemplate("jedi_robe", jedi_robe)
