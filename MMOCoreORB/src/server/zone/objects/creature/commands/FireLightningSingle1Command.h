/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef FIRELIGHTNINGSINGLE1COMMAND_H_
#define FIRELIGHTNINGSINGLE1COMMAND_H_

#include "CombatQueueCommand.h"
#include "templates/SharedObjectTemplate.h"

class FireLightningSingle1Command : public CombatQueueCommand {
public:

	FireLightningSingle1Command(const String& name, ZoneProcessServer* server)
		: CombatQueueCommand(name, server) {
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ManagedReference<WeaponObject*> weapon = creature->getWeapon();

        if (weapon == nullptr)
            return INVALIDWEAPON;

        // Get the weapon template path (e.g. "object/weapon/ranged/rifle/rifle_lightning_heavy.iff")
        SharedObjectTemplate* tmpl = weapon->getObjectTemplate();
        String tplPath = tmpl ? tmpl->getFullTemplateString() : String();

        // Accept original lightning rifles OR the heavy lightning rifle template
        bool isLightningWeapon =
            weapon->isLightningRifle() ||
            tplPath == "object/weapon/ranged/rifle/rifle_lightning_heavy.iff";

        if (!isLightningWeapon)
            return INVALIDWEAPON;

		return doCombatAction(creature, target);
	}

};

#endif //FIRELIGHTNINGSINGLE1COMMAND_H_
