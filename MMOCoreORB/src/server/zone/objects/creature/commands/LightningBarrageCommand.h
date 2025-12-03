/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.*/

#ifndef LIGHTNINGBARRAGECOMMAND_H_
#define LIGHTNINGBARRAGECOMMAND_H_

#include "CombatQueueCommand.h"

class LightningBarrageCommand : public CombatQueueCommand {
public:
    LightningBarrageCommand(const String& name, ZoneProcessServer* server)
        : CombatQueueCommand(name, server) {
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        // Require an equipped lightning cannon / lightning rifle
        ManagedReference<WeaponObject*> weapon = creature->getWeapon();

        if (weapon == nullptr || !weapon->isLightningRifle())
            return INVALIDWEAPON;

        return doCombatAction(creature, target);
    }
};

#endif // LIGHTNINGBARRAGECOMMAND_H_
