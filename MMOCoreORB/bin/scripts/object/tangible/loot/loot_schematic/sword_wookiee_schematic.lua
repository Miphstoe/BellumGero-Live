object_tangible_loot_loot_schematic_sword_wookiee_schematic = object_tangible_loot_loot_schematic_shared_sword_wookiee_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Blade of Nyenthi'Oris Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/sword_wookiee.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_sword_wookiee_schematic, "object/tangible/loot/loot_schematic/sword_wookiee_schematic.iff")