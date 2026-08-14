-- Bellum Gero World Builder built-in static Ship Scenery templates.
-- Their client IFFs are generated deterministically into bg_worldbuilder.tre.

local shipSceneryTemplates = {
	{ "object_static_worldbuilder_ship_republic", "arc170" },
	{ "object_static_worldbuilder_ship_rebel", "awing" },
	{ "object_static_worldbuilder_ship_rebel", "bwing" },
	{ "object_static_worldbuilder_ship_separatist", "droid_fighter" },
	{ "object_static_worldbuilder_ship_separatist", "grievous_starship" },
	{ "object_static_worldbuilder_ship_republic", "jedifighter" },
	{ "object_static_worldbuilder_ship_civilian", "kse_firespray" },
	{ "object_static_worldbuilder_ship_imperial", "lambda_shuttle" },
	{ "object_static_worldbuilder_ship_republic", "naboo_starfighter" },
	{ "object_static_worldbuilder_ship_civilian", "soorosuub_space_yacht" },
	{ "object_static_worldbuilder_ship_imperial", "tie_advanced" },
	{ "object_static_worldbuilder_ship_imperial", "tie_aggressor" },
	{ "object_static_worldbuilder_ship_imperial", "tie_bomber" },
	{ "object_static_worldbuilder_ship_imperial", "tie_fighter" },
	{ "object_static_worldbuilder_ship_imperial", "tie_interceptor" },
	{ "object_static_worldbuilder_ship_imperial", "tie_oppressor" },
	{ "object_static_worldbuilder_ship_republic", "v_wing" },
	{ "object_static_worldbuilder_ship_rebel", "xwing" },
	{ "object_static_worldbuilder_ship_rebel", "ywing" },
	{ "object_static_worldbuilder_ship_civilian", "ykl37r" },
	{ "object_static_worldbuilder_ship_civilian", "yt1300" },
	{ "object_static_worldbuilder_ship_civilian", "yt2400" },
	{ "object_static_worldbuilder_ship_rebel", "z95" },
}

for _, entry in ipairs(shipSceneryTemplates) do
	local prefix = entry[1]
	local name = entry[2]
	local directory = string.gsub(prefix, "_", "/")
	local sharedPath = directory .. "/shared_" .. name .. ".iff"
	local serverPath = directory .. "/" .. name .. ".iff"
	local sharedName = prefix .. "_shared_" .. name
	local serverName = prefix .. "_" .. name

	local sharedTemplate = SharedStaticObjectTemplate:new {
		clientTemplateFileName = sharedPath
	}
	_G[sharedName] = sharedTemplate
	ObjectTemplates:addClientTemplate(sharedTemplate, sharedPath)

	local serverTemplate = sharedTemplate:new {
	}
	_G[serverName] = serverTemplate
	ObjectTemplates:addTemplate(serverTemplate, serverPath)
end
