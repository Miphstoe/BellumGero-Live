-- Bellum Gero World Builder structural publisher loader.
--
-- Keep this include stable. The external World Builder publisher writes the
-- finalized project-specific registrations to generated_templates.lua.
-- Stock/source building templates are loaded before this folder from
-- building/serverobjects.lua, so generated templates can safely inherit them.

includeFile("building/worldbuilder/generated_templates.lua")
