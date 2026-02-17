# Breakdown: cursor_previous_agent_chats_location.md

**Source:** `cursor_previous_agent_chats_location.md` (exported 2/14/2026)  
**Size:** ~9,180 lines, ~99 user/agent exchanges  
**Scope:** One long Cursor chat covering chat history, SWG context file placement, WSL server setup, DB/config, build/run, docs, and Git/SSH.

---

## 1. Cursor chat history (where + how to open)

| Topic | Summary |
|-------|--------|
| **Where are previous agent chats?** | **UI:** Chat panel → History (clock icon). **Disk (Windows):** `%APPDATA%\Cursor\User\workspaceStorage\*\state.vscdb` and `global-state.vscdb`. |
| **Open today’s chats** | Chat sidebar → History (clock) → open today’s entries. Or **`Ctrl+Alt+L`** → Chat/Composer History. |
| **Not paywalled** | Chat history is local; if empty, ensure same workspace (history is workspace-tied). For WSL: open `\\wsl.localhost\Debian\home\Enderwookie\...` (or the folder you used). |

---

## 2. SWG file structure context document

| Topic | Summary |
|-------|--------|
| **User action** | Pasted full `tree` of `D:\SWGProjects\Core3` (Windows path; different from `~/localswgserver`). |
| **Request** | Add to context files; create something like `SWG_FILE_CODE_STRUCUTRE_CONTEXT.md`. |
| **First placement** | Cursor created it at `/home/Enderwookie/SWG_FILE_CODE_STRUCUTRE_CONTEXT.md` (WSL home). |
| **Correction** | User: should be in `localswgserver`. Cursor moved it to `D:\SWGProjects\Core3\SWG_FILE_CODE_STRUCUTRE_CONTEXT.md` (no `localswgserver` under that Core3 tree). |
| **Symlink in WSL** | User wanted it to *also* show in parent `localswgserver`. **WSL commands (not PowerShell):** `mkdir -p "/mnt/d/SWGProjects/localswgserver"`, then `ln -sfn "../Core3/SWG_FILE_CODE_STRUCUTRE_CONTEXT.md" "/mnt/d/SWGProjects/localswgserver/SWG_FILE_CODE_STRUCUTRE_CONTEXT.md"`. |

---

## 3. Database (MariaDB) setup on WSL

| Topic | Summary |
|-------|--------|
| **Check if DB is running** | `sudo service mariadb status`; `ss -tlnp \| grep 3306`; `sudo mariadb -e "SHOW DATABASES;"`. |
| **Create Core3 DB** | `CREATE DATABASE swgemu;`; create user `swgemu`@`localhost` and `swgemu`@`127.0.0.1` with password `123456`; `GRANT ALL ON swgemu.*`; `FLUSH PRIVILEGES`; import: `sudo mariadb < .../MMOCoreORB/sql/swgemu.sql`. |
| **Bellum Gero?** | Yes — Core3 DB; `swgemu` is the DB name. `DBHost = "db"` in config is the *host* (Docker container name), not the DB name. |
| **config-local.lua** | Added to override `DBHost` from `"db"` → `127.0.0.1` for WSL-native MariaDB. |
| **User pushback** | “Why config-local.lua? Where is config.lua?” — Explained: `config.lua` is main; `config-local.lua` is optional override. Path: `localswgserver/MMOCoreORB/bin/conf/config.lua`. |
| **Undo** | User said “Undo all changes.” Cursor removed added files (e.g. context file from D:\ path, config-local.lua). User told to remove empty `D:\SWGProjects\localswgserver` manually. |

---

## 4. Build and TREs

| Topic | Summary |
|-------|--------|
| **CMake/Ninja** | Configure from `~/localswgserver/MMOCoreORB`; build in `build/unix/ninja-debug`; target `core3`. |
| **TRE check** | Python snippet to read `TreFiles` from `config.lua` and list missing TREs under `/trefiles`. All 52 present in this chat. |
| **Binary location** | `src/core3` inside build dir; copy to `MMOCoreORB/bin/core3` then run from `bin/`: `./core3`. |

---

## 5. Server run and first startup

| Topic | Summary |
|-------|--------|
| **Run** | `cp -f .../src/core3 .../bin/core3`; `cd ~/localswgserver/MMOCoreORB/bin`; `./core3`. |
| **Verify** | `ss -lntu | egrep ':(44453|44462)\b'`; check `log/`. |
| **TreeArchive WARNINGs** | “.iff not found” messages are often non-fatal; server continued loading. |
| **ad_queue.lua error** | `Failed to load ad queue file: custom_scripts/ad_queue.lua`. Fix: create `custom_scripts/ad_queue.lua` (e.g. `return {}`) or use example template so server doesn’t spam. |

---

## 6. Restart server

| Topic | Summary |
|-------|--------|
| **Same terminal** | `Ctrl+C`, then `cd ~/localswgserver/MMOCoreORB/bin` and `./core3`. |
| **Background / lost terminal** | `pkill -f '.../MMOCoreORB/bin/core3'` (or path with `$HOME/localswgserver`), then start again. |

---

## 7. Local dev docs and “never again”

| Topic | Summary |
|-------|--------|
| **LOCAL_DEV_ENV_SETUP.md** | Created in `~/localswgserver`: WSL-native setup, DB, TREs at `/trefiles`, config-local.lua, build/run/restart, client connect, ad_queue fix. |
| **SWG_CONTEXT.md** | Updated with quick link to setup doc, config-local note, “known-good” snapshot, hub-ads note. |
| **.cursorrules** | Updated with DB guidance (Docker vs WSL) and link to LOCAL_DEV_ENV_SETUP. |
| **Dev tools from scratch** | Section added to setup doc: WSL2 + Debian, packages (git, ssh), GitHub auth, clone BellumGero-Live → `~/localswgserver`, submodules, Cursor (WSL path, terminals), client `login.cfg` (host + port). |
| **ad_queue for future devs** | Template `ad_queue.lua.example`; `.gitignore` entry for `custom_scripts/ad_queue.lua`; setup doc step: `mkdir -p ... custom_scripts` and `cp -n ... ad_queue.lua.example ... ad_queue.lua`. |

---

## 8. Two profiles and client connection

| Topic | Summary |
|-------|--------|
| **User goal** | Create two profiles on local server; add local-only stuff to ignore list; point local BG client at local instance and log in. |
| **Miphstoe** | User shared Discord discussion (two images) re: prod vs local client — two instances vs changing file location. |
| **Content in file** | Discord snippet: “So to switch from Prod to Local?” (client setup). |

---

## 9. Git and SSH

| Topic | Summary |
|-------|--------|
| **Push to GitHub** | `git remote -v`; `git push origin <branch>`; confirm branch with `git branch`. |
| **SSH key** | User thought they had SSH key. Steps: check `~/.ssh/`; generate `ed25519` if needed; add pub key to GitHub; `git remote set-url origin git@github.com:Miphstoe/BellumGero-Live.git`; `ssh -T git@github.com`. |
| **HTTPS auth failed** | “Invalid username or token. Password authentication is not supported.” → Must use SSH or Personal Access Token (PAT). Cursor gave full SSH setup and optional PAT steps. |

---

## 10. Recurring path/config facts (from this chat)

- **Repo root:** `~/localswgserver` (WSL). Not `D:\SWGProjects\Core3` (that’s a different tree).
- **Config:** `config.lua` first; `config-local.lua` optional override (e.g. `DBHost = "127.0.0.1"`).
- **DB name:** `swgemu`; user `swgemu` / pass `123456` (defaults).
- **Login port:** 44453; client uses `127.0.0.1` or WSL IP.
- **Binary:** Build in `MMOCoreORB/build/unix/ninja-debug`; run from `MMOCoreORB/bin`.

---

## 11. Files created or updated (mentioned in chat)

| File | Action |
|------|--------|
| `SWG_FILE_CODE_STRUCUTRE_CONTEXT.md` | Created (then moved; symlink from localswgserver in WSL). |
| `config-local.lua` | Added then undone. |
| `LOCAL_DEV_ENV_SETUP.md` | Created and expanded. |
| `SWG_CONTEXT.md` | Updated. |
| `.cursorrules` | Updated (later migrated to `.cursor/rules/` in another chat). |
| `MMOCoreORB/bin/custom_scripts/ad_queue.lua.example` | Added. |
| `MMOCoreORB/bin/.gitignore` | Entry for `custom_scripts/ad_queue.lua`. |

---

## 12. How to use this breakdown

- **Find a topic:** Use the section headers (e.g. “Database”, “Build and TREs”, “Git and SSH”).
- **Get exact commands:** Reopen `cursor_previous_agent_chats_location.md` and search for the topic (e.g. “config-local”, “ad_queue”, “ssh-keygen”, “ninja core3”).
- **Cross-reference:** Match with your other exports (`cursor_domesticated_milk.md`, `cursor_nightsister_lance_weapon_creatio.md`, `cursor_core3_server_reboot_command.md`) for consistent paths and workflows.

If you want, the next step can be a one-page “cheat sheet” (commands only) or a merge of this breakdown into a single “Bellum Gero local dev” reference.
