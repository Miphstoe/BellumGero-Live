#ifndef DOCTORBUFFDROIDZONECOMPONENT_H_
#define DOCTORBUFFDROIDZONECOMPONENT_H_

#include "server/zone/objects/scene/components/GroundZoneComponent.h"
#include "server/zone/objects/tangible/components/DoctorBuffDroidDataComponent.h"
#include "server/zone/packets/object/SpatialChat.h"
#include "server/zone/TreeEntry.h"
#include "system/lang/Time.h"

class DoctorBuffDroidZoneComponent : public GroundZoneComponent {
public:
	void notifyPositionUpdate(SceneObject* sceneObject, TreeEntry* entry) const override {
		ManagedReference<SceneObject*> target = cast<SceneObject*>(entry);
		if (target == nullptr || !target->isPlayerCreature())
			return;

		DataObjectComponentReference* dataRef = sceneObject->getDataObjectComponent();
		if (dataRef == nullptr || dataRef->get() == nullptr || !dataRef->get()->isDoctorBuffDroidData())
			return;

		DoctorBuffDroidDataComponent* data = cast<DoctorBuffDroidDataComponent*>(dataRef->get());
		if (data == nullptr || !data->isAdBarkEnabled())
			return;

		String adText = data->getAdBarkText();
		if (adText.isEmpty())
			return;

		float distanceSq = target->getWorldPosition().squaredDistanceTo2d(sceneObject->getWorldPosition());
		static const float kBarkRangeSq = DoctorBuffDroidDataComponent::BARK_RANGE * DoctorBuffDroidDataComponent::BARK_RANGE;

		if (distanceSq >= kBarkRangeSq)
			return;

		Time now;
		uint64 nowMs = now.getMiliTime();

		if (!data->canBarkAtPlayer(target->getObjectID(), nowMs))
			return;

		data->recordBark(target->getObjectID(), nowMs);

		ManagedReference<SceneObject*> droidRef = sceneObject;
		ManagedReference<SceneObject*> playerRef = target;
		String text = adText;

		Core::getTaskManager()->executeTask([droidRef, playerRef, text]() {
			if (droidRef == nullptr || playerRef == nullptr)
				return;

			Locker locker(droidRef);

			SpatialChat* chatMessage = new SpatialChat(
				droidRef->getObjectID(),
				playerRef->getObjectID(),
				playerRef->getObjectID(),
				UnicodeString(text),
				50, 0, 0, 0, 0
			);

			droidRef->broadcastMessage(chatMessage, true);
		}, "DoctorBuffDroidBarkLambda");
	}
};

#endif /* DOCTORBUFFDROIDZONECOMPONENT_H_ */
