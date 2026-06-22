print("[JEDI-SEA-VENDOR] loading screenplay scripts/screenplays/vendors/jedi_furniture_sea_vendor.lua")

JediFurnitureSeaVendor = ScreenPlay:new {
	numberOfActs = 1
}

registerScreenPlay("JediFurnitureSeaVendor", true)

local JEDI_SEA_VENDOR_CFG = {
	planet = "corellia",
	x = -177,
	y = 28,
	z = -4703,
	heading = 0,
	cell = 0,
	template = "jedi_furniture_sea_vendor",
	customName = "Jedi Furniture SEA Vendor"
}

function JediFurnitureSeaVendor:start()
	self:spawnVendor()
end

function JediFurnitureSeaVendor:spawnVendor()
	local pNpc = spawnMobile(
		JEDI_SEA_VENDOR_CFG.planet,
		JEDI_SEA_VENDOR_CFG.template,
		0,
		JEDI_SEA_VENDOR_CFG.x,
		JEDI_SEA_VENDOR_CFG.y,
		JEDI_SEA_VENDOR_CFG.z,
		JEDI_SEA_VENDOR_CFG.heading,
		JEDI_SEA_VENDOR_CFG.cell
	)

	if pNpc == nil then
		print("[JEDI-SEA-VENDOR][ERROR] spawnMobile returned nil")
		return
	end

	local ai = AiAgent(pNpc)
	if ai then
		ai:setConvoTemplate("jedi_furniture_sea_vendor_conv")
	end

	local creature = CreatureObject(pNpc)
	if creature then
		creature:setCustomObjectName(JEDI_SEA_VENDOR_CFG.customName)
	end

	print(string.format("[JEDI-SEA-VENDOR] Spawned vendor at %s (%.1f, %.1f, %.1f)", JEDI_SEA_VENDOR_CFG.planet, JEDI_SEA_VENDOR_CFG.x, JEDI_SEA_VENDOR_CFG.y, JEDI_SEA_VENDOR_CFG.z))
end
