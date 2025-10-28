/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.*/

#ifndef REAPERSTRIKECOMMAND_H_
#define REAPERSTRIKECOMMAND_H_

#include "CombatQueueCommand.h"

class ReaperStrikeCommand : public CombatQueueCommand {
public:
    ReaperStrikeCommand(const String& name, ZoneProcessServer* server)
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

#endif // REAPERSTRIKECOMMAND_H_