# Bellum Gero — Dev Environment Reference

Three dev environments are in use. Each has a defined role and a distinct path signature.

---

## Environment Detection

| If you see... | You are on... |
|---------------|---------------|
| Windows path `C:\Users\Shadow` or device `SHADOW-D03EOJBB` | Shadow PC |
| WSL hostname `EnderWookie` or Windows user `EnderWookie` (device `MS-7L91`) | Main Desktop |
| WSL hostname `LX15PRO` or Windows user `Mobile-Wookie` (device `LX15PRO`) | Laptop |

Auto-detect in WSL bash:
```bash
hostname   # returns EnderWookie (Main Desktop) or LX15PRO (Laptop)
```

---

## Shadow PC

- **Device**: SHADOW-D03EOJBB (cloud VM — Shadow Computer)
- **CPU**: AMD EPYC 9354, 32 cores @ 3.25 GHz
- **RAM**: 16 GB
- **GPU**: NVIDIA RTX 2000 Ada Generation (15 GB VRAM)
- **Storage**: 512 GB
- **OS**: Windows 11 Home
- **Role**: Code editing and asset editing ONLY
- **No WSL** — do not attempt to build or run the server here
- **Windows project path**: `C:\Users\Shadow\code\swg-bg`
- **Git/Cursor**: Use Cursor and Git from PowerShell or Git Bash

### What you can do on Shadow PC
- Edit Lua scripts, C++ source, IDL files
- Browse/edit TRE assets with SWG Explorer
- Commit and push code branches
- Review `.cursor/` rules and context

### What you CANNOT do on Shadow PC
- Build the server (no WSL, no Linux toolchain)
- Run or test the server
- Use `make`, `cmake`, `ninja`, `mariadb`, etc.

---

## Main Desktop

- **Device**: EnderWookie (`MS-7L91`)
- **CPU**: AMD Ryzen 5 3600, 6 cores @ 3.60 GHz
- **RAM**: 64 GB
- **GPU**: AMD Radeon RX 7600 XT (16 GB VRAM)
- **Storage**: 3.24 TB
- **OS**: Windows 11 Pro
- **WSL**: Debian — hostname `EnderWookie`, user `Enderwookie`
- **Role**: Primary build, test, and run server
- **Windows user**: `EnderWookie`

### Paths

| Item | Path |
|------|------|
| WSL project root | `~/localswgserver` |
| Windows project root | `C:\Users\EnderWookie` |
| TRE files (Windows) | `C:\BellumGero\` |
| TRE files (WSL) | `/mnt/c/BellumGero` |
| Config | `~/localswgserver/MMOCoreORB/bin/conf/config.lua` |
| Lua scripts | `~/localswgserver/MMOCoreORB/bin/scripts/` |

### Build recommendation
- Recommended flag: `NINJAFLAGS="-j6"`
- `.wslconfig` (`C:\Users\EnderWookie\.wslconfig`):
```ini
[wsl2]
memory=16GB
processors=6
swap=4GB
```

---

## Laptop (LX15PRO)

- **Device**: LX15PRO
- **CPU**: AMD Ryzen 5 7430U with Radeon Graphics @ 2.30 GHz
- **RAM**: 16 GB (15.4 GB usable)
- **GPU**: AMD Radeon integrated (496 MB)
- **Storage**: 477 GB
- **OS**: Windows 11 Pro
- **WSL**: Debian — hostname `LX15PRO`, user `EnderWookie`
- **Role**: Dev, test, and production server
- **Windows user**: `Mobile-Wookie`

### Paths

| Item | Path |
|------|------|
| WSL project root | `~/workspace/BellumGero-Live` |
| Windows project root | `C:\Users\Mobile-Wookie` |
| TRE files (Windows) | `C:\BellumGero\` |
| TRE files (WSL) | `/mnt/c/BellumGero` |
| Config | `~/workspace/BellumGero-Live/MMOCoreORB/bin/conf/config.lua` |
| Lua scripts | `~/workspace/BellumGero-Live/MMOCoreORB/bin/scripts/` |

### Build recommendation
- Recommended flag: `NINJAFLAGS="-j4"` (16 GB RAM — keep parallel jobs low)
- `.wslconfig` (`C:\Users\Mobile-Wookie\.wslconfig`):
```ini
[wsl2]
memory=6GB
processors=4
swap=4GB
```

---

## Shared Configuration

### TRE Files

Both WSL machines access TRE files from Windows:

| Machine | Windows path | WSL path |
|---------|-------------|----------|
| Main Desktop | `C:\BellumGero\` | `/mnt/c/BellumGero` |
| Laptop | `C:\BellumGero\` | `/mnt/c/BellumGero` |

`config.lua` setting: `TrePath = "/mnt/c/BellumGero"`

TREs are read-only client assets — do not modify them.

### Database (MariaDB — WSL only)

```
DBHost = "127.0.0.1"   -- NOT "db" (Docker default)
DBName = "swgemu"
DBUser = "swgemu"
DBPass = "swgemu"
```

### Git Identity (both WSL machines)

```
user.name  = Thewookie-Eng
user.email = bktarr@pm.me
```

### SSH Key

SSH key stored at `~/.ssh/id_ed25519` on both WSL machines.
GitHub account: **Thewookie-Eng** — repo: `git@github.com:Miphstoe/BellumGero-Live.git`
