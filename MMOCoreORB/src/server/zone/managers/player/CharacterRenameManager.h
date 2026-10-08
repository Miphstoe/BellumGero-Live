/*
 * CharacterRenameManager.h
 *
 * Bellum Gero - paid Character Name Change Service (Bellum Gero Hub).
 *
 * Renames the existing character object in place (same object ID) using the
 * same sync steps as Core3's /setFirstName + /setLastName, but validates and
 * applies first + last name together, serializes all renames behind one mutex,
 * and charges the bank fee under the same creature lock as the rename.
 *
 * Name and bank balance both live on the CreatureObject, so they are saved to
 * the object database together. The MySQL characters table and the in-memory
 * name index are secondary; reconcileNameIndex() repairs them on login if a
 * crash ever leaves them out of step with the object database.
 */

#ifndef CHARACTERRENAMEMANAGER_H_
#define CHARACTERRENAMEMANAGER_H_

#include "engine/engine.h"

namespace server {
namespace zone {
namespace objects {
namespace creature {
	class CreatureObject;
}
}
}
}

using namespace server::zone::objects::creature;

class CharacterRenameManager : public Singleton<CharacterRenameManager>, public Logger, public Object {
public:
	static const int SERVICE_FEE = 1000000;

	enum : int {
		RESULT_SUCCESS = 0,
		RESULT_INVALID = 1,
		RESULT_UNAVAILABLE = 2,
		RESULT_INSUFFICIENT_FUNDS = 3,
		RESULT_UNSAFE_STATE = 4,
		RESULT_FAILED = 5,
		RESULT_SAME_NAME = 6
	};

	struct RenameResult {
		int code = RESULT_FAILED;
		String message;
		String fullName;
	};

	CharacterRenameManager();

	// Read-only check used by the SUI steps. Never reserves names or charges credits.
	RenameResult checkRename(CreatureObject* player, const String& rawFirstName, const String& rawLastName);

	// Revalidates everything, renames, then charges SERVICE_FEE from the bank.
	RenameResult purchaseRename(CreatureObject* player, const String& rawFirstName, const String& rawLastName);

	// Called at character login: makes the name index + MySQL match the object database.
	void reconcileNameIndex(CreatureObject* player);

private:
	Mutex renameMutex;

	RenameResult validate(CreatureObject* player, const String& rawFirstName, const String& rawLastName, String& firstName, String& lastName, bool checkDatabase);
	String checkEligibility(CreatureObject* player);
	bool normalizeComponent(const String& raw, String& out);
	bool isFirstNameTakenInDatabase(const String& firstName, uint64 playerID, int galaxyID);
	void updateCharacterTables(uint64 playerID, int galaxyID, const String& firstName, const String& lastName);
	void audit(CreatureObject* player, const String& status, const String& oldName, const String& newName, int fee, const String& reason);
};

#endif /* CHARACTERRENAMEMANAGER_H_ */
