# Mandalorian Daily Bounty Mission System - Executive Brief

## Overview
Endgame daily content system for Mandalorian Tribesmen (Chapter 5 completers). Provides repeatable bounty hunting progression with tiered difficulty and mixed rewards.

## FOB (Frequency Orbital Beacon)
- **Acquisition**: One-time grant from Mandalorian Recruiter (Mos Eisley cantina)
- **Eligibility**: This character must complete Chapter 5, currently have Novice Bounty Hunter, and wear a Mandalorian Way quest helmet (any custom tier). Account-wide completion does not qualify. Checked for FOB grants/use, mission acceptance (including automatic advancement), waypoint recovery, and camp kills before rewards/progression. Losing eligibility during combat retires the camp; restore eligibility and re-sync to retry the same tier without consuming another daily mission.
- **Regression check**: From the repository root, run `lua MMOCoreORB/utils/validate_mando_daily_eligibility.lua` (mocked engine; live equip/camp behavior still requires in-game verification).
- **Inventory Check**: Prevents duplicate FOB grants
- **Interface**: Right-click radial menu with two options:
  - "Mission Status" - Shows daily progress
  - "Accept Next Mission" - Starts next bounty contract

## Daily Mission System
- **Limit**: 5 missions per day per character
- **Reset**: Daily (date-based tracking via server data keys)
- **Progression**: Auto-advances through tiers 1-5 sequentially
- **Rewards**: Credits + mixed loot from camp completion, with rare reward chances increasing each tier

## Tier Structure
| Tier | Mark Level | Henchmen (Count/Level) | Credit Range | Special Mark |
|------|------------|----------------------|--------------|--------------|
| 1    | 45         | 2 × 38               | 8k-12k       | Wanted Outlaw |
| 2    | 50         | 3 × 42               | 10k-15k      | Wanted Outlaw |
| 3    | 55         | 4 × 46               | 12k-18k      | Wanted Outlaw |
| 4    | 60         | 5 × 50               | 15k-22k      | Wanted Outlaw |
| 5    | 100        | 6 × 54               | 20k-30k      | IG-88 Assassin Droid |

## Quest Flow
1. Acquire FOB from recruiter (one-time check)
2. Right-click FOB → "Accept Next Mission"
3. System validates daily count < 5
4. Spawn bounty camp at 1600-2200m range with waypoint
5. Travel to camp, eliminate mark + henchmen
6. Camp completion awards mixed loot (tier-specific loot groups)
7. Completion message directs player back to FOB
8. Repeat until 5/5 complete
9. Daily reset at midnight server time

## Daily loot probabilities

Each column totals 100%. These are category probabilities per reward roll,
not the chance of a particular item. Tiers 1–4 grant one roll; tier 5 retains
its camp reward plus an additional guild-contact roll from the same pool.

| Reward category | Tier 1 | Tier 2 | Tier 3 | Tier 4 | Tier 5 |
|---|---:|---:|---:|---:|---:|
| Armor schematics | 0.5% | 1% | 2% | 4% | 8% |
| Weapon schematics | 0.25% | 0.5% | 1% | 2% | 4% |
| Finished Mandalorian weapons | 0.1% | 0.25% | 0.5% | 0.75% | 1% |
| Advanced weapon components | 0.5% | 1% | 1.5% | 2% | 3% |
| Jetpack schematic | 0.1% | 0.25% | 0.5% | 1% | 2% |
| Jetpack components | 0.5% | 1% | 2% | 3% | 4% |
| Furniture schematics | 15% | 18% | 21% | 24% | 27% |
| Decorations and trophies | 83.05% | 78% | 71.5% | 63.25% | 51% |

Armor includes all ten BH and all ten DW Mandalorian armor schematics,
retaining the previous 10:41 BH-to-DW weighting within that category.
Weapon schematics cover the six Mandalorian melee weapons. Finished weapons
cover those six plus the Mandalorian Geonosian pistol, Nym slugthrower carbine,
and light lightning cannon. They use the existing weapon templates,
certifications, and experimental stat ranges, with normal loot quality and
condition rolls; they are usable weapons rather than schematic items.

Advanced components are the blaster power handler, blaster pistol barrel,
blaster rifle barrel, sword core, and vibro unit. Existing loot quality
modifiers still apply. Global component and weapon definitions are unchanged.

Existing decorations remain in each tier, furniture schematics are available
at every tier, and the tier 5 trophy selection remains available. The camp
message says "reward" because successful drops are not always schematics.
Four Mandalorian decorations appear at every tier with increasing per-roll
odds: the clan banner and clan painting rise through 1%, 2%, 3%, 5%, and 7.5%;
the clan hologram painting and helmet hologram rise through 0.25%, 0.5%,
0.75%, 1%, and 2%. Their weights come from the decoration category, leaving
all rare-reward category probabilities unchanged.
For tier 5's two rolls, the chance of at least one item from a category is
`1 - (1 - p)^2`: for example, armor is 15.36% and epic tissue is 0.9975%.

Run `python MMOCoreORB/utils/validate_mando_daily_loot.py` for static checks
of probabilities, registrations, reward coverage, and finished weapon stats.
Server spawning, equip checks, and displayed component stats still require
in-game validation.
