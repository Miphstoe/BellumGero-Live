/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.
*/
#include "server/zone/objects/player/sessions/ImageDesignPositionObserver.h"
#include "templates/params/ObserverEventType.h"
#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/player/sessions/ImageDesignSession.h"

int ImageDesignPositionObserverImplementation::notifyObserverEvent(uint32 eventType, Observable* observable, ManagedObject* arg1, int64 arg2) {
    ManagedReference<ImageDesignSession*> strongRef = session.get();
    if (strongRef == nullptr)
        return 1;
    if (eventType != ObserverEventType::POSITIONCHANGED)
        return 0;
    SceneObject* scene = dynamic_cast<SceneObject*>(observable);
    if (scene == nullptr)
        return 1;

    // MODIFIED: Always cancel timeout instead of checking building location
    // This allows image design and stat migration to work anywhere
    strongRef->checkDequeueEvent(scene);

    // Original code that enforced salon requirement:
    // if (scene->getParentRecursively(SceneObjectType::SALONBUILDING) == nullptr) {
    //     //queue the timeout
    //     strongRef->queueIdTimeoutEvent();
    // } else {
    //     //cancel the timeout
    //     strongRef->checkDequeueEvent(scene);
    // }

    return 0;
}