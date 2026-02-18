# Plan: Insect Meat for Dantooine, Lok, Tatooine, Yavin

**Goal:** Ensure each planet (Dantooine, Lok, Tatooine, Yavin) has at least one creature that yields **Insect meat** when harvested (i.e. `meatType = "meat_insect"`). Harvest on that planet then produces that planet’s insect meat resource (e.g. "Dantooine insect meat", "Lok insect meat").

**Scope:** Plan only — no code changes in this step.

---

## 1. Current state

| Planet     | Insect meat status | Existing creatures with `meat_insect` |
|-----------|--------------------|---------------------------------------|
| **Tatooine** | ✅ Already has     | rock_beetle, overkreetle, rockmite, sand_beetle, large_sand_beetle |
| **Yavin4**  | ✅ Already has     | puny_tanc_mite, tanc_mite, tanc_mite_warrior, deadly_tanc_mite, giant_tanc_mite; angler, angler_hatchling, angler_recluse, lurking_angler, mad_angler, giant_angler, bone_angler |
| **Dantooine** | ❌ None            | No creature uses `meat_insect` (quenkers use `meat_wild`) |
| **Lok**      | ❌ None            | No creature uses `meat_insect` |

So only **Dantooine** and **Lok** need changes. Tatooine and Yavin are done for insect meat.

---

## 2. Options per planet

### 2.1 Dantooine

- **Option A – Use existing quenkers**  
  Change all Dantooine quenker variants from `meatType = "meat_wild"` to `meatType = "meat_insect"`.  
  - Files: `quenker.lua`, `quenker_ravager.lua`, `quenker_relic_reaper.lua`, `savage_quenker.lua`, `terrible_quenker.lua`, `bile_drenched_quenker.lua`.  
  - Pros: No new assets, no spawn/lair work; instant Dantooine insect meat.  
  - Cons: Quenkers are sometimes considered more “reptilian” in canon; if you prefer insect-only, use Option B.

- **Option B – New Dantooine insect creature**  
  Add a new creature (e.g. “plains mite” or “dantooine beetle”) with `meat_insect`, then add to `serverobjects.lua` and to spawn/lair as desired.  
  - Pros: Thematically clear insect; no change to quenkers.  
  - Cons: New Lua template, possible new .iff if no suitable one exists, and spawn/lair integration.

**Recommendation:** Start with **Option A** (quenkers → meat_insect) for speed; add Option B later if you want a dedicated insect species.

---

### 2.2 Lok

- **Option A – New Lok insect creature**  
  Add one (or more) new creature(s), e.g. “sulfur mite” or “lok cave beetle”, with `meatType = "meat_insect"`.  
  - Steps: new Lua in `mobile/lok/<script>.lua`, include in `lok/serverobjects.lua`, add to spawn (e.g. `spawn/lok/*.lua`) and optionally lair.  
  - Need: Creature name, level range, .iff (reuse existing insect/mite if available), stats, loot.

- **Option B – Retask an existing Lok creature**  
  If there is an existing Lok mob that is clearly insect-like and currently uses another meat type, switch it to `meat_insect`.  
  - Current Lok creatures use meat_avian, meat_carnivore, meat_herbivore, meat_reptilian — none are obviously “insect” by name (vesps are reptilian, etc.), so Option A is more appropriate.

**Recommendation:** **Option A** — add at least one new Lok insect creature (e.g. one mite/beetle variant), then wire into spawn (and lair if desired).

---

### 2.3 Tatooine

- No change required for insect meat; already multiple sources.
- Optional: add another insect creature later for variety (e.g. another beetle/mite) if desired.

---

### 2.4 Yavin (yavin4)

- No change required; tanc mites and anglers already provide insect meat.
- Optional: add more insect variants later if desired.

---

## 3. Implementation order (when you implement)

1. **Dantooine**  
   - If Option A: edit the 6 quenker Lua files: set `meatType = "meat_insect"` (and optionally adjust `meatAmount` if desired).  
   - If Option B: create new creature Lua, add to `dantooine/serverobjects.lua`, then spawn/lair.

2. **Lok**  
   - New creature Lua in `mobile/lok/` (e.g. `sulfur_mite.lua` or `lok_cave_beetle.lua`).  
   - Include in `lok/serverobjects.lua`.  
   - Add to one or more `spawn/lok/*.lua` and optionally a lair in `lair/creature_lair/lok/`.

3. **Testing (per CREATURE_TEST_RUNNER / creature testing procedure)**  
   - Reload server if Lua changed: `shutdown 0 fast` then `./core3` from `MMOCoreORB/bin`.  
   - Admin: `/setGodMode self on`, `/invuln`.  
   - Per planet: `/teleport <planet> <x> <y>`, `/teleportTarget <combatToon> <planet> <x> <y>`, `/createCreature <script>`.  
   - Kill and harvest on combat toon; confirm correct meat (e.g. “Dantooine insect meat”, “Lok insect meat”).  
   - Cleanup: `/kill` or `/destroy`.

4. **Mission terminals (optional)**  
   If these creatures should appear on Destroy mission terminals, follow `.cursor/context/CREATURE_MISSION_TERMINAL_REQUIREMENTS.md` (add to destroy list + set `missionBuilding` on lair if applicable).

---

## 4. Summary

| Planet     | Action |
|-----------|--------|
| **Dantooine** | Either switch quenkers to `meat_insect` (Option A) or add new insect creature (Option B). |
| **Lok**       | Add at least one new insect creature with `meat_insect` and add to spawn (and optionally lair). |
| **Tatooine**  | No change needed. |
| **Yavin4**    | No change needed. |

Next step: choose Dantooine option (A or B) and name/level for the Lok insect creature, then implement and test.
