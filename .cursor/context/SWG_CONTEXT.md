## Bellum Gero (BG) SWGEmu Server Context

> **Machine scope:** This file describes **this mobile laptop dev PC only** (paths, `Dev-BG` vs `BellumGero`, `/trefiles` workflow). Other computers or teammates may use different folders — do not treat this as global project truth.

- **User**: Enderwookie
- **Project root (WSL, this laptop)**: `~/workspace/BellumGero-Live/`
- **OS**: Windows 11 + WSL2 (Debian 12 Bookworm)

## Quick links (read these first)

- **Local dev setup (WSL-native MariaDB)**: `LOCAL_DEV_ENV_SETUP.md`
- **Project structure snapshot**: `SWG_FILE_CODE_STRUCUTRE_CONTEXT.md`
- **New creatures on mission terminals**: `CREATURE_MISSION_TERMINAL_REQUIREMENTS.md` (Destroy missions checklist + when to ask)

### File system rules (this laptop only)
- **Codebase (WSL)**: `/home/Enderwookie/workspace/BellumGero-Live/`
  - Edits, builds, and running Core3 from WSL use this tree.
- **`C:\Dev-BG\`** → **`/mnt/c/Dev-BG/`** on this machine: **local dev** client folder — SIE output, **`bg_custom1.tre`** you iterate on.
  - Copy **`bg_custom1.tre` from here** into WSL **`/trefiles/`** when testing the dev server on this laptop.
- **`C:\BellumGero\`** → **`/mnt/c/BellumGero/`** on this machine: **prod-style** install (client + TREs for production play). Not the default source for day-to-day **`/trefiles`** sync on this box unless you mean to test prod assets.

### Portal / client assets: provide TRE files
Core3 needs access to the client `.tre` files.

This repo’s current `config.lua` uses `TrePath = "/trefiles"`, so set up `/trefiles` in WSL.

#### Option A (common BG dev workflow): copy TREs into WSL
On **this laptop**, confirm `.tre` files exist:

```bash
ls -la /mnt/c/Dev-BG/*.tre | head
```

If that fails, your client may live under a different path on this PC — adjust commands accordingly.

One-time setup:

```bash
sudo mkdir -p /trefiles
```

Copy ALL `.tre` files (simple, a bit slower):

```bash
sudo cp -f /mnt/c/Dev-BG/*.tre /trefiles/
```

Copy ONLY the BG custom tre (fast iteration, recommended if that’s all you change):

```bash
sudo cp -f /mnt/c/Dev-BG/bg_custom1.tre /trefiles/
```

Verify:

```bash
ls -la /trefiles/bottom.tre
```

#### Option B (optional): symlink TREs from Windows
Instead of copying, you can symlink the Windows files into `/trefiles`:

```bash
sudo mkdir -p /trefiles
sudo ln -s /mnt/c/Dev-BG/*.tre /trefiles/ 2>/dev/null || true
ls -la /trefiles/bottom.tre
```

### Codebase map (high-signal folders)
Repo root (this laptop): `~/workspace/BellumGero-Live`
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
mkdir -p ~/workspace/BellumGero-Live/third_party
cd ~/workspace/BellumGero-Live/third_party
git clone https://github.com/brainboxdotcc/DPP.git
cd DPP
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
sudo cmake --install build
sudo ldconfig
```

Build (recommended dev build):

```bash
cd ~/workspace/BellumGero-Live/MMOCoreORB
make build-ninja-debug
```

Build (production-style):

```bash
cd ~/workspace/BellumGero-Live/MMOCoreORB
make -j"$(nproc)"
```

Run:

```bash
cd ~/workspace/BellumGero-Live/MMOCoreORB/bin
./core3
```

Debug run:

```bash
cd ~/workspace/BellumGero-Live/MMOCoreORB/bin
gdb ./core3
```

### Database configuration (what Core3 will use)
**Config source of truth**: `~/workspace/BellumGero-Live/MMOCoreORB/bin/conf/config.lua`

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
-- ~/workspace/BellumGero-Live/MMOCoreORB/bin/conf/config-local.lua
DBHost = "127.0.0.1"
DBPort = 3306
DBName = "swgemu"
DBUser = "swgemu"
-- DBPass = "your-local-password"
```

DB schema/data sources in this repo:
- `~/workspace/BellumGero-Live/MMOCoreORB/sql/swgemu.sql` (main schema/data)
- `~/workspace/BellumGero-Live/MMOCoreORB/sql/datatables.sql` (extra tables)
- `~/workspace/BellumGero-Live/MMOCoreORB/sql/mantis.sql` (mantis schema)

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
- **New creatures and mission terminals**: When adding new creatures that should be targetable via Destroy missions, ask: *"Do you want this creature on the Destroy mission terminal so players can take target missions for it?"* If yes, follow **CREATURE_MISSION_TERMINAL_REQUIREMENTS.md** (add lair to planet `destroy_mission` list + set `missionBuilding` on the lair).

### Quick SWGEmu note
SWGEmu is an open-source server emulator aiming to recreate **Star Wars Galaxies (Pre-CU)**.