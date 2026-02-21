# Core3 server reboot command
_Exported on 2/14/2026 at 11:22:36 PST from Cursor (2.4.37)_

---

**User**

what is the command to reboot the core3 server

---

**Cursor**

Searching the codebase for references to "core3" and reboot commands.


Searching for reboot commands or scripts:


Checking for reboot scripts or commands:


There isn't a single "reboot" command for the core3 server. Reboot by shutting down, then restarting:

## To reboot the core3 server:

**1. Shutdown the server** (from the server console):
```
shutdown 0 fast
```
This performs a fast shutdown (saves data but disconnects players quickly).

Or for a normal shutdown with warnings:
```
shutdown 1
```
This gives players 1 minute warning before shutdown.

**2. After shutdown completes, restart the server:**
```bash
cd ~/localswgserver/MMOCoreORB/bin
./core3
```

Or if you want to run it with GDB:
```bash
cd ~/localswgserver/MMOCoreORB/bin
gdb ./core3
```
Then type `r` in GDB to start it.

---

**Note:** If the server is running in the background and you can't access the console, you can:
1. Find the process: `ps aux | grep core3`
2. Send a graceful shutdown: `kill -SIGTERM <PID>`
3. Wait for it to stop, then restart with `./core3`

The `shutdown` command is the recommended way to stop the server cleanly before restarting it.

---

**User**

Enderwookie@EnderWookie:~/localswgserver/MMOCoreORB/bin$ ps aux | grep core3
Enderwo+  511453  0.0  0.0   6524  2048 pts/0    S+   20:34   0:00 grep core3
Enderwookie@EnderWookie:~/localswgserver/MMOCoreORB/bin$

---

**Cursor**

The core3 server isn't running (only the `grep` process appears). To start it, run:


You're already in the correct directory. Start the core3 server with:

**To start with GDB (for debugging):**
```bash
gdb ./core3
```
Then type `r` at the GDB prompt to run it.

**Or to start without GDB:**
```bash
./core3
```

The server will start loading. Wait for messages about loading templates, connecting to the database, etc., before it's ready.

---

**For future reference - to reboot when it's running:**
1. In the server console, type: `shutdown 0 fast`
2. Wait for shutdown to complete
3. Then restart with `./core3` (or `gdb ./core3`)

Since it's not running now, just start it with `./core3`.

---

**User**

What are the commands for a game admin in god mode to buff a player

---

**Cursor**

Searching the codebase for admin/god mode buff commands.


Searching for buff-related commands:


Checking for other buff-related admin commands:


Commands for admins in god mode to buff players:

## Main Buff Command: `/gmrevive buff`

**Basic Usage:**
- `/gmrevive buff` — Buff yourself (if no target) or your target
- `/gmrevive buff <player name>` — Buff a specific player by name
- `/gmrevive buff area` — Buff all players in a 32-unit radius
- `/gmrevive buff area <range>` — Buff all players within a specified range (5-50 units)
- `/gmrevive buff area <range> <faction>` — Buff players of a specific faction (imperial, rebel, or neutral)

**What it does:**
Applies full enhancement buffs:
- Medical buffs: Health, Strength, Constitution, Action, Quickness, Stamina
- Performance buffs: Mind, Focus, Willpower

**Examples:**
```
/gmrevive buff                    (buffs yourself or your target)
/gmrevive buff PlayerName         (buffs a player named "PlayerName")
/gmrevive buff area               (buffs all nearby players)
/gmrevive buff area 20            (buffs players within 20 units)
/gmrevive buff area 30 imperial   (buffs imperial players within 30 units)
```

**Other `/gmrevive` options:**
- `/gmrevive` — Revive/heal yourself or your target (no buffs)
- `/gmrevive <player name>` — Revive a specific player
- `/gmrevive modifiers` — Clear all buffs and reset HAM to base values (requires a player target)

**Requirements:**
- Admin level > 0
- God mode enabled (`/setGodMode self on`)
- The `admin` ability

The `/gmrevive buff` command is the primary way to grant full enhancement buffs to players as an admin.

