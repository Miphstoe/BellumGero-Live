--
-- Bellum Gero Training Dummy object templates
--
-- Save at:
-- MMOCoreORB/bin/scripts/object/mobile/training_dummy.lua
--
-- This file is intentionally self-contained. It registers both the dedicated
-- shared client template and the non-shared server object template.
--
-- The existing CLL-8 shared template is used only as a parent. It is not
-- modified or replaced.
--

object_mobile_shared_training_dummy =
	object_mobile_shared_cll8_binary_load_lifter:new {
		clientTemplateFileName = "object/mobile/shared_training_dummy.iff"
	}

ObjectTemplates:addClientTemplate(
	object_mobile_shared_training_dummy,
	"object/mobile/shared_training_dummy.iff"
)

object_mobile_training_dummy = object_mobile_shared_training_dummy:new {
	objectMenuComponent = "TrainingDummyMenuComponent"
}

ObjectTemplates:addTemplate(
	object_mobile_training_dummy,
	"object/mobile/training_dummy.iff"
)
