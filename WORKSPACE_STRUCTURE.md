# Workspace Folder and File Structure

This document describes the folder and file layout of the **swg-bg** (SWG Bellum Gero) workspace. It was generated from a full review of the repository. Paths are relative to the workspace root unless noted.

---

## Root Level

| Item | Type | Description |
|------|------|-------------|
| **.cursor/** | directory | Cursor IDE workspace data: rules, skills, extensions, ai-tracking. See [.cursor/README.md](.cursor/README.md). |
| **.git/** | directory | Git repository data (not listed in detail). |
| **docker/** | directory | Docker build and run for Core3 dev/server. |
| **linux/** | directory | Linux (native) bootstrap/setup scripts. |
| **MMOCoreORB/** | directory | SWGEmu Core3 server (ORB) — main codebase; Git submodule `engine3` under `utils/`. |
| **wsl2/** | directory | WSL2 bootstrap/setup for Windows. |
| **.gitignore** | file | Git ignore patterns. |
| **.gitmodules** | file | Git submodules (e.g. `MMOCoreORB/utils/engine3` → swgemu/engine3). |
| **COPYING** | file | License. |
| **README.md** | file | Project overview, Docker/WSL setup, build/run. |

---

## .cursor/

Cursor-specific configuration and state. Only the structure relevant to the **project** is listed; extension bundles under `.cursor/extensions/` are omitted (they are IDE extensions, not part of the game code).

| Item | Type | Description |
|------|------|-------------|
| **ai-tracking/** | directory | AI code-tracking database (`ai-code-tracking.db`). |
| **extensions/** | directory | Installed Cursor/VSCode extensions (e.g. C++, Lua, WSL, SWG IFF/TRE tools). See `.cursor/README.md` for SWG tooling. |
| **projects/** | directory | Cursor project state. |
| **rules/** | directory | Workspace rules (e.g. `bellum-gero.mdc` — Bellum Gero context, Lua-first, paths). |
| **skills-cursor/** | directory | Agent skills (create-rule, create-skill, update-cursor-settings, etc.). |
| **argv.json** | file | IDE argv state. |
| **ide_state.json** | file | IDE state. |
| **README.md** | file | Index of rules, skills, and related docs. |

---

## docker/

Docker-based build and run for the Core3 server. TRE files are expected in a Docker volume (e.g. `shared-tre` → `/tre/` in container).

| Item | Type | Description |
|------|------|-------------|
| **files/** | directory | Files copied into the image/container. |
| **files/firstboot/** | directory | First-boot scripts and dotfiles (e.g. `home-files/.profile`, `home-files/bin/build`, `home-files/bin/run`, MySQL README). |
| **scripts/** | directory | Scripts used in the container (e.g. `supervisord-core3.conf`). |
| **.gitignore** | file | Docker ignore patterns. |
| **build.sh** | file | Build the Docker image. |
| **Dockerfile** | file | Image definition. |
| **run.sh** | file | Run container and start interactive shell. |
| **default-env**, **env-base**, **env-run** | files | Environment/config for Docker runs. |

---

## linux/

Scripts for setting up a **native Linux** (non-Docker, non-WSL) development environment.

| Item | Type | Description |
|------|------|-------------|
| **.shellcheckrc** | file | ShellCheck configuration. |
| **bootstrap.sh** | file | Bootstrap script for Linux env. |
| **README.md** | file | Linux setup instructions. |

---

## wsl2/

Scripts for setting up **WSL2** on Windows (e.g. for Bellum Gero dev server at `~/localswgserver`).

| Item | Type | Description |
|------|------|-------------|
| **bootstrap.bat** | file | Windows batch script for WSL2 bootstrap. |
| **README.md** | file | WSL2 setup instructions. |

---

## MMOCoreORB/

SWGEmu Core3 server codebase. Contains C++ source, Lua scripts, config, SQL, and build files. **Lua-first** custom content (items, NPCs, spawns, quests, etc.) lives under `bin/scripts/` and `bin/custom_scripts/`. Build/run is done on **WSL dev server**, not on Shadow PC.

### Top-level

| Item | Type | Description |
|------|------|-------------|
| **bin/** | directory | Runtime: executables, config, scripts, logs, databases, navmeshes. |
| **build/** | directory | CMake/build output (generated). |
| **cmake/** | directory | CMake modules/config. |
| **doc/** | directory | Documentation. |
| **docker/** | directory | MMOCoreORB-specific Docker support. |
| **sql/** | directory | SQL schemas/migrations. |
| **src/** | directory | C++ source (client, server, tre3, pathfinding, etc.). |
| **utils/** | directory | Utilities; **utils/engine3** is a Git submodule (engine3). |
| **.cdtproject**, **.cproject**, **.project** | files | Eclipse CDT project. |
| **.clang-format**, **.clang_complete** | files | Clang format and completion. |
| **.gitignore** | file | Ignore patterns. |
| **AUTHORS**, **ChangeLog**, **COPYING**, **NEWS**, **README** | files | Project metadata. |
| **CMakeLists.txt**, **Makefile** | files | Build. |
| **codetemplates.xml**, **suppressions.txt** | files | Code style/suppressions. |
| **README.osx** | file | macOS build notes. |

### MMOCoreORB/bin/

| Item | Type | Description |
|------|------|-------------|
| **conf/** | directory | Server config: `config.lua`, `config-local.lua` (WSL), `features.lua`, `adminusers.lst`, `bannedusers.lst`, `motd.txt`, etc. |
| **custom_scripts/** | directory | Symlinks or overrides for custom Lua (loot, mobile, object, screenplays); see README.md there. |
| **databases/** | directory | Database files (often .gitignore’d). |
| **log/** | directory | Log output; **log/admin/** for admin logs. |
| **navmeshes/** | directory | Navigation meshes. |
| **scripts/** | directory | **Main Lua scripts** (ai, commands, loot, mobile, object, screenplays, skills, staff, etc.). |
| **ccore3**, **dcore3**, **hcore3**, **vcore3**, **vcore3client** | files | Server/client executables (built on WSL). |
| **core3-default.supp** | file | Suppression file for diagnostics. |
| **.gitignore** | file | Ignore runtime artifacts. |

### MMOCoreORB/bin/scripts/

Primary location for **Lua** game logic. Key subdirectories:

| Subdirectory | Purpose |
|--------------|---------|
| **ai/** | AI behaviors (e.g. cityPatrol, crackdown, deathWatch, default, pet, static). |
| **ai_space/** | Space AI (default, escort, spaceStations, turretship). |
| **commands/** | In-game commands (hundreds of `.lua` files). |
| **custom/** | Custom content (e.g. name_pools). |
| **custom_scripts/** | Custom script hooks (loot, mobile, object, screenplays). |
| **loot/** | Loot definitions: **groups/** (e.g. creature, npc, space, theme_park) and **items/** (armor, creature, forage, etc.). |
| **managers/** | Lua-side managers. |
| **mobile/** | Mobile (NPC/creature) scripts. |
| **object/** | Object scripts. |
| **screenplays/** | Quest/screenplay scripts. |
| **ship_mobile/** | Space ship mobiles and patrol points. |
| **skills/** | Skill definitions (e.g. language, staff). |
| **staff/** | Staff levels (admin, dev, csr, etc.). |
| **utils/** | Helper scripts (spawn_mobiles, space_helpers, logger, helpers). |

Root-level files here include `custom_scripts.lua`, `testscript.lua`, and loader/config as needed.

### MMOCoreORB/src/

C++ source tree. High-level layout:

| Subdirectory | Purpose |
|--------------|---------|
| **client/** | Client code: **login/**, **zone/** (managers, objects: creature, intangible, player, scene, tangible). |
| **conf/** | Config handling. |
| **odb/** | Object database layer. |
| **pathfinding/** | Pathfinding (e.g. recast). |
| **server/** | Server code: **chat/**, **db/**, **features/**, **login/** (account, objects, packets), **metrics/**, **ping/**, **status/**, **utils/**, **web/**, **zone/** (managers—e.g. auction, city, combat, crafting, creature—objects, packets). |
| **templates/** | C++ templates. |
| **terrain/** | Terrain. |
| **tests/** | Tests. |
| **tre3/** | TRE archive handling. |

---

## Git Submodule

- **MMOCoreORB/utils/engine3** — [swgemu/engine3](https://github.com/swgemu/engine3) (shallow clone). Required for building Core3.

---

## Summary

- **Root:** Repo metadata, Docker/Linux/WSL setup, and the main **MMOCoreORB** tree.
- **.cursor:** IDE rules, skills, and extensions (see `.cursor/README.md`).
- **docker/, linux/, wsl2:** Environment setup; WSL2 is used for the Bellum Gero dev server.
- **MMOCoreORB:** Core3 server — **bin/** for config and Lua, **bin/scripts/** for gameplay Lua, **src/** for C++, **utils/engine3** as submodule.

For Bellum Gero workflow (Shadow PC vs WSL), see the workspace rule **bellum-gero.mdc** and `.cursor/README.md`.
