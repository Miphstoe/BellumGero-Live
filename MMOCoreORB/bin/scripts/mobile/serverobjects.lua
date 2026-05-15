-- Conversations
includeFile("conversations.lua")

-- Dress Groups - Must be loaded before mobiles
includeFile("dressgroup/serverobjects.lua") 

-- Creatures
includeFile("corellia/serverobjects.lua")
includeFile("dantooine/serverobjects.lua")
includeFile("dathomir/serverobjects.lua")
includeFile("endor/serverobjects.lua")
includeFile("event/serverobjects.lua")
includeFile("herald/serverobjects.lua")
includeFile("lok/serverobjects.lua")
includeFile("misc/serverobjects.lua")
includeFile("naboo/serverobjects.lua")
includeFile("pet/serverobjects.lua")
includeFile("quest/serverobjects.lua")
includeFile("rori/serverobjects.lua")
includeFile("space/serverobjects.lua")
includeFile("talus/serverobjects.lua")
includeFile("tatooine/serverobjects.lua")
includeFile("thug/serverobjects.lua")
includeFile("townsperson/serverobjects.lua")
includeFile("tutorial/serverobjects.lua")
includeFile("yavin4/serverobjects.lua")

includeFile("faction/serverobjects.lua")
includeFile("dungeon/serverobjects.lua") 

-- Weapons
includeFile("weapon/serverobjects.lua") 

-- Spawn Groups
includeFile("spawn/serverobjects.lua")

-- Trainer
includeFile("trainer/serverobjects.lua")

-- Mission
includeFile("mission/serverobjects.lua")

-- Lairs
includeFile("lair/serverobjects.lua")

-- Outfits
includeFile("outfits/serverobjects.lua")

-- Custom content - Loads last to allow for overrides...
--includeFile("../custom_scripts/mobile/serverobjects.lua")
includeFile("custom_events/serverobjects.lua")
includeFile("acklay_worldboss.lua")
includeFile("enhanced_gaping_spider_boss.lua")

-- Apprentice Coin Vendor
includeFile("vendors/apprentice_coin_vendor.lua")

-- SEA Vendor
-- mobile (creature) template FIRST so spawnMobile can find it
includeFile("vendors/attachment_exchange_vendor.lua")

-- BG Token Vendor
includeFile("vendors/bg_token_vendor.lua")

-- BG Token Vendor 2 (75 tokens per item)
--includeFile("vendors/bg_token_vendor_2.lua")

-- BG Token Vendor 3 - Veteran Rewards (75 tokens per item)
includeFile("vendors/bg_token_vendor_3.lua")

-- Bellum Gero custom mobiles
includeFile("bellum/bg_force_old_man.lua")
includeFile("bellum/mallichae_bg_rite.lua")
includeFile("bellum/ranger_razor_cat_alpha.lua")
includeFile("bellum/the_hand.lua")
includeFile("bellum/gloomfang_mauler.lua")
includeFile("bellum/rotmaw_mauler.lua")
includeFile("bellum/dreadmaw_mauler.lua")
includeFile("bellum/xalgorath.lua")
includeFile("bellum/imperial_traitor.lua")
includeFile("bellum/tour_coordinator.lua")
includeFile("bellum/master_artisan_procurement_officer.lua")
includeFile("bellum/imperial_traitor_elite.lua")
includeFile("bellum/rebel_traitor.lua")
includeFile("bellum/rebel_traitor_elite.lua")
includeFile("bellum/field_captain_rax_vorn.lua")
includeFile("bellum/war_general_kael_draxus.lua")
includeFile("bellum/high_strategist_velkor_thane.lua")
includeFile("bellum/supreme_warlord_darth_malvek.lua")
includeFile("bellum/painting_exchange_curator.lua")
includeFile("bellum/captain_durn_valek.lua")
includeFile("bellum/hot_pirate_heavy_raider.lua")
includeFile("bellum/hot_pirate_flame_trooper.lua")
includeFile("bellum/hot_pirate_shield_technician.lua")
includeFile("bellum/hot_pirate_berserker_bruiser.lua")
includeFile("bellum/hot_pirate_mortar_specialist.lua")
includeFile("bellum/hot_pirate_kragg_siegebreaker.lua")
includeFile("bellum/hot_emplacement_turret.lua")
includeFile("bellum/hot_emplacement_generator.lua")
includeFile("bellum/hot_emplacement_artillery.lua")
-- Holocron Village Vendor (5 Holocrons of Destiny per item)
includeFile("vendors/holocron_village_vendor.lua")

-- Artisan Procurement Vendor
includeFile("vendors/artisan_procurement_vendor.lua")
