/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions.*/

#ifndef REAPERSHOTCOMMAND_H_
#define REAPERSHOTCOMMAND_H_

#include "CombatQueueCommand.h"

class ReaperShotCommand : public CombatQueueCommand {
public:
    ReaperShotCommand(const String& name, ZoneProcessServer* server)
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

#endif // REAPERSHOTCOMMAND_H_