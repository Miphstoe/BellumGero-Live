# Standard Operating Procedure: Testing New Creatures in SWG (Admin)

**Applicability:** SWGEmu (Core3) admin commands.  
**Purpose:** Step-by-step SOP for field-testing new or modified creatures in SWG as an Admin, including God Mode setup, mobility, spawn, inspection, and cleanup.

---

## 1. God Mode Setup

Enable admin safety and visibility options before testing.

### 1.1 Admin privileges

- **Requirement:** Account must have admin level > 0 (e.g. `accounts.admin_level = 1` in the database). This is set outside the game (DB/config), not via an in-game command.
- Ensure your character has the **admin** ability so GM commands are available.

### 1.2 Enable God Mode (GM state)

```text
/setGodMode self on
```

- Use **`self`** to affect your character. Required for commands like `/gmrevive buff`.
- To turn off: `/setGodMode self off`

### 1.3 Invulnerability

```text
/invulnerable
```

- Abbreviation: **`/invuln`**
- Makes **you** (the target) invulnerable to all damage. You can still attack. Self-only per the reference command set.

### 1.4 Concealment (invisibility to NPCs / reduced aggro)

- The reference admin command set does **not** list a dedicated “invisibility” or “concealment” toggle.
- **Optional:** Use **`/grantSkill`** to give your character a Scout concealment-related skill (e.g. so you are less likely to be seen or aggro’d by creatures during tests). Exact skill box name depends on your server’s skill tables (see Appendix I in the admin booklet).
- If your server has a custom command for invisibility/concealment, use that and document it here.

**Quick checklist:**

| Step | Command | Purpose |
|------|--------|--------|
| 1 | (DB) `admin_level = 1` | Admin account |
| 2 | `/setGodMode self on` | Enable GM god mode |
| 3 | `/invuln` | Invulnerable |
| 4 | (Optional) `/grantSkill <concealSkill>` | Concealment if desired |

---

## 2. Mobility: Teleport

### 2.1 Syntax

**Teleport yourself:**

```text
/teleport <planet> <x> <y>
```

- **`<planet>`** — Planet name (e.g. `tatooine`, `naboo`, `corellia`). Use the exact name your server expects (often lowercase).
- **`<x>`** — World X coordinate.
- **`<y>`** — World Y coordinate. (Some docs show “Y” as the height axis; if your server uses Z for height, coordinates may be X, Z, Y — check server docs.)

**Examples:**

```text
/teleport naboo 0 0
/teleport tatooine 3500 -4800
/teleport corellia -137 4450
```

If your server uses comma-separated coordinates (e.g. `0,0`), use that format: `/teleport naboo 0,0`.

**Teleport another player (for reference):**

```text
/teleportTarget <targetName> [<planet> <x> <y>] [<z> <parentID>]
```

Example: `/teleportTarget PlayerName corellia 0 0`

### 2.2 Suggested test coordinates (field testing)

Use these as starting points; adjust for your server’s geography.

| Planet    | Location / use        | X      | Y (or Z) | Notes              |
|----------|------------------------|--------|----------|--------------------|
| **Tatooine** | Desert (open)          | 0      | 0        | Simple open area   |
| **Tatooine** | Near Mos Eisley       | 3525   | -4800    | City outskirts     |
| **Tatooine** | Anchorhead area       | -1300  | 3600     | Another open zone  |
| **Naboo**   | Theed / open          | 0      | 0        | Central            |
| **Naboo**   | Countryside           | -5850  | 4100     | Open field         |
| **Corellia**| Coronet / open        | 0      | 0        | Central            |
| **Corellia**| Wilderness            | -137   | 4450     | Open field         |

Replace **`<planet>`**, **`<x>`**, and **`<y>`** with your chosen row when using `/teleport <planet> <x> <y>`.

---

## 3. Testing Workflow

End-to-end flow: **Travel → Spawn creature → Check resources/stats → Clean up.**

### Step 1 — Travel to test location

1. Ensure God Mode is set up (Section 1).
2. Teleport to the desired planet and coordinates (Section 2).

   **Example:**

   ```text
   /teleport tatooine 0 0
   ```

### Step 2 — Spawn the creature

**Spawn command (Core3):**

```text
/createCreature <creatureScript> [<x> <z> <y>] [<planet>] [<cellId>]
```

- **`<creatureScript>`** — **Required.** Path to the creature script (e.g. under `MMOCoreORB/bin/scripts/`). Often `mobile/creature/...` or as in your server’s “Generate Items/Creature/NPC” list (Appendix II). Use the exact path your server expects (e.g. `mobile/creature/creature_name.lua` or script name without extension — check your server docs).
- **`[<x> <z> <y>]`** — Optional. Spawn at specific world coordinates (order may be x, z, y on your build).
- **`[<planet>]`** — Optional. Spawn on this planet; omit to use current planet.
- **`[<cellId>]`** — Optional. Interior cell; omit for outdoor spawns.

**Examples:**

- Spawn at your current location (outdoor):

  ```text
  /createCreature mobile/creature/somemob
  ```

- Spawn at specific coordinates on current planet:

  ```text
  /createCreature mobile/creature/somemob 100 0 200
  ```

- Spawn on a specific planet:

  ```text
  /createCreature mobile/creature/somemob 0 0 0 tatooine
  ```

Replace **`mobile/creature/somemob`** (and coordinates/planet) with your **creature template/script** and desired location.

### Step 3 — Check resources and stats

1. **Target the creature** (click or select).
2. **In-game checks:**
   - Health/attack behavior, name, level, faction.
   - If harvestable: harvest and verify resources (type, amount).
3. **Debug dump (optional):**  
   Use the targeted object to get detailed info (often emailed to you):

   ```text
   /dumpTargetInformation
   ```

   Use this to verify template, stats, object vars, and any custom data.

### Step 4 — Clean up

**Option A — Kill (preferred for creatures):**

1. Target the creature.
2. Run:

   ```text
   /kill
   ```

   This kills the targeted creature (or player). No extra arguments needed.

**Option B — Hard destroy (if needed):**

- If the creature must be removed as an object (e.g. stuck or non-responsive):

  ```text
  /destroy [destroyChildren]
  ```

  Target the creature first. **`destroyChildren`** defaults to true. Use only when `/kill` is not sufficient.

---

## 4. Variable summary (what you must fill in)

| Variable              | Where used              | Example / note                          |
|-----------------------|-------------------------|-----------------------------------------|
| **Planet name**       | `/teleport`, `/createCreature` | `tatooine`, `naboo`, `corellia`        |
| **X, Y (Z)**          | `/teleport`, `/createCreature` | Numbers from Section 2.2 or your choice |
| **Creature template** | `/createCreature`       | e.g. `mobile/creature/your_creature`    |
| **Conceal skill**     | Optional `/grantSkill`  | From your server’s skill tables         |

---

## 5. References

- **Admin commands:** `.cursor/context/SWG_ADMIN_COMMANDS_CONTEXT.md` (from SWGEMU Admin Commands booklet).
- **God mode / buffs:** `.cursor/context/cursor_core3_server_reboot_command.md` (e.g. `/setGodMode self on`, `/gmrevive buff`).
- **Project context:** `.cursor/rules/bellum-gero.mdc` (Bellum Gero, WSL dev server, Lua-first).
- **Creature scripts:** `MMOCoreORB/bin/scripts/` (Lua); creature paths and Appendix II on your server define the exact **&lt;creatureScript&gt;** for `/createCreature`.

---

*SOP version: 1.0. Adjust teleport coordinate order (x/y/z) and creature script path format to match your Core3 build and server docs.*
