# Cursor workspace – Bellum Gero / Shadow PC

Index for rules, skills, and related docs used in this Cursor workspace.

## Rules (always or contextually applied)

| File | Purpose |
|------|--------|
| [rules/bellum-gero.mdc](rules/bellum-gero.mdc) | SWG Bellum Gero context: Shadow PC vs WSL, Lua-first, paths, Git/collab. Always applied. |

## Skills (agent skills)

| Skill | Purpose |
|-------|--------|
| [skills-cursor/create-rule/](skills-cursor/create-rule/) | Create Cursor rules (`.cursor/rules/*.mdc`) |
| [skills-cursor/create-skill/](skills-cursor/create-skill/) | Create Agent Skills (SKILL.md) |
| [skills-cursor/create-subagent/](skills-cursor/create-subagent/) | Create custom subagents |
| [skills-cursor/migrate-to-skills/](skills-cursor/migrate-to-skills/) | Migrate rules/commands to skills |
| [skills-cursor/update-cursor-settings/](skills-cursor/update-cursor-settings/) | Modify Cursor/VSCode settings.json |

*(Note: `skills-cursor` is Cursor’s built-in skills directory.)*

## Related docs (Bellum Gero / Shadow PC)

These may live in your user folder or project; paths below are typical on Shadow PC:

| Doc | Typical path | Purpose |
|-----|--------------|--------|
| **SWG_EXPLORER_SETUP.md** | `C:\Users\Shadow\SWG_EXPLORER_SETUP.md` | Swg.Explorer install, build, TRE viewer setup |
| **SHADOW_PC_SETUP_PLAN.md** | `C:\Users\Shadow\SHADOW_PC_SETUP_PLAN.md` or project root | Shadow PC dev environment plan |
| **BELLUM_GERO_PROMPT.md** | `C:\Users\Shadow\BELLUM_GERO_PROMPT.md` or project root | Bellum Gero AI prompt / context |
| **README.md** (project) | e.g. `C:\Users\Shadow\code\swg-bg\README.md` | Project index (when in a repo) |

## Swg.Explorer (TRE viewer)

- **Setup (build + run):** See **SWG_EXPLORER_SETUP.md** (path above).
- **Install location:** `C:\Users\Shadow\Tools\Swg.Explorer`
- **Build from source:** DirectX DLLs go in `C:\Users\Shadow\Tools\Swg.Explorer\lib` — see that folder’s `README.txt`.

## WSL dev server

For build/run/test and server config, use the WSL dev server; see **bellum-gero.mdc** for paths (`~/localswgserver`, config, TREs).
