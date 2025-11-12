object_tangible_loot_loot_schematic_rifle_lightning_heavy_schematic = object_tangible_loot_loot_schematic_shared_rifle_lightning_heavy_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Heavy Lightning Cannon Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/rifle_lightning_heavy.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_rifle_lightning_heavy_schematic, "object/tangible/loot/loot_schematic/rifle_lightning_heavy_schematic.iff")
