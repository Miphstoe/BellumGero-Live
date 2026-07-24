-- Bellum: holographic bounty hunter guild contact (Mando daily story convo).
-- Client asset: object/mobile/shared_mando_holo_bh.iff in bg_custom1.tre
-- (boba_fett appearance chain re-shaded with the holo membrane shader).
object_mobile_mando_holo_bh = object_mobile_shared_mando_holo_bh:new {
	templateType = NPCCREATURE,

	armor = 3,

	kinetic = 100,
	energy = 100,
	electricity = 100,
	stun = 100,
	blast = 100,
	heat = 100,
	cold = 100,
	acid = 100,

	baseHAM = { 300000, 300, 300, 300000, 300, 300, 300000, 300, 300 },

	level = 300,

	stalker = 0,
	killer = 0,

	tame = 0,

	meatType = "",
	boneType = "",
	hideType = "",

	milk = 0,
	hideMax = 0,
	boneMax = 0,
	meatMax = 0,

	ferocity = 0
}

ObjectTemplates:addTemplate(object_mobile_mando_holo_bh, "object/mobile/mando_holo_bh.iff")
