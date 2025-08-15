/*
                Copyright <SWGEmu>
        See file COPYING for copying conditions. */

#ifndef FORCERUN3COMMAND_H_
#define FORCERUN3COMMAND_H_

#include "JediQueueCommand.h"

class ForceRun3Command : public JediQueueCommand {
public:
    ForceRun3Command(const String& name, ZoneProcessServer* server)
        : JediQueueCommand(name, server) {
        // BuffCRC's, first one is used.
        buffCRC = BuffCRC::JEDI_FORCE_RUN_3;

        // If these are active they will block buff use
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_1);
        blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_2);

        // Skill mods.
        skillMods.put("force_run", 3);
        skillMods.put("slope_move", 100);
    }

    int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const override;
};

#endif // FORCERUN3COMMAND_H_
