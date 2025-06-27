looted_container = {
    description = "",
    minimumLevel = 0,
    maximumLevel = 0,
    lootItems = {
        -- Junk/Misc Items (15% chance total, excluding locked_container)
        -- Common
        {itemTemplate = "broken_decryptor", weight = 62500},
        {itemTemplate = "camera", weight = 62500},
        {itemTemplate = "corrupt_datadisk", weight = 62500},
        {itemTemplate = "corsec_id_badge", weight = 62500},
        {itemTemplate = "damaged_datapad", weight = 62500},
        {itemTemplate = "decorative_bowl", weight = 62500},
        {itemTemplate = "decorative_shisa", weight = 62500},
        {itemTemplate = "dermal_analyzer", weight = 62500},
        {itemTemplate = "dud_firework_grey", weight = 62500},
        {itemTemplate = "dud_firework_red", weight = 62500},
        {itemTemplate = "empty_cage", weight = 62500},
        {itemTemplate = "expensive_basket", weight = 62500},
        {itemTemplate = "expired_ticket", weight = 62500},
        {itemTemplate = "hyperdrive_part", weight = 62500},
        {itemTemplate = "ledger", weight = 62500},
        {itemTemplate = "locked_briefcase", weight = 62500},
        {itemTemplate = "loudspeaker", weight = 62500},
        {itemTemplate = "palm_frond", weight = 62500},
        {itemTemplate = "photographic_image", weight = 62500},
        {itemTemplate = "recorded_image_1", weight = 62500},
        {itemTemplate = "recording_rod", weight = 62500},
        {itemTemplate = "slave_collar", weight = 62500},
        {itemTemplate = "used_ticket", weight = 62500},
        {itemTemplate = "worklight", weight = 62500},
        -- Uncommon
        {itemTemplate = "force_color_crystal", weight = 31250},
        {itemTemplate = "force_power_crystal", weight = 62500},
        {itemTemplate = "jedi_holocron_dark", weight = 31250},
        {itemTemplate = "jedi_holocron_light", weight = 31250},
        {itemTemplate = "attachment_clothing", weight = 31250},
        {itemTemplate = "attachment_armor", weight = 31250},
        
        -- Locked Container (10% chance)
        {itemTemplate = "locked_container", weight = 1000000},
        
        -- Weapons (25% chance)
        {groupTemplate = "weapons_all", weight = 2500000},
        -- Armors (25% chance)
        {groupTemplate = "armor_all", weight = 2500000},
        -- Clothing (25% chance)
        {groupTemplate = "wearables_all", weight = 2500000},
       
    }
}
addLootGroupTemplate("looted_container", looted_container)