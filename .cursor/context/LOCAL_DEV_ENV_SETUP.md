# Local Dev Environment Setup (WSL Native) — Bellum Gero

This is the **known-good, reproducible** setup for running Bellum Gero locally on **Windows + WSL (Debian)** with:

- **Server repo**: `~/localswgserver` (BellumGero-Live)
- **DB**: **MariaDB installed in WSL** (not Docker)
- **Client assets**: `.tre` files available in WSL at `/trefiles`

If you follow this in order, you should not have to rediscover any of the common “gotchas”.

## Dev tools setup (from scratch)

### Windows: install WSL2 + Debian

- Enable WSL2 and install Debian (Windows Terminal / PowerShell):

```powershell
wsl --install
wsl --install -d Debian
```

After install, launch Debian and create your Linux user (this guide assumes `Enderwookie`).

### WSL: base packages (git, build tools)

Inside Debian (WSL):

```bash
sudo apt update
sudo apt install -y git openssh-client ca-certificates curl
```

### GitHub auth (HTTPS or SSH)

This repo works with **HTTPS** (simplest) or **SSH** (recommended if you contribute a lot).

- **HTTPS**: clone normally; you’ll authenticate via Git Credential Manager on Windows when needed.
- **SSH (optional)**:

```bash
ssh-keygen -t ed25519 -C "enderwookie@bellumgero" -f ~/.ssh/id_ed25519
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Add the printed public key to GitHub: Settings → SSH and GPG keys.

### Clone the Bellum Gero repo

```bash
cd ~
git clone https://github.com/Miphstoe/BellumGero-Live.git localswgserver
cd ~/localswgserver
git submodule update --init --recursive
```

### Cursor (recommended)

- Install Cursor on Windows.
- Open the WSL repo folder in Cursor using the WSL path:
  - `\\wsl.localhost\Debian\home\Enderwookie\localswgserver`
- Use a WSL terminal for commands/builds (avoid PowerShell for Linux build steps).

## Repo (one-time)

```bash
cd ~/localswgserver
git remote -v
git submodule update --init --recursive
```

## System dependencies (one-time)

```bash
sudo apt update
sudo apt install -y \
  build-essential cmake ninja-build clang gdb default-jre git python3 \
  libmariadb-dev libmariadb-dev-compat liblua5.3-dev libdb5.3-dev libssl-dev \
  libboost-all-dev libjemalloc-dev
```

Discord integration (DPP) is required by this repo. Verify:

```bash
pkg-config --modversion dpp
```

If missing, follow the DPP install steps in `SWG_CONTEXT.md`.

## TRE files (one-time)

Core3 is configured to use:

- `TrePath = "/trefiles"` (see `MMOCoreORB/bin/conf/config.lua`)

Create and populate `/trefiles`:

```bash
sudo mkdir -p /trefiles
# Adjust this source path if your client TREs are elsewhere:
sudo cp -f /mnt/c/SWGEmu/*.tre /trefiles/
```

Verify:

```bash
ls -la /trefiles/bottom.tre
```

Optional: verify you have *all* TREs listed in config:

```bash
python3 - <<'PY'
import re, pathlib
cfg = pathlib.Path.home() / "localswgserver/MMOCoreORB/bin/conf/config.lua"
text = cfg.read_text(errors="ignore")
m = re.search(r"TreFiles\\s*=\\s*\\{([\\s\\S]*?)\\}\\s*,", text)
files = re.findall(r'"([^"]+\\.tre)"', m.group(1)) if m else []
base = pathlib.Path("/trefiles")
missing = [f for f in files if not (base / f).exists()]
print(f"TreFiles listed: {len(files)}")
print(f"Present in /trefiles: {len(files)-len(missing)}")
if missing:
    print("MISSING:")
    for f in missing: print(" -", f)
else:
    print("All TRE files present.")
PY
```

## MariaDB (one-time)

Confirm MariaDB is running:

```bash
sudo service mariadb status
```

Create/import the Core3 database:

```bash
sudo mariadb -e "CREATE DATABASE IF NOT EXISTS swgemu;"
sudo mariadb < ~/localswgserver/MMOCoreORB/sql/swgemu.sql
```

Create the DB user that Core3 uses by default (`swgemu` / default password in `config.lua`):

```bash
sudo mariadb -e "CREATE USER IF NOT EXISTS 'swgemu'@'localhost' IDENTIFIED BY '123456';"
sudo mariadb -e "CREATE USER IF NOT EXISTS 'swgemu'@'127.0.0.1' IDENTIFIED BY '123456';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON swgemu.* TO 'swgemu'@'localhost';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON swgemu.* TO 'swgemu'@'127.0.0.1';"
sudo mariadb -e "FLUSH PRIVILEGES;"
```

Verify:

```bash
sudo mariadb -e "SHOW DATABASES LIKE 'swgemu';"
sudo mariadb -e "USE swgemu; SHOW TABLES;" | head -n 25
```

## Core3 config for WSL-native DB (one-time)

### Why `config-local.lua` exists

`MMOCoreORB/bin/conf/config.lua` is the **shared default** and (in this repo) uses:

- `DBHost = "db"` (Docker-style hostname)

When running MariaDB **natively in WSL**, override DB connectivity locally via:

- `MMOCoreORB/bin/conf/config-local.lua`

Create/update `config-local.lua`:

```bash
cat > ~/localswgserver/MMOCoreORB/bin/conf/config-local.lua <<'EOF'
Core3 = Core3 or {}
Core3.DBHost = "127.0.0.1"
Core3.DBPort = 3306
Core3.DBName = "swgemu"
Core3.DBUser = "swgemu"
Core3.DBPass = "123456"
EOF
```

> Note: `config-local.lua` is parsed after `config.lua` if it exists.

## Build (repeat as needed)

```bash
cd ~/localswgserver/MMOCoreORB
make build-ninja-debug
```

If it only generates IDL the first time, explicitly build the server target:

```bash
cd ~/localswgserver/MMOCoreORB/build/unix/ninja-debug
ninja core3
```

## Run (repeat as needed)

Copy the built binary into `bin/` and start:

```bash
cp -f ~/localswgserver/MMOCoreORB/build/unix/ninja-debug/src/core3 ~/localswgserver/MMOCoreORB/bin/core3
cd ~/localswgserver/MMOCoreORB/bin
./core3
```

### Restart server

- Foreground: **Ctrl+C**, then rerun `./core3`
- If you lost the terminal:

```bash
pkill -f "$HOME/localswgserver/MMOCoreORB/bin/core3" || true
cd ~/localswgserver/MMOCoreORB/bin
./core3
```

## Client connection (Windows client → WSL server)

Core3 default login port:

- `LoginPort = 44453`

Typical approaches:

- Try `127.0.0.1:44453` first
- If that doesn’t work, use your WSL IP:

```bash
hostname -I | awk '{print $1}'
```

### Find and edit `login.cfg` (Windows)

The SWG client has a `login.cfg` (or similarly named config) that controls login server host/port.

Because install locations vary, search for it:

- In **Windows Explorer** search your SWG client folder for `login.cfg`.
- Or in **WSL** (if you know the Windows client folder):

```bash
ls -la /mnt/c/SWGEmu/login.cfg 2>/dev/null || true
```

Typical values to set:

- **LoginServerAddress**: `127.0.0.1` (try first) or your WSL IP (from `hostname -I`)
- **LoginServerPort**: `44453`

After editing, start your SWG client and log in.

> If login fails, check `MMOCoreORB/bin/log/core3.log` and confirm `AutoReg`/account settings in `config.lua` for local testing.

## Known “madness” issues and fixes

### “ERROR: Failed to load ad queue file … custom_scripts/ad_queue.lua”

This is the Bellum Gero hub ads system. The file is **created when you create an Ad** via the BG Hub.

To stop spam immediately (safe placeholder), copy the template into place:

```bash
mkdir -p ~/localswgserver/MMOCoreORB/bin/custom_scripts
cp -n ~/localswgserver/MMOCoreORB/bin/custom_scripts/ad_queue.lua.example \
  ~/localswgserver/MMOCoreORB/bin/custom_scripts/ad_queue.lua
```

Restart `./core3`.

### “DBHost = db” confusion

- `db` is a **hostname** (commonly a Docker service name), not a database name.
- For WSL-native MariaDB you want `127.0.0.1` in `config-local.lua`.

