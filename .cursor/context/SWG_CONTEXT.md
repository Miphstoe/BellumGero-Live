## Bellum Gero (BG) SWGEmu Server Context

- **User**: Enderwookie
- **Project root (WSL)**: `~/localswgserver` (Main Desktop) or `~/workspace/BellumGero-Live` (Laptop)
- **OS**: Windows 11 + WSL2 (Debian 12 Bookworm)

## Quick links (read these first)

- **Local dev setup (WSL-native MariaDB)**: `LOCAL_DEV_ENV_SETUP.md`
- **Project structure snapshot**: `SWG_FILE_CODE_STRUCUTRE_CONTEXT.md`
- **New creatures on mission terminals**: `CREATURE_MISSION_TERMINAL_REQUIREMENTS.md` (Destroy missions checklist + when to ask)

### File system rules
- **Codebase (Linux / WSL)**: `~/localswgserver/` (Main Desktop) or `~/workspace/BellumGero-Live/` (Laptop)
  - **Rule**: all code edits, builds, and server runs happen here (WSL paths).
- **Game assets (Windows)**: `/mnt/c/SWGEmu/`
  - **Rule**: treat as read-only TRE assets; don’t compile/build here.

### Portal / client assets: provide TRE files
Core3 needs access to the client `.tre` files.

This repo’s current `config.lua` uses `TrePath = "/trefiles"`, so set up `/trefiles` in WSL.

#### Option A (common BG dev workflow): copy TREs into WSL
Before copying, confirm the `.tre` files exist on your machine (WSL view of your Windows install):

```bash
ls -la /mnt/c/SWGEmu/*.tre | head
```

If that returns “No such file”, your SWG client (and its `.tre` files) is in a different Windows folder—find that folder first, then copy from that location instead.

Example (one possible dev layout):
- Windows: `C:\home\enderwookie\Desktop\SWGEmu`
- WSL: `/mnt/c/home/enderwookie/Desktop/SWGEmu`

One-time setup:

```bash
sudo mkdir -p /trefiles
```

Copy ALL `.tre` files (simple, a bit slower):

```bash
sudo cp -f /mnt/c/SWGEmu/*.tre /trefiles/
```

Copy ONLY the BG custom tre (fast iteration, recommended if that’s all you change):

```bash
sudo cp -f /mnt/c/SWGEmu/bg_custom1.tre /trefiles/
```

Verify:

```bash
ls -la /trefiles/bottom.tre
```

#### Option B (optional): symlink TREs from Windows
Instead of copying, you can symlink the Windows files into `/trefiles`:

```bash
sudo mkdir -p /trefiles
sudo ln -s /mnt/c/SWGEmu/*.tre /trefiles/ 2>/dev/null || true
ls -la /trefiles/bottom.tre
```

### Codebase map (high-signal folders)
Repo root: `~/localswgserver` (Main Desktop) or `~/workspace/BellumGero-Live` (Laptop)
- `MMOCoreORB/`: Core3 server source + build system
  - `bin/`: runtime directory (binaries, logs, scripts)
    - `conf/config.lua`: main config (see DB section)
    - `scripts/`: Lua content (preferred for most gameplay/content edits)
  - `src/`: C++ core code (requires rebuild)
- `docker/`: containerized dev/server environment scripts
- `wsl2/`: Windows/WSL helper scripts
- `linux/`: Linux bootstrap docs/scripts

### Build + run (WSL Debian) — for THIS repo
Install build dependencies (Debian 12):

```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build clang gdb default-jre git \
  libmariadb-dev libmariadb-dev-compat liblua5.3-dev libdb5.3-dev libssl-dev \
  libboost-all-dev libjemalloc-dev
```

If your build complains that `dpp` is missing (Discord++ / DPP), you must install DPP so `pkg-config` can find it:

```bash
pkg-config --modversion dpp
```

If `libdpp-dev` is not available in your Debian repos, build and install DPP from source (then rerun the `pkg-config` command above):

```bash
mkdir -p ~/localswgserver/third_party
cd ~/localswgserver/third_party
git clone https://github.com/brainboxdotcc/DPP.git
cd DPP
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
sudo cmake --install build
sudo ldconfig
```

Build (recommended dev build):

```bash
cd ~/localswgserver/MMOCoreORB
make build-ninja-debug
```

Build (production-style):

```bash
cd ~/localswgserver/MMOCoreORB
make -j"$(nproc)"
```

Run:

```bash
cd ~/localswgserver/MMOCoreORB/bin
./core3
```

Debug run:

```bash
cd ~/localswgserver/MMOCoreORB/bin
gdb ./core3
```

### Database configuration (what Core3 will use)
**Config source of truth**: `~/localswgserver/MMOCoreORB/bin/conf/config.lua`

Current main DB values in that file:
- **DBHost**: `"db"`
- **DBPort**: `3306`
- **DBName**: `"swgemu"`
- **DBUser**: `"swgemu"`
- **DBPass**: stored in `config.lua` (don’t duplicate secrets here)

Override behavior:
- `conf/config-local.lua` is parsed after `config.lua` if it exists.
- For WSL-local MariaDB (non-docker), you’ll typically create `conf/config-local.lua` to override **just** the connection host/user/pass (example without secrets):

```lua
-- ~/localswgserver/MMOCoreORB/bin/conf/config-local.lua
DBHost = "127.0.0.1"
DBPort = 3306
DBName = "swgemu"
DBUser = "swgemu"
-- DBPass = "your-local-password"
```

DB schema/data sources in this repo:
- `~/localswgserver/MMOCoreORB/sql/swgemu.sql` (main schema/data)
- `~/localswgserver/MMOCoreORB/sql/datatables.sql` (extra tables)
- `~/localswgserver/MMOCoreORB/sql/mantis.sql` (mantis schema)

### Current known-good local status (2026-02-01)

- **MariaDB**: running on `127.0.0.1:3306`
- **Database**: `swgemu` exists and is imported
- **DB user**: `swgemu` exists for `localhost` and `127.0.0.1`
- **TREs**: `TrePath = "/trefiles"` and required `.tre` files are present
- **Build output**: server binary built at `MMOCoreORB/build/unix/ninja-debug/src/core3`
- **Run**: copy to `MMOCoreORB/bin/core3` and run from `MMOCoreORB/bin`
- **Hub ads**: missing `bin/custom_scripts/ad_queue.lua` will spam errors until you create an Ad; see `LOCAL_DEV_ENV_SETUP.md`

See `LOCAL_DEV_ENV_SETUP.md` for the full step-by-step.

### Workflow rules (day-to-day)
- **Lua first**: for items/NPCs/stats, prefer `MMOCoreORB/bin/scripts/` (fast, no compile).
- **C++ only when needed**: changes in `MMOCoreORB/src/` require rebuild.
- **Strict builds**: this repo uses `-Werror` (warnings become errors). Fix the warning in code rather than weakening the build.
- **New creatures and mission terminals**: When adding new creatures that should be targetable via Destroy missions, ask: *"Do you want this creature on the Destroy mission terminal so players can take target missions for it?"* If yes, follow **CREATURE_MISSION_TERMINAL_REQUIREMENTS.md** (add lair to planet `destroy_mission` list + set `missionBuilding` and `customName` on the lair).
- **Branch split**: Cursor context, rules, and plans (`.cursor/` .md files) live on **Ender_CursorConfig**. Game code (Lua, C++, scripts under `MMOCoreORB/`) stays on feature branches (e.g. WildMeat). When moving Cursor docs from a feature branch into Ender_CursorConfig, use `git checkout <feature-branch> -- .cursor/context/<file>.md` (or specific paths)—do not replace the entire `.cursor/` with the other branch’s version.
- **Feature plan doc exception**: On feature branches, allow only project-level planning docs named `FeaturePlan_[Subject].md` at repo root. Keep all other rules/context/workflow docs on `Ender_CursorConfig`.
- **Never mix before merge**: Run `premerge` immediately before every `git merge`. It enforces five checks (`git rev-parse --show-toplevel`, `git branch --show-current`, `git status --short`, `git stash list --max-count=3`, `git fetch origin --prune`) and blocks merges on dirty trees. Script locations: `.cursor/scripts/premerge-check.sh` (WSL) and `.cursor/scripts/premerge-check.ps1` (PowerShell on Shadow PC).

### Quick SWGEmu note
SWGEmu is an open-source server emulator aiming to recreate **Star Wars Galaxies (Pre-CU)**.