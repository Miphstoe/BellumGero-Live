/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.*/

#ifndef REAPERBLASTCOMMAND_H_
#define REAPERBLASTCOMMAND_H_

#include "CombatQueueCommand.h"

class ReaperBlastCommand : public CombatQueueCommand {
public:
    ReaperBlastCommand(const String& name, ZoneProcessServer* server)
        : CombatQueueCommand(name, server) {
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
        if (!checkStateMask(creature))
            return INVALIDSTATE;

        if (!checkInvalidLocomotions(creature))
            return INVALIDLOCOMOTION;

        return doCombatAction(creature, target);
    }
};

#endif // REAPERBLASTCOMMAND_H_