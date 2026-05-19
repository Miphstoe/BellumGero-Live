/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef FIRELIGHTNINGCONE1COMMAND_H_
#define FIRELIGHTNINGCONE1COMMAND_H_

#include "CombatQueueCommand.h"
#include "templates/SharedObjectTemplate.h"

class FireLightningCone1Command : public CombatQueueCommand {
public:

	FireLightningCone1Command(const String& name, ZoneProcessServer* server)
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

        // Stock LLC, heavy LLC, Bellum custom LLC (same CRC family as rifle_lightning.iff only for stock)
        bool isLightningWeapon =
            weapon->isLightningRifle() ||
            tplPath == "object/weapon/ranged/rifle/rifle_lightning_heavy.iff" ||
            tplPath == "object/weapon/ranged/rifle/rifle_foundling_light_lightning_cannon.iff" ||
            tplPath == "object/weapon/ranged/rifle/rifle_mando_way_lightning.iff";

        if (!isLightningWeapon)
            return INVALIDWEAPON;

		return doCombatAction(creature, target);
	}

};

#endif //FIRELIGHTNINGCONE1COMMAND_H_
