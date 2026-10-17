-- Bellum Gero: Species Change Token
-- Single-use item, veteran-reward candidate. See screenplays/bellum/species_change_token.lua for
-- the radial/SUI workflow and MMOCoreORB/docs/species_change_token.md for the full design writeup.
-- Use the stock data-disk client template. The custom shared_species_change_token.iff
-- is absent from the loaded TREs, so it cannot provide the item's client data.
object_tangible_item_species_change_token =
  object_tangible_item_shared_loot_credit_chip:new {
	gameObjectType = 8211, -- GENERICITEM; createObject needs a registered object type.
	objectMenuComponent = "SpeciesChangeTokenMenuComponent",
	customName = "Species Change Token",
	noTrade = 1,
  }

ObjectTemplates:addTemplate(object_tangible_item_species_change_token,
  "object/tangible/item/species_change_token.iff")
