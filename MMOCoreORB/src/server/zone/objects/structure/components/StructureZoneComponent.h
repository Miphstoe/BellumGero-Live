/*
 * StructureZoneComponent.h
 *
 *  Created on: Apr 15, 2012
 *      Author: TragD
 */

#ifndef STRUCTUREZONECOMPONENT_H_
#define STRUCTUREZONECOMPONENT_H_

#include "engine/engine.h"
#include "server/zone/objects/scene/components/GroundZoneComponent.h"

namespace server {
 namespace zone {
  namespace objects {
   namespace scene { class SceneObject; }
   namespace structure { class StructureObject; }
  }
  class Zone;
 }
}

using namespace server::zone::objects::scene;
using namespace server::zone::objects::structure;
using namespace server::zone;

class StructureZoneComponent : public GroundZoneComponent {
public:
    void notifyInsertToZone(SceneObject* sceneObject, Zone* zone) const override;
    void notifyRemoveFromZone(SceneObject* sceneObject) const override;

    // IMPORTANT: do NOT use 'override' here unless your base declares the same signature.
    // Start with non-const, returning int:
    virtual int notifyEnter(SceneObject* sceneObject, SceneObject* mover);
    virtual int notifyExit(SceneObject* sceneObject, SceneObject* mover);
};



#endif /* STRUCTUREZONECOMPONENT_H_ */
