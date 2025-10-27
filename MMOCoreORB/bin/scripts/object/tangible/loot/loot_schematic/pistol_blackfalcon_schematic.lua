object_tangible_loot_loot_schematic_pistol_blackfalcon_schematic = object_tangible_loot_loot_schematic_shared_pistol_blackfalcon_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Black Falcon Pistol Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_weaponsmith_master",
	targetDraftSchematic = "object/draft_schematic/weapon/pistol_blackfalcon.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_pistol_blackfalcon_schematic, "object/tangible/loot/loot_schematic/pistol_blackfalcon_schematic.iff")
