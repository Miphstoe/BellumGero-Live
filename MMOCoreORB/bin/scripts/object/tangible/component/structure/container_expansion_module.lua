-- Subspace Container Expansion Module
-- Structure component used to expand furniture container capacity

object_tangible_component_structure_container_expansion_module = object_tangible_component_structure_shared_container_expansion_module:new {
    -- You can leave experiments very simple; we don't really care about stats
    numberExperimentalProperties = {1},
    experimentalProperties       = {"XX"},
    experimentalWeights          = {1},
    experimentalGroupTitles      = {"null"},
    experimentalSubGroupTitles   = {"hitpoints"},
    experimentalMin              = {1000},
    experimentalMax              = {1000},
    experimentalPrecision        = {0},
    experimentalCombineType      = {0},
}

ObjectTemplates:addTemplate(object_tangible_component_structure_container_expansion_module, "object/tangible/component/structure/container_expansion_module.iff")
