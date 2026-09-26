-- Bellum Gero: Species Change Token
-- Single-use item, veteran-reward candidate. See screenplays/bellum/species_change_token.lua for
-- the radial/SUI workflow and MMOCoreORB/docs/species_change_token.md for the full design writeup.
object_tangible_item_species_change_token =
  object_tangible_item_shared_species_change_token:new {
	objectMenuComponent = "SpeciesChangeTokenMenuComponent",
	customName = "Species Change Token",
	noTrade = 1,
  }

ObjectTemplates:addTemplate(object_tangible_item_species_change_token,
  "object/tangible/item/species_change_token.iff")
