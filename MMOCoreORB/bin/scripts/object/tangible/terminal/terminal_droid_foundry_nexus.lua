-- Bellum Gero Droid Foundry Nexus
--
-- Uses the stock Nym cave terminal interaction profile so the Foundry console
-- behaves like a normal SWG "Use" terminal (including double-click behavior),
-- while the custom client IFF supplies the bulky shipping-terminal appearance.

object_tangible_terminal_shared_terminal_droid_foundry_nexus =
    object_tangible_terminal_shared_terminal_nym_cave:new {
        clientTemplateFileName = "object/tangible/terminal/shared_terminal_droid_foundry_nexus.iff",
    }

ObjectTemplates:addClientTemplate(
    object_tangible_terminal_shared_terminal_droid_foundry_nexus,
    "object/tangible/terminal/shared_terminal_droid_foundry_nexus.iff"
)

object_tangible_terminal_terminal_droid_foundry_nexus =
    object_tangible_terminal_shared_terminal_droid_foundry_nexus:new {
    }

ObjectTemplates:addTemplate(
    object_tangible_terminal_terminal_droid_foundry_nexus,
    "object/tangible/terminal/terminal_droid_foundry_nexus.iff"
)
