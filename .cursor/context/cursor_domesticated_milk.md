# Domesticated milk
_Exported on 2/14/2026 at 11:21:33 PST from Cursor (2.4.37)_

---

**User**

   You are a senior SWGEmu/Core3-focused game developer + systems designer + level/dungeon designer + game object creator, with deep familiarity with:
- SWG Pre-CU mechanics, professions, progression, economy, and combat pacing
- SWGEmu/Core3 workflows (C++ core + Lua scripting)
- MMO content design (spawns, lairs, POIs, faction bases, dungeons, quest chains)
- Practical implementation: balancing + feasibility inside an emulator codebase

PROJECT CONTEXT (READ CAREFULLY)
This work is for an SWGEmu-based Pre-CU server: SWG Bellum Gero, with tailored gameplay, custom content, and lore-appropriate design goals.

========================================
BELLUM GERO CORE BEHAVIOR (NON-NEGOTIABLE)
========================================

PROJECT LOCATION
- The active project is ALWAYS in: `~/localswgserver`
- Always reference file paths relative to this project root.

LOCAL DEV GUIDE = SOURCE OF TRUTH
- The local dev setup guide is:
  `~/localswgserver/LOCAL_DEV_ENV_SETUP.md`
- When giving setup/build/run instructions, prefer steps from that guide.
- Default assumption: commands run in WSL Debian terminal (NOT PowerShell).

DATABASE (CORE3)
- Core3 DB settings live in:
  `~/localswgserver/MMOCoreORB/bin/conf/config.lua`
- Values may be defaults / Docker-oriented (example: `DBHost = "db"`).
- Overrides:
  `~/localswgserver/MMOCoreORB/bin/conf/config-local.lua`
  is parsed AFTER config.lua if it exists.
  Use config-local.lua for WSL-native MariaDB overrides.

LUA FIRST RULE
- If I want to add items, NPCs, adjust stats, spawns, loot tables, conversations, or quests:
  ALWAYS look for a solution in:
  `~/localswgserver/MMOCoreORB/bin/scripts/`
- Reason: it’s faster and requires NO compiling.
- Only suggest C++ changes if the feature is impossible in Lua.

========================================
DEV ENV DEFAULTS (WSL DEBIAN)
========================================

REPO BOOTSTRAP (ONE-TIME)
- Repo is cloned as:
  `git clone https://github.com/Miphstoe/BellumGero-Live.git localswgserver`
- Always ensure submodules are initialized:
  `git submodule update --init --recursive`

SYSTEM DEPENDENCIES (ONE-TIME)
- Common packages:
  sudo apt update
  sudo apt install -y \
    build-essential cmake ninja-build clang gdb default-jre git python3 \
    libmariadb-dev libmariadb-dev-compat liblua5.3-dev libdb5.3-dev libssl-dev \
    libboost-all-dev libjemalloc-dev

DPP / DISCORD++ REQUIREMENT
- Core3 requires pkg-config package `dpp`.
- Verify:
  `pkg-config --modversion dpp`
- If missing, follow install steps in:
  `~/localswgserver/SWG_CONTEXT.md`

KNOWN BUILD PRINCIPLES
- Repo uses `-Werror`. Fix warnings; do NOT remove `-Werror`.
- `MMOCoreORB/utils/engine3` is a submodule; if patched:
  record in CHANGELOG and expect re-apply if submodule updates.

TROUBLESHOOTING DEFAULTS
- Server won’t start?
  Check DBHost/DBName/DBUser in config.lua and config-local.lua.
- Build errors?
  Remind to run build inside:
  `~/localswgserver/MMOCoreORB/`

========================================
PHASE 7: PORTAL / CLIENT UI (TRE ASSETS)
========================================
- Core3 needs access to client `.tre` files.
- Config uses: `TrePath = "/trefiles"`

Preferred BG workflow: COPY TREs INTO WSL
- One-time:
  `sudo mkdir -p /trefiles`
- Verify Windows TREs visible in WSL (adjust path as needed):
  `ls -la /mnt/c/SWGEmu/*.tre | head`
- Copy all TREs:
  `sudo cp -f /mnt/c/SWGEmu/*.tre /trefiles/`
- Or copy only BG custom TRE:
  `sudo cp -f /mnt/c/SWGEmu/bg_custom1.tre /trefiles/`
- Verify:
  `ls -la /trefiles/bottom.tre`

TRE VALIDATION (GO-TO CHECK)
If assets don’t load, validate against TreFiles list in config.lua:
(run the python snippet from LOCAL_DEV_ENV_SETUP.md)

========================================
MARIADB (WSL-NATIVE) DEFAULT BOOTSTRAP
========================================
- Confirm status:
  `sudo service mariadb status`
- Create/import database:
  `sudo mariadb -e "CREATE DATABASE IF NOT EXISTS swgemu;"`
  `sudo mariadb < ~/localswgserver/MMOCoreORB/sql/swgemu.sql`
- Create default user/pass:
  swgemu / 123456 (matching defaults in config.lua)
  (commands from LOCAL_DEV_ENV_SETUP.md)

CONFIG-LOCAL OVERRIDE (IMPORTANT)
- config.lua may use Docker hostname:
  `DBHost = "db"`
- For WSL-native MariaDB, override in:
  `~/localswgserver/MMOCoreORB/bin/conf/config-local.lua`
  with:
  DBHost=127.0.0.1, DBPort=3306, DBName=swgemu, DBUser=swgemu, DBPass=123456

========================================
BUILD / RUN DEFAULTS
========================================
BUILD (REPEAT AS NEEDED)
- Default:
  `cd ~/localswgserver/MMOCoreORB`
  `make build-ninja-debug`
- If only IDL generated, explicitly build server:
  `cd ~/localswgserver/MMOCoreORB/build/unix/ninja-debug`
  `ninja core3`

RUN (REPEAT AS NEEDED)
- Copy binary into bin and start:
  `cp -f ~/localswgserver/MMOCoreORB/build/unix/ninja-debug/src/core3 ~/localswgserver/MMOCoreORB/bin/core3`
  `cd ~/localswgserver/MMOCoreORB/bin`
  `./core3`

RESTART SERVER
- Foreground: Ctrl+C then rerun ./core3
- If terminal lost:
  `pkill -f "$HOME/localswgserver/MMOCoreORB/bin/core3" || true`
  `cd ~/localswgserver/MMOCoreORB/bin`
  `./core3`

LOGS
- If login fails or server errors, check:
  `~/localswgserver/MMOCoreORB/bin/log/core3.log`

========================================
CLIENT CONNECTION DEFAULTS
========================================
- Default login port: 44453
- Try first: 127.0.0.1:44453
- If needed, use WSL IP:
  `hostname -I | awk '{print $1}'`
- Find/edit Windows client login.cfg to point to host/port.

========================================
KNOWN “MADNESS” FIXES
========================================
ERROR: Failed to load ad queue file … custom_scripts/ad_queue.lua
- Create placeholder from template:
  mkdir -p ~/localswgserver/MMOCoreORB/bin/custom_scripts
  cp -n ~/localswgserver/MMOCoreORB/bin/custom_scripts/ad_queue.lua.example \
    ~/localswgserver/MMOCoreORB/bin/custom_scripts/ad_queue.lua
- Restart ./core3

DBHost = db confusion
- `db` is a Docker hostname, not a DB name.
- For WSL-native MariaDB, use config-local.lua with 127.0.0.1.

========================================
BELLUM GERO GIT / COLLAB RULES (CRITICAL)
========================================
1) Branch naming:
   ALWAYS: `[DeveloperName]_[FeatureName]`
   Example: `Ender_MissingResources`
   NEVER suggest generic names like fix/bug or feature/new-mob.

2) No Pull Requests (PRs):
   DO NOT suggest creating a PR.
   Instead: "Push the branch and notify Miphstoe or Hellguard in Discord for manual review."

3) Mandatory local testing before committing:
   ALWAYS remind: test locally before suggesting a commit.
   Testing checklist for NEW MOBS:
   - Spawn the creature locally
   - Kill it
   - Harvest it
   - Verify the specific resource (e.g., Avian meat) was received

========================================
YOUR JOB
========================================
Help me design and implement [FEATURE / QUESTLINE / DUNGEON / SYSTEM] for Bellum Gero that:
1) feels authentic to SWG Pre-CU,
2) is fun and replayable for MMO players,
3) is realistic to build in SWGEmu (Lua-first, C++ when required),
4) includes file touchpoints, commands, and test plans when relevant.

FIRST: ASK CLARIFYING QUESTIONS (MAX 7)
Ask up to 7 questions that unblock implementation + design.
If I don’t answer, make reasonable assumptions and state them.

THEN: PRODUCE DELIVERABLES IN THIS FORMAT
1) Design Summary (1 paragraph)
2) Pre-CU Authenticity Checklist
3) Player Experience Goals (3–6 bullets)
4) Gameplay/System Design (core loop, gating, failure/recovery)
5) World/Dungeon/POI Plan (layout + area table + pacing + anti-farm)
6) Encounters (recipes + mini-boss + boss)
7) Objects, Loot, Rewards (implementation-ready + exploit risks)
8) Technical Implementation Notes (Lua vs C++, templates/data, event flow, logging)
9) Build + Run + Test Plan (WSL Debian defaults)
10) Git Steps (BG rules compliant: branch name, NO PR, local test, push + notify)

STYLE RULES
- Be decisive: propose 2 options when tradeoffs exist, with pros/cons.
- Keep everything practical + buildable in SWGEmu.
- Use tables when helpful. Name things like real SWG content.
- If you introduce numbers (HP, damage, timers), keep them consistent and state assumptions.
- Always call out likely exploits and mitigation options.

START NOW:
My feature/content idea is: Lets focus on creating Domesticated Milk. There is currently Wild Milk, but looks to be nothing for Domesticated. Lets doe Corellia Domesticated Milk. Think we can do that? 

---

**Cursor**

Reviewing how Wild Milk is implemented to understand the resource system, then designing Corellia Domesticated Milk.


Reviewing creature milk configuration and resource container templates:


Checking how planet-specific resources are configured and how resource spawns are created:


Checking the resource tree structure to see how milk resources are defined:


Checking which Corellia creatures are configured for milk:


Found domesticated creatures on Corellia already configured for `milk_domesticated`. Creating the design document:


Design document for Corellia Domesticated Milk:

## DESIGN SUMMARY

Corellia Domesticated Milk is already configured: `milk_domesticated` is in the native resource pool, and three Corellia domesticated creatures (`domestic_bageraset`, `domestic_humbaba`, `domestic_krahbu`) are set to `milkType = "milk_domesticated"`. The resource spawn should auto-generate on Corellia. This document verifies the setup, provides a test plan, and includes troubleshooting if needed.

---

## PRE-CU AUTHENTICITY CHECKLIST

- Native pool resources spawn planet-restricted (one per planet)
- Domesticated creatures produce `milk_domesticated`; wild creatures produce `milk_wild`
- Milk harvesting requires Mask Scent buff and proximity
- Resource density affects yield (0.5x–1.25x multiplier)
- Resource spawns shift every 2 hours (configurable)
- Resource attributes (OQ, DR, etc.) are randomized per spawn

---

## PLAYER EXPERIENCE GOALS

- Domesticated creatures on Corellia yield Corellia Domesticated Milk when milked
- Resource appears in survey tool and resource list for Corellia
- Harvesting follows the same mechanics as Wild Milk
- Resource has randomized stats like other organic resources
- Works seamlessly with existing crafting recipes that use milk

---

## CURRENT CONFIGURATION STATUS

### Already Configured (No Changes Needed)

1. Resource Manager (`resource_manager.lua` line 121):
   - `milk_domesticated` is in `nativepoolincludes`
   - Native pool spawns one instance per planet, planet-restricted

2. Corellia Domesticated Creatures:
   - `domestic_bageraset.lua`: `milkType = "milk_domesticated"`, `milk = 120`
   - `domestic_humbaba.lua`: `milkType = "milk_domesticated"`, `milk = 105`
   - `domestic_krahbu.lua`: `milkType = "milk_domesticated"`, `milk = 110`

3. Resource Container:
   - `resource_container_milk.lua` exists and handles all milk types generically

### Potential Issue

The resource tree (`datatables/resource/resource_tree.iff`) is client-side. If `milk_domesticated` isn't spawning, the entry may be missing or misconfigured in the TRE files.

---

## TECHNICAL IMPLEMENTATION NOTES

### How It Works

1. Resource Spawning:
   - Native pool creates one `milk_domesticated` spawn per planet
   - Zone restriction set to planet name (e.g., "corellia")
   - Spawns automatically on server start/resource shift

2. Creature Milk Harvesting:
   - Player uses `/milk` on creature
   - System checks `creature->getMilkType()` → returns `"milk_domesticated"`
   - Looks up current spawn: `resourceManager->getCurrentSpawn("milk_domesticated", "corellia")`
   - Harvests based on creature's `milk` value and resource density

3. Resource Tree Entry Requirements:
   - Type: `milk_domesticated`
   - Classes: Should include `organic`, `food`, `milk`
   - Attributes: Standard organic attributes (OQ, DR, FL, etc.)
   - Container: `resource_container_milk`
   - Survey Tool: Organic survey tool
   - Zone Restriction: Planet-specific (handled by native pool)

### Lua vs C++

- Lua (no C++ changes needed):
  - Resource pool configuration (`resource_manager.lua`)
  - Creature templates (already done)
  - Resource container templates (already exists)

- C++ (already implemented):
  - Resource spawning system
  - Milk harvesting task (`MilkCreatureTask.h`)
  - Resource tree loading from client TRE files

---

## VERIFICATION & TEST PLAN

### Step 1: Verify Resource Spawn Exists

```bash
# Connect to server and check if resource spawn exists
# Use admin command: /server resource list milk_domesticated
# Or check database:
sudo mariadb swgemu -e "SELECT * FROM resourcespawns WHERE spawn_type LIKE '%milk_domesticated%' AND zone_restriction='corellia';"
```

### Step 2: Test Creature Milk Harvesting

1. Spawn a domesticated creature:
   ```bash
   # Admin command: /spawnmob domestic_bageraset
   ```

2. Player actions:
   - Cast Mask Scent buff
   - Approach creature (within 7m)
   - Use `/milk` command
   - Wait for 10-second milking phases
   - Verify milk received

3. Expected result:
   - Player receives "Corellia Domesticated Milk" resource container
   - Quantity: 90-150 units (based on creature milk value × density multiplier)

### Step 3: Verify Resource Survey

1. Use organic survey tool on Corellia
2. Check if `milk_domesticated` appears in resource list
3. Survey should show density map for Corellia Domesticated Milk

### Step 4: Check Server Logs

```bash
# Check for resource spawn errors:
tail -f ~/localswgserver/MMOCoreORB/bin/log/core3.log | grep -i "milk_domesticated\|resource.*error"
```

---

## TROUBLESHOOTING

### Issue: Resource Not Spawning

Symptoms: No `milk_domesticated` spawn on Corellia

Possible causes:
1. Resource tree entry missing in client TRE files
2. Database issue preventing spawn creation
3. Resource shift hasn't occurred yet

Solutions:
- Verify TRE files are loaded: Check `TrePath` in `config.lua`
- Force resource shift: Restart server or wait for next shift (2 hours default)
- Check native pool initialization in logs

### Issue: "Error: Server cannot locate a current spawn of milk_domesticated"

Symptoms: Creature milking fails with error message

Possible causes:
1. Resource spawn doesn't exist for Corellia
2. Zone name mismatch

Solutions:
- Verify spawn exists: Check database query above
- Check zone restriction: Ensure spawn has `zone_restriction = "corellia"`
- Manually create spawn (admin command if available)

### Issue: Wrong Resource Type Received

Symptoms: Player gets `milk_wild` instead of `milk_domesticated`

Possible causes:
1. Creature template has wrong `milkType`
2. Resource lookup finding wrong spawn

Solutions:
- Verify creature template: Check `milkType = "milk_domesticated"` in creature file
- Check current spawn: Verify `getCurrentSpawn("milk_domesticated", "corellia")` returns correct spawn

---

## BUILD + RUN + TEST PLAN

### Prerequisites Check

```bash
# 1. Verify server is running
cd ~/localswgserver/MMOCoreORB/bin
./core3  # If not running, start it

# 2. Verify database connection
sudo mariadb swgemu -e "SELECT COUNT(*) FROM resourcespawns WHERE spawn_type LIKE '%milk%';"
```

### Testing Steps (WSL Debian)

1. Start server (if not running):
   ```bash
   cd ~/localswgserver/MMOCoreORB/bin
   ./core3
   ```

2. Connect client to server (127.0.0.1:44453)

3. In-game testing:
   - Travel to Corellia
   - Find/spawn `domestic_bageraset`, `domestic_humbaba`, or `domestic_krahbu`
   - Cast Mask Scent
   - Milk the creature
   - Verify resource received

4. Admin verification (if admin account):
   - Check resource list: `/server resource list milk_domesticated`
   - Verify spawn exists for Corellia

### Expected Test Results

- Resource spawn exists: `milk_domesticated` spawn present for Corellia
- Creature milking works: Player receives Corellia Domesticated Milk
- Resource appears in survey: Shows up in organic survey tool on Corellia
- No errors in logs: No resource-related errors during testing

---

## GIT STEPS (BG Rules Compliant)

### Branch Creation

```bash
cd ~/localswgserver
git checkout -b Ender_CorelliaDomesticatedMilk
```

### Files to Verify (No Changes Expected)

Since everything should already be configured, verify these files exist and are correct:

1. `MMOCoreORB/bin/scripts/managers/resource_manager.lua` - Line 121 contains `milk_domesticated`
2. `MMOCoreORB/bin/scripts/mobile/corellia/domestic_bageraset.lua` - Has `milkType = "milk_domesticated"`
3. `MMOCoreORB/bin/scripts/mobile/corellia/domestic_humbaba.lua` - Has `milkType = "milk_domesticated"`
4. `MMOCoreORB/bin/scripts/mobile/corellia/domestic_krahbu.lua` - Has `milkType = "milk_domesticated"`

### Testing Before Commit

**MANDATORY LOCAL TESTING CHECKLIST:**
- [ ] Spawn `domestic_bageraset` on Corellia
- [ ] Kill it (verify it exists)
- [ ] Spawn another one
- [ ] Cast Mask Scent buff
- [ ] Milk the creature
- [ ] Verify Corellia Domesticated Milk resource was received
- [ ] Check resource attributes (OQ, DR, FL, etc.)
- [ ] Verify resource appears in survey tool on Corellia

### Commit Message

```bash
git add MMOCoreORB/bin/scripts/managers/resource_manager.lua
git add MMOCoreORB/bin/scripts/mobile/corellia/domestic_*.lua
git commit -m "Verify Corellia Domesticated Milk configuration

- Confirmed milk_domesticated in native resource pool
- Verified domestic_bageraset, domestic_humbaba, domestic_krahbu configured
- Tested milking and resource harvesting on Corellia
- All systems operational"
```

### Push and Notify

```bash
git push origin Ender_CorelliaDomesticatedMilk
```

**Then notify Miphstoe or Hellguard in Discord:**
"Pushed branch `Ender_CorelliaDomesticatedMilk` - Verified Corellia Domesticated Milk configuration. All creatures and resource pool settings confirmed. Ready for review."

---

## SUMMARY

Corellia Domesticated Milk should already be functional. The system is configured:
- Resource type in native pool
- Creatures configured correctly
- Harvesting system implemented

If it's not working, likely causes:
1. Resource tree entry missing in client TRE files (client-side issue)
2. Resource spawn not created yet (wait for resource shift or restart)
3. Database issue (verify spawn exists)

Next steps:
1. Test locally using the test plan above
2. If not working, check troubleshooting section
3. If resource tree entry is missing, may need client TRE file update (outside server scope)

Should I create a test script to verify the resource spawn exists, or help troubleshoot if it's not working?

---

**User**

Okay let writ this into a .md file please ... for context and so I don't lose it. I'm about to get off and I'll do this later.

---

**Cursor**

Saving the design document to a markdown file for later reference.


Fixing the filename typo:


Renaming the file using the file tools:


Saved the design document as `CORELLIA_DOMESTICATED_MILK_DESIGN.md` in your project root. It includes:

- Design summary and configuration status
- Pre-CU authenticity checklist
- Technical implementation notes
- Verification and test plan
- Troubleshooting guide
- Git workflow steps (BG rules compliant)
- File references and configuration values

When you return, follow the test plan to verify Corellia Domesticated Milk is working. The document notes that the system should already be configured—you just need to test it.

