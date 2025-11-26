/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef MASTERBOUNTYGUILDSCREENHANDLER_H_
#define MASTERBOUNTYGUILDSCREENHANDLER_H_

#include "ScreenHandler.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "engine/log/Logger.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
namespace conversation {
namespace screenhandlers {

class MasterBountyGuildScreenHandler : public ScreenHandler, public Logger {
public:
	static const String STARTSCREENHANDLERID;

	MasterBountyGuildScreenHandler() :
			ScreenHandler(),
			Logger("MasterBountyGuildScreenHandler") {
	}

	virtual ~MasterBountyGuildScreenHandler() {
	}

	virtual ConversationScreen* handleScreen(
			CreatureObject* conversingPlayer,
			SceneObject* conversingNPC,
			int selectedOption,
			ConversationScreen* conversationScreen);

	bool toBinaryStream(ObjectOutputStream* stream) {
		return true;
	}

	bool parseFromBinaryStream(ObjectInputStream* stream) {
		return true;
	}
};

} } } } } }

using namespace server::zone::objects::creature::conversation::screenhandlers;

#endif /* MASTERBOUNTYGUILDSCREENHANDLER_H_ */
