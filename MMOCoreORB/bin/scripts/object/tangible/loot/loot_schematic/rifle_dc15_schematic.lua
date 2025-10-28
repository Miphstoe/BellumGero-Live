object_tangible_loot_loot_schematic_rifle_dc15_schematic = object_tangible_loot_loot_schematic_shared_rifle_dc15_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "DC-15 Rifle Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/rifle_dc15.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_rifle_dc15_schematic, "object/tangible/loot/loot_schematic/rifle_dc15_schematic.iff")
