# Mandalorian Daily Bounty Mission System - Executive Brief

## Overview
Endgame daily content system for Mandalorian Tribesmen (Chapter 5 completers). Provides repeatable bounty hunting progression with tiered difficulty and schematic rewards.

## FOB (Frequency Orbital Beacon)
- **Acquisition**: One-time grant from Mandalorian Recruiter (Mos Eisley cantina)
- **Eligibility**: Mandalorian Tribesmen only (Chapter 5 complete)
- **Inventory Check**: Prevents duplicate FOB grants
- **Interface**: Right-click radial menu with two options:
  - "Mission Status" - Shows daily progress
  - "Accept Next Mission" - Starts next bounty contract

## Daily Mission System
- **Limit**: 5 missions per day per character
- **Reset**: Daily (date-based tracking via server data keys)
- **Progression**: Auto-advances through tiers 1-5 sequentially
- **Rewards**: Credits + schematic loot from mark kills

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
6. Mark drops schematic loot (tier-specific loot groups)
7. Completion message directs player back to FOB
8. Repeat until 5/5 complete
9. Daily reset at midnight server time
