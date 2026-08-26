#ifndef FACTORYQUEUERETRYTASK_H_
#define FACTORYQUEUERETRYTASK_H_

#include "server/zone/objects/installation/factory/FactoryObject.h"

class FactoryQueueRetryTask : public Task {
	ManagedReference<FactoryObject*> factory;

public:
	FactoryQueueRetryTask(FactoryObject* factoryObject) : Task() {
		factory = factoryObject;
	}

	void run() {
		Locker lock(factory);
		if (factory != nullptr)
			factory->evaluateManufacturingQueue();
		if (factory != nullptr && factory->isManufacturingQueueEnabled() && !factory->isActive() && factory->getContainerObjectsSize() > 0) {
			Reference<FactoryQueueRetryTask*> retryTask = new FactoryQueueRetryTask(factory);
			factory->addPendingTask("factoryQueueRetry", retryTask, 60000);
		}
	}
};

#endif
