# Wild Meat & Planet-Specific Resource Creatures (Rori, Talus, Lok)

**Branch:** `Ender_WildMeat_Rori_talus_lok_ScaleyHide_lok_talus_wooley_hide`  
**Developer:** Ender  
**Scope:** New harvestable resource creatures for Rori (wild meat, wooly hide, wild milk), Talus (wild meat, wooly hide, animal bone, wild milk), and Lok (wild meat, scaley hide, animal bone).

---

## 1. Feature Summary

Four new creature templates and their dynamic lairs/spawns:

| Creature | Planet | Harvest Resources |
|----------|--------|-------------------|
| **Monstrous Dark Graul** | Rori | Rori wild meat only |
| **Wild Foreign Bantha** | Talus | Talus wild meat, Talus wooly hide, Talus animal bone, wild milk |
| **Wild Foreign Bantha (Rori)** | Rori | Rori wild meat, Rori wooly hide, Rori animal bone, **Rori wild milk** |
| **LongClaw Wild Vortor Lizard** | Lok | Lok wild meat, Lok scaley hide, Lok animal bone |

Resource type strings used (must exist in server resource spawns or fall back to base types):

- **Rori:** `meat_wild_rori`, `hide_wooly_rori`, `bone_mammal_rori`, `milk_wild_rori`
- **Talus:** `meat_wild_talus`, `hide_wooly_talus`, `bone_mammal_talus`, `milk_wild` (or `milk_wild_talus` if added)
- **Lok:** `meat_wild_lok`, `hide_scaley_lok`, `bone_mammal_lok`

---

## 2. Files Created (New)

| Path |
|------|
| `MMOCoreORB/bin/scripts/mobile/rori/monstrous_dark_graul.lua` |
| `MMOCoreORB/bin/scripts/mobile/rori/wild_foreign_bantha.lua` |
| `MMOCoreORB/bin/scripts/mobile/talus/wild_foreign_bantha.lua` |
| `MMOCoreORB/bin/scripts/mobile/lok/longclaw_wild_vortor_lizard.lua` |
| `MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/rori/rori_monstrous_dark_graul_pack_neutral_none.lua` |
| `MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/rori/rori_wild_foreign_bantha_herd_neutral_none.lua` |
| `MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/talus/talus_wild_foreign_bantha_herd_neutral_none.lua` |
| `MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/lok/lok_longclaw_wild_vortor_lizard_pack_neutral_none.lua` |
| `README_WildMeat_ResourceCreatures.md` |

---

## 3. Files Modified (Existing)

| Path | Change |
|------|--------|
| `MMOCoreORB/bin/scripts/mobile/rori/serverobjects.lua` | Added `includeFile` for `monstrous_dark_graul.lua`, `wild_foreign_bantha.lua` |
| `MMOCoreORB/bin/scripts/mobile/talus/serverobjects.lua` | Added `includeFile` for `wild_foreign_bantha.lua` |
| `MMOCoreORB/bin/scripts/mobile/lok/serverobjects.lua` | Added `includeFile` for `longclaw_wild_vortor_lizard.lua` |
| `MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/serverobjects.lua` | Added `includeFile` for the four new lair Lua files |
| `MMOCoreORB/bin/scripts/mobile/spawn/rori/rori_world.lua` | Added lair spawn entries for monstrous_dark_graul and wild_foreign_bantha_rori |
| `MMOCoreORB/bin/scripts/mobile/spawn/talus/talus_world.lua` | Added lair spawn entry for wild_foreign_bantha |
| `MMOCoreORB/bin/scripts/mobile/spawn/lok/lok_world.lua` | Added lair spawn entry for longclaw_wild_vortor_lizard |

---

## 4. Creature Template IDs (for spawn/lair reference)

| Template ID | Creature |
|-------------|----------|
| `monstrous_dark_graul` | Monstrous Dark Graul (Rori) |
| `wild_foreign_bantha` | Wild Foreign Bantha (Talus) |
| `wild_foreign_bantha_rori` | Wild Foreign Bantha (Rori) |
| `longclaw_wild_vortor_lizard` | LongClaw Wild Vortor Lizard (Lok) |

---

## 5. Lair Template Names (for spawn scripts)

| Lair Template Name |
|--------------------|
| `rori_monstrous_dark_graul_pack_neutral_none` |
| `rori_wild_foreign_bantha_herd_neutral_none` |
| `talus_wild_foreign_bantha_herd_neutral_none` |
| `lok_longclaw_wild_vortor_lizard_pack_neutral_none` |

---

## 6. Next Steps

1. **Test on WSL dev server** (see Testing section below) before considering the feature done.
2. **Resource types:** If the server does not have planet-suffixed resource types (e.g. `meat_wild_rori`) in its resource manager/spawns, either add them or confirm harvest falls back to base types (e.g. `meat_wild`) and that behavior is acceptable.
3. **Optional:** Add **creature_lair** (static lair) versions with buildings if you want fixed nest/camp POIs in addition to dynamic spawns.
4. **Optional:** Tweak spawn weighting/difficulty in `*_world.lua` after observing density in-game.

---

## 7. Testing (WSL Dev Server)

Do this on the **WSL dev server** (`~/localswgserver`), not on Shadow PC.

1. **Build (if needed)**  
   - `cd ~/localswgserver/MMOCoreORB && make -j$(nproc)`

2. **Start server**  
   - Start Core3 as you normally do (e.g. run the server process).

3. **In-game checks (each planet)**  
   - **Rori:** Find and kill **Monstrous Dark Graul** and **Wild Foreign Bantha**. Harvest each; verify you get Rori wild meat, and from the bantha also Rori wooly hide, bone, and **Rori wild milk**.  
   - **Talus:** Find and kill **Wild Foreign Bantha**. Harvest; verify Talus wild meat, wooly hide, animal bone, and milk.  
   - **Lok:** Find and kill **LongClaw Wild Vortor Lizard**. Harvest; verify Lok wild meat, scaley hide, and animal bone.

4. **Sanity checks**  
   - Confirm creature names and level/difficulty feel right.  
   - Confirm no Lua errors in server logs when these mobs spawn or are harvested.

---

## 8. Commit Instructions (Step-by-Step)

Do this from **Shadow PC** (PowerShell or Git Bash) or from **WSL** with the repo at `~/localswgserver` (or your clone path). Leave nothing out.

### 8.1. Confirm branch and what you will commit

- You must be on the **code branch** (this feature), not `Ender_CursorConfig` or `Main`:
  ```bash
  git branch --show-current
  ```
  Expected: `Ender_WildMeat_Rori_talus_lok_ScaleyHide_lok_talus_wooley_hide`

- Do **not** commit:
  - Any change to `WORKSPACE_STRUCTURE.md` or other `.cursor/context/` or dev-env-only files.
  - Any change that belongs only on `Ender_CursorConfig`.

### 8.2. Add only the feature files

Add every **new** and **modified** file that belongs to this feature (creatures, lairs, spawns, serverobjects, and this README). Do **not** add dev-env or config-only files.

```bash
git add MMOCoreORB/bin/scripts/mobile/rori/monstrous_dark_graul.lua
git add MMOCoreORB/bin/scripts/mobile/rori/wild_foreign_bantha.lua
git add MMOCoreORB/bin/scripts/mobile/talus/wild_foreign_bantha.lua
git add MMOCoreORB/bin/scripts/mobile/lok/longclaw_wild_vortor_lizard.lua
git add MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/rori/rori_monstrous_dark_graul_pack_neutral_none.lua
git add MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/rori/rori_wild_foreign_bantha_herd_neutral_none.lua
git add MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/talus/talus_wild_foreign_bantha_herd_neutral_none.lua
git add MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/lok/lok_longclaw_wild_vortor_lizard_pack_neutral_none.lua
git add MMOCoreORB/bin/scripts/mobile/rori/serverobjects.lua
git add MMOCoreORB/bin/scripts/mobile/talus/serverobjects.lua
git add MMOCoreORB/bin/scripts/mobile/lok/serverobjects.lua
git add MMOCoreORB/bin/scripts/mobile/lair/creature_dynamic/serverobjects.lua
git add MMOCoreORB/bin/scripts/mobile/spawn/rori/rori_world.lua
git add MMOCoreORB/bin/scripts/mobile/spawn/talus/talus_world.lua
git add MMOCoreORB/bin/scripts/mobile/spawn/lok/lok_world.lua
git add README_WildMeat_ResourceCreatures.md
```

### 8.3. Verify staged files

```bash
git status
```

- **Staged:** Only the 16 paths above (15 feature files + this README).  
- **Not staged / untracked:** Anything that is dev-env only (e.g. `WORKSPACE_STRUCTURE.md`, `.cursor/` changes). If something wrong is staged, unstage it:
  ```bash
  git restore --staged <path>
  ```

### 8.4. Commit

```bash
git commit -m "Add Rori/Talus/Lok resource creatures: wild meat, wooly/scaley hide, bone, Rori wild milk"
```

(Adjust the message if you prefer; keep it descriptive.)

### 8.5. Push the branch

```bash
git push -u origin Ender_WildMeat_Rori_talus_lok_ScaleyHide_lok_talus_wooley_hide
```

If the branch already exists on `origin` and is tracked:

```bash
git push
```

### 8.6. Notify for review

- Per project workflow: **no PRs**. Notify **Miphstoe** or **Hellguard** in Discord that the branch is pushed and ready for manual review.

### 8.7. Dev-env / config changes (separate branch)

- If you also changed Cursor rules, `.cursor/context/`, or other dev-env files, switch to **Ender_CursorConfig**, add **only** those files, commit, and push **after** this code push. See `.cursor/rules/bellum-gero.mdc` (Commit & Push Workflow).

---

## 9. Quick Reference – Resource Types by Planet

| Planet | Meat | Hide | Bone | Milk |
|--------|------|------|------|------|
| Rori | meat_wild_rori | hide_wooly_rori | bone_mammal_rori | milk_wild_rori |
| Talus | meat_wild_talus | hide_wooly_talus | bone_mammal_talus | milk_wild (or milk_wild_talus) |
| Lok | meat_wild_lok | hide_scaley_lok | bone_mammal_lok | — |

---

*This README documents the feature on branch `Ender_WildMeat_Rori_talus_lok_ScaleyHide_lok_talus_wooley_hide`. See also `.cursor/rules/bellum-gero.mdc` and `.cursor/rules/branch-naming.mdc` for project workflow.*
