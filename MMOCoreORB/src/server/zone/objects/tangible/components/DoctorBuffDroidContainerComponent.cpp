#include "DoctorBuffDroidContainerComponent.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/scene/components/DataObjectComponentReference.h"
#include "DoctorBuffDroidDataComponent.h"

bool DoctorBuffDroidContainerComponent::checkContainerPermission(SceneObject* sceneObject, CreatureObject* creature, uint16 permission) const {
	if (sceneObject == nullptr || creature == nullptr)
		return false;

	DataObjectComponentReference* data = sceneObject->getDataObjectComponent();
	if (data == nullptr || data->get() == nullptr || !data->get()->isDoctorBuffDroidData())
		return false;

	DoctorBuffDroidDataComponent* droidData = cast<DoctorBuffDroidDataComponent*>(data->get());
	if (droidData == nullptr)
		return false;

	if (!droidData->isOwner(creature)) {
		creature->sendSystemMessage("Only the owning Master Doctor can access the Doctor Buff Droid's supplies directly.");
		return false;
	}

	return true;
}
