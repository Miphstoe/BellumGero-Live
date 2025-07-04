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

    // MODIFIED: Check if actually in salon, if yes use original logic, if no do nothing
    if (scene->getParentRecursively(SceneObjectType::SALONBUILDING) != nullptr) {
        // Actually in salon - cancel timeout as normal
        strongRef->checkDequeueEvent(scene);
    }
    // If not in salon, do nothing (don't queue timeout, don't dequeue)
    
    return 0;
}