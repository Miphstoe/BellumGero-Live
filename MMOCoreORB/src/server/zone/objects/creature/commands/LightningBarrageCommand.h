/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.*/

#ifndef LIGHTNINGBARRAGECOMMAND_H_
#define LIGHTNINGBARRAGECOMMAND_H_

#include "CombatQueueCommand.h"
#include "templates/SharedObjectTemplate.h"

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

#endif // LIGHTNINGBARRAGECOMMAND_H_
