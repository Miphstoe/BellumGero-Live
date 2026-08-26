
object_tangible_loot_loot_schematic_droideka_foundry_schematic = object_tangible_loot_loot_schematic_shared_droideka_foundry_schematic:new {
	templateType = LOOTSCHEMATIC,
	customObjectName = "Droideka Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_droidengineer_master",
	targetDraftSchematic = "object/draft_schematic/droid/droid_droideka_foundry.iff",
	targetUseCount = 1
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_droideka_foundry_schematic, "object/tangible/loot/loot_schematic/droideka_foundry_schematic.iff")
