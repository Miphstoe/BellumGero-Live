# Foundling mission credit by planet

The active informant assignment stores its planet in
`MandoWayOfLife / foundling.currentPlanet`. Standard terminal missions count
only when their start planet and the owner's zone at completion both match
that assignment. Bounties remain excluded. Credit stops when the 24-mission
quota is complete, until the player returns to the informant and advances.

This changes C++ mission completion logic and requires rebuilding and restarting
the game server. Existing progress is preserved; previously miscredited missions
are not retroactively removed.

## Automated regression check

Run `python3 utils/validate_foundling_planet_credit.py` from `MMOCoreORB` with `g++`
available. The harness extracts and compiles the production quota block with
engine doubles, exercising all supported mission types across Tatooine, Talus,
and Endor; cross-planet origins/completions; missing planet/zone data; disabled
assignments; excluded types; duplicate completions; quota completion; and the
next assignment. It does not validate engine integration or Lua conversations.

## In-game verification

1. Accept an assignment from the informant on the current Foundling planet.
   Confirm the quota begins at 0/24 using `!foundling`.
2. Take and complete a standard terminal mission there. Confirm 1/24.
3. Travel elsewhere and take/complete a standard mission. Confirm its normal
   reward is granted, the planet restriction message appears, and the quota
   stays at 1/24.
4. Where the mission type allows it, try completing an off-planet mission after
   returning to the assigned planet. Confirm it does not count. Also verify a
   mission originating on the assigned planet does not count if completed away
   from it.
5. Finish 24 eligible local missions. Confirm the return waypoint and turn-in
   become available. Complete another mission before turn-in; quota stays 24/24.
6. Turn in and visit the next informant. Confirm counting stays disabled until
   accepting that assignment, which starts at 0/24. Missions from the previous
   planet must not count for the new assignment.
7. Repeat local and off-planet checks for Tatooine, Talus, and Endor. Relog during
   an active assignment and confirm its saved planet and progress still apply.
