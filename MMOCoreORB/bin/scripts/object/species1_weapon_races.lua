-- Player template paths extracted from bg_species1.tre (shared_ client IFF names).
-- Only player weapons with an existing nonempty race list gain these races.
local species1PlayerRaces = {
	"object/creature/player/abyssin_male.iff",
	"object/creature/player/aqualish_female.iff",
	"object/creature/player/aqualish_male.iff",
	"object/creature/player/arcona_male.iff",
	"object/creature/player/bith_female.iff",
	"object/creature/player/bith_male.iff",
	"object/creature/player/cerean_male.iff",
	"object/creature/player/chadra_fan_female.iff",
	"object/creature/player/chadra_fan_male.iff",
	"object/creature/player/chiss_female.iff",
	"object/creature/player/chiss_male.iff",
	"object/creature/player/devaronian_female.iff",
	"object/creature/player/devaronian_male.iff",
	"object/creature/player/droid_male.iff",
	"object/creature/player/dug_male.iff",
	"object/creature/player/duros_male.iff",
	"object/creature/player/ewok_female.iff",
	"object/creature/player/ewok_male.iff",
	"object/creature/player/feeorin_male.iff",
	"object/creature/player/geonosian_male.iff",
	"object/creature/player/gotal_male.iff",
	"object/creature/player/gran_male.iff",
	"object/creature/player/gungan_male.iff",
	"object/creature/player/hutt_female.iff",
	"object/creature/player/hutt_male.iff",
	"object/creature/player/iktotchi_male.iff",
	"object/creature/player/ishi_tib_male.iff",
	"object/creature/player/jenet_male.iff",
	"object/creature/player/kel_dor_male.iff",
	"object/creature/player/kubaz_male.iff",
	"object/creature/player/mirialan_female.iff",
	"object/creature/player/mirialan_male.iff",
	"object/creature/player/nautolan_male.iff",
	"object/creature/player/nightsister_female.iff",
	"object/creature/player/nikto_male.iff",
	"object/creature/player/ortolan_male.iff",
	"object/creature/player/quarren_male.iff",
	"object/creature/player/sanyassan_female.iff",
	"object/creature/player/sanyassan_male.iff",
	"object/creature/player/smc_female.iff",
	"object/creature/player/talz_male.iff",
	"object/creature/player/togorian_male.iff",
	"object/creature/player/togruta_female.iff",
	"object/creature/player/toydarian_male.iff",
	"object/creature/player/weequay_male.iff",
	"object/creature/player/zeltron_female.iff",
	"object/creature/player/zeltron_male.iff",
}

function addSpecies1WeaponRaces(template)
	local races = template.playerRaces

	if type(races) ~= "table" or #races == 0 then
		return
	end

	-- Inherited lists can be shared with parent templates; copy before extending.
	if rawget(template, "playerRaces") == nil then
		local copy = {}
		for i, race in ipairs(races) do
			copy[i] = race
		end
		races = copy
		template.playerRaces = races
	end

	local present = {}
	for _, race in ipairs(races) do
		present[race] = true
	end

	for _, race in ipairs(species1PlayerRaces) do
		if not present[race] then
			races[#races + 1] = race
		end
	end
end
