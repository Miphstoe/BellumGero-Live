object_tangible_loot_loot_schematic_marine_chest_plate_crafted_schematic = object_tangible_loot_loot_schematic_shared_marine_chest_plate_crafted_schematic:new {
	templateType = LOOTSCHEMATIC,
    customName = "Marine Armor Chest Plate Schematic",
	objectMenuComponent = "LootSchematicMenuComponent",
	attributeListComponent = "LootSchematicAttributeListComponent",
	requiredSkill = "crafting_armorsmith_master",
	targetDraftSchematic = "object/draft_schematic/clothing/clothing_armor_marine_chest.iff",
	targetUseCount = 3,
}

ObjectTemplates:addTemplate(object_tangible_loot_loot_schematic_marine_chest_plate_crafted_schematic, "object/tangible/loot/loot_schematic/marine_chest_plate_crafted_schematic.iff")