/*
 * VendorPackupCommand.h
 *
 * Bellum Gero "/vendorPackup" -- Vendor Packup System command.
 *
 * Player facing (no characterAbility): execution permission is separate from ownership.
 * Every operation is authorized by VendorPackupManager against the TARGET VENDOR on the server.
 *
 *   /vendorPackup                      (target one of your vendors) pack it up (confirmation dialog)
 *   /vendorPackup pack                 same
 *   /vendorPackup redeploy             (target your packed vendor, placed in a structure) redeploy it
 *
 * Administrative subcommands -- these alone require the "admin" ability, checked below:
 *   /vendorPackup status [vendorOID]   show pack state, owner, location, listing count
 *   /vendorPackup recover [vendorOID]  resolve an interrupted pack/restore (never creates objects)
 *
 * The client command_table row must have an EMPTY characterAbility and targetType optional.
 */

#ifndef VENDORPACKUPCOMMAND_H_
#define VENDORPACKUPCOMMAND_H_

#include "server/zone/objects/creature/commands/QueueCommand.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/TangibleObject.h"
#include "server/zone/managers/vendor/VendorPackupManager.h"

class VendorPackupCommand : public QueueCommand {
public:
	VendorPackupCommand(const String& name, ZoneProcessServer* server) : QueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (creature == nullptr)
			return GENERALERROR;

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return GENERALERROR;

		StringTokenizer tokenizer(arguments.toString());
		tokenizer.setDelimeter(" ");

		String sub = "pack";

		if (tokenizer.hasMoreTokens()) {
			tokenizer.getStringToken(sub);
			sub = sub.toLowerCase();
		}

		VendorPackupManager* manager = VendorPackupManager::instance();

		// ---- administrative subcommands (explicit admin check) ----
		if (sub == "status" || sub == "recover") {
			if (!ghost->hasAbility("admin")) {
				creature->sendSystemMessage("You are not authorized to use that option.");
				return INSUFFICIENTPERMISSION;
			}

			uint64 vendorID = target;

			if (tokenizer.hasMoreTokens())
				vendorID = tokenizer.getLongToken();

			if (vendorID == 0) {
				creature->sendSystemMessage("Usage: /vendorPackup status|recover <vendorOID> (or target the vendor)");
				return SUCCESS;
			}

			if (sub == "status") {
				creature->sendSystemMessage(manager->describeVendor(vendorID));
				return SUCCESS;
			}

			Logger::console.info(true) << "[VENDORPACK] admin " << creature->getFirstName() << " (" << creature->getObjectID()
				<< ") requested recovery of vendor " << vendorID;

			bool ok = manager->recoverVendor(vendorID, "admin");

			creature->sendSystemMessage(String(ok ? "Recovery complete. " : "Recovery could not complete (see log). ") + manager->describeVendor(vendorID));
			return SUCCESS;
		}

		// ---- player operations: the target is untrusted, the manager re-validates everything ----
		if (sub != "pack" && sub != "redeploy") {
			creature->sendSystemMessage("Usage: /vendorPackup [pack|redeploy] while targeting your vendor.");
			return SUCCESS;
		}

		ZoneServer* zoneServer = creature->getZoneServer();

		ManagedReference<SceneObject*> targetObject = (target != 0 && zoneServer != nullptr) ? zoneServer->getObject(target) : nullptr;

		if (targetObject == nullptr || !targetObject->isVendor() || !targetObject->isTangibleObject()) {
			creature->sendSystemMessage("Target one of your vendors first.");
			return SUCCESS;
		}

		TangibleObject* vendor = targetObject->asTangibleObject();

		if (vendor == nullptr)
			return GENERALERROR;

		if (sub == "redeploy")
			manager->redeploy(creature, vendor);
		else
			manager->promptPackUp(creature, vendor);

		return SUCCESS;
	}
};

#endif /* VENDORPACKUPCOMMAND_H_ */
