# Mandalorian Project Overview (Player Perspective)

This document summarizes the Mandalorian project as it currently plays in game, what has been updated recently, and what players should expect next.

## What The Mandalorian Project Includes

- A full progression path called **Mando Way of Life**.
- Foundling onboarding with recruiter and informant steps.
- Chapter based progression from Foundling to Clanbound, then Mandalorian title progression.
- Spynet chapter gates tied to Bounty Hunter terminal progression.
- Private Spynet trial flow using bounty camp theaters instead of legacy disk driven flow.
- Rank rewards that include armor, titles, badges, and chapter specific unlocks.
- Mandalorian armory additions with chapter gated cert weapons and related schematics.
- Chapter and status messaging and system guidance to keep progression readable for players.

## Major Updates We Have Made

## 1) Progression Clarity And Reliability

- Added clearer recruiter, trialmaster, and operative guidance for what to do next.
- Added phase based status reporting for chapter gates and Spynet progress.
- Added or hardened login refresh behavior so key waypoints return correctly after relog.
- Reworked text and punctuation in many player facing lines to avoid client font rendering issues.

## 2) Spynet Trial Flow Improvements

- Replaced legacy private trial patterns with Mellichae style bounty camp theater flow.
- Added reliable Quest tab waypoint restoration and stronger support for desync cases.
- Added migration for legacy characters stuck on pre theater trial data.
- Added fail safe handling for unresolved target OIDs and stale task states.
- Added additional diagnostics around trial lifecycle, waypoint grant failures, and camp teardown.

## 3) Chapter Gate And Bounty Integration

- Chapter gates now track terminal bounty progress with stronger synchronization.
- Removed the daily private contract cap to reduce progression stalls.
- Improved mission feedback so players understand why some bounty completions do not count toward Spynet.
- Added more explicit guidance on required BH specialization gates by chapter.

## 4) Rewards, Gear, And Balance

- Mandalorian custom armor progression was retuned by chapter and armor class.
- Clanbound armor resist profile and vulnerability settings were tuned for intended survivability.
- Added chapter gated Mandalorian armory weapons and recruiter schematic access.
- Weapon test pass standardized burst profile on the new armory ranged options.
- Chapter 5 path now routes through Jabba themepark badge completion for Mandalorian title grant.

## 5) Stability And Core Fixes Supporting The Arc

- Hardened several Lua and C plus plus integration points to reduce crashes from malformed table reads.
- Added guardrails so tracker or script side failures do not block mission completion cleanup.
- Improved travel and terminal edge case behavior that affected player flow around required activities.

## Current Player Experience (How It Plays Today)

1. A player starts with the Foundling track and follows recruiter or informant guidance.
2. After Foundling arc completion, chapter gates open through the Spynet operative path.
3. Each chapter requires specific BH preparation, then Spynet terminal progress, then a private trial.
4. Trials run through bounty camp theaters with Quest tab guidance and post trial chapter advance.
5. Chapter completion grants progression rewards and unlocks the next requirements.
6. Endgame progression currently routes Clanbound players to Jabba themepark before Mandalorian title completion.

## What We Are Doing Now (Player Facing Direction)

- Keeping progression friction low by continuing to harden waypoint and state recovery behavior.
- Keeping chapter guidance explicit so players can self service the next step.
- Continuing to tune reward pacing and chapter gate readability from in game feedback.
- Maintaining compatibility with client text and UI limitations to reduce confusion.

## Known Player Tips

- For Spynet bounty camp trials, check the datapad **Quest** tab for the active trial pin.
- If guidance appears stale after reconnect, revisit the relevant recruiter or operative to refresh support paths.
- Keep inventory space available around major chapter turn ins due to multi item reward grants.

## Source Notes

This overview is based on the tracked implementation history in `bellumgero_change_log.md` and current Mandalorian related scripts in the project.
