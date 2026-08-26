
object_tangible_loot_loot_schematic_battle_droid_foundry_schematic = object_tangible_loot_loot_schematic_shared_battle_droid_foundry_schematic:new {
	templateType = LOOTSCHEMATIC,
	customObjectName = "Battle Droid Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_droidengineer_master",
	targetDraftSchematic = "object/draft_schematic/droid/droid_battle_droid_foundry.iff",
	targetUseCount = 1
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_battle_droid_foundry_schematic, "object/tangible/loot/loot_schematic/battle_droid_foundry_schematic.iff")
