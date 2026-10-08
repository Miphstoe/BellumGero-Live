/*
 * ImageDesignRejectMessageCallback.h
 *
 *  Created on: 02/02/2011
 *      Author: Polonel
 */

#ifndef IMAGEDESIGNREJECTMESSAGECALLBACK_H_
#define IMAGEDESIGNREJECTMESSAGECALLBACK_H_

#include "ObjectControllerMessageCallback.h"
#include "server/zone/objects/player/sessions/ImageDesignSession.h"
#include "server/zone/objects/player/sessions/ImageDesignStationSession.h"
#include "server/zone/objects/player/sessions/VendorImageDesignSession.h"

class ImageDesignRejectMessageCallback : public MessageCallback {
	uint64 designer;
	uint64 target;
	uint64 tent;
	uint8 type;

	ImageDesignData data;

	ObjectControllerMessageCallback* objectControllerMain;

public:
	ImageDesignRejectMessageCallback(ObjectControllerMessageCallback* objectControllerCallback) :
			MessageCallback(objectControllerCallback->getClient(), objectControllerCallback->getServer()),
			designer(0), target(0), tent(0), type(0), objectControllerMain(objectControllerCallback) {
	}

	void parse(Message* message) {
		message->shiftOffset(4);//?
		designer = message->parseLong();
		target = message->parseLong();
		tent = message->parseLong();
		type = message->parseByte();

		data.parse(message);
	}

	void run() {
		ManagedReference<CreatureObject*> player = client->getPlayer();

		if (player == nullptr)
			return;

		ManagedReference<Facade*> facade =
			player->getActiveSession(SessionFacadeType::IMAGEDESIGN);

		ManagedReference<VendorImageDesignSession*> vendorSession =
			dynamic_cast<VendorImageDesignSession*>(facade.get());

		if (vendorSession != nullptr) {
			vendorSession->cancelVendorImageDesign(
				designer, target, tent, type, data);
			return;
		}

		ManagedReference<ImageDesignStationSession*> stationSession =
			dynamic_cast<ImageDesignStationSession*>(facade.get());

		if (stationSession != nullptr) {
			stationSession->cancelStationImageDesign(
				designer, target, tent, type, data);
			return;
		}

		ManagedReference<ImageDesignSession*> session =
			dynamic_cast<ImageDesignSession*>(facade.get());

		if (session == nullptr)
			return;

		session->cancelImageDesign(designer, target, tent, type, data);
	}
};


#endif /* IMAGEDESIGNREJECTMESSAGECALLBACK_H_ */
