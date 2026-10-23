# Combat audit — 23 October 2026

The deterministic combat suite passes **20 smoke checks and 567 regression checks**. A separate manual six-map audit passes **33 state/encounter checks**, including killing the final boss through phase 3. A subsequent starter trial wins both early maps with Cael and Lysenne alive, establishing access to general recruitment with two survivors. A successful complete campaign with survivor carryover has **not** been demonstrated. These are automated observations, not human playtesting or a claim of finished balance.

## Reproduce

From the repository root, with Godot 4.6.3 available:

```sh
XDG_DATA_HOME="$PWD/.runtime/data" \
XDG_CONFIG_HOME="$PWD/.runtime/config" \
XDG_CACHE_HOME="$PWD/.runtime/cache" \
godot --headless --path game --script res://tests/simulation_campaign_audit.gd
```

Append `-- --boss-only` to run the focused final-boss fixture. That fixture requires the boss to spawn, reach phase 3 and die without escaping. Append `-- --boss-only --guard-boss` to reproduce the earlier stationary-formation stall; that diagnostic is expected to fail its completion/boss assertions.

The audit is deliberately separate from `tools/run_checks.py`. Its ordinary map checks require a terminal victory/defeat without a simulation timeout, finite bounded state and valid survivor membership. They allow an observed defeat. Its final standalone fixture additionally requires an actual boss kill. The regular regression suite also completes a real four-wave first battle and verifies all 116 recruit abilities, all 18 enemy abilities, combat mechanics, editor transactions and JSON continuation.

## Conditions and policy

Source: `game/tests/simulation_campaign_audit.gd`. All placements, upgrades, removals, casts and movement orders use the shipped `command()` API. There are no free units, health refills, extra supplies, enemy deletions or altered damage values. Each map starts with its authored 300 supplies, 100 gate HP, normal difficulty, enemy HP multiplier 1.0 and deterministic RNG. Earned supplies fund later purchases. Times below include eight seconds of planning after each completed nonfinal wave, up to 24 seconds per completed map.

The fixture uses these roster definitions:

| Roster | Members, in placement order |
|---|---|
| P2 | BAR01 Tornel Ashhand; BAR03 Orok Vell |
| P4 | P2; GEN01 General Veyra of the Pale Wing; GEN03 General Kharu Redtusk |
| P7 | P4; CAP01 Ilyra Valecrest; CAP04 Neme Solenne; CAP07 Orel Brasshaven |
| R5 | CAP01; CAP04; CAP07; CAP03; CAP08, the five recovery recruits after losses |

Placement cells are zero-based tile coordinates. Living units receive Guard orders and these cells in roster order:

- Most maps: `(22,9), (21,10), (22,10), (23,11), (21,11), (23,9), (24,10), (24,11), (20,10), (20,11)`.
- MAP02: `(27,10), (26,11), (26,10), (27,11), (25,10), (25,11), (28,10), (28,11), (24,10), (24,11)`.

At each planning phase the script salvages destroyed towers and spent traps, attempts one Hearthward and then buys Bolt Cradles on marked pads in descending x order until five towers are present or supplies run out. It upgrades existing towers when all five pads are filled or a tower is below half health, paying 65/95 supplies for stages 2/3. Remaining supplies buy individual Snare traps, following rounded enemy-track segments between x=12 and x=27 in descending x order. Rejected or unaffordable edits are left rejected by the engine.

| Map | Hearthward cell |
|---|---|
| MAP01 | `(20,7)` |
| MAP02 | `(22,15)` |
| MAP03 | `(21,7)` |
| MAP04 | `(23,7)` |
| MAP05 | `(22,7)` |
| MAP06 | `(21,6)` |

The cast policy holds damage/taunt abilities until a hostile is within the explicit effect range/radius. It holds shields/buffs/intercepts until a hostile is within `max(2.5, basic attack range)` and heals until a living ally below 80% HP is within the effect radius. It uses each available slot when this policy permits. When BOSS01 appears, it issues a live Advance order to every living ally so surviving melee units close the distance. It does not dodge individual boss telegraphs or optimize ability combinations.

## Actual survivor-carryover route

These maps use the survivors of the preceding battle. Generals are added only after a MAP02 win. Following the observed losses, five capital recruits are added before MAP04; dead allies are never restored. An empty party can continue by buying Bolt Cradles. The fixture isolates combat/recruitment counts and does not automate the full dialogue UI or story rewards.

| Map | Starting roster | Result | Wave | Gate | Elapsed | Survivors |
|---|---|---|---:|---:|---:|---|
| MAP01 Hinge Gate | P2 | Victory | 4 | 100 | 206.8s | BAR01, BAR03 |
| MAP02 Lantern Ford | P2 | Defeat | 4 | 0 | 294.7s | None |
| MAP03 Five-Banner Breach | None | Defeat | 2 | 0 | 132.6s | None |
| MAP04 The Return Road | R5 | Defeat | 1 | 0 | 74.3s | CAP01 |
| MAP05 Crownroot Court | CAP01 | Defeat | 1 | 0 | 83.5s | None |
| MAP06 The Uncrowned Threshold | None | Defeat | 1 | 0 | 63.8s | None |

This policy completes the loss route without script exceptions. It does not establish that the intended two-to-four-to-seven-ally victory route is accessible or balanced. Fixed placement by roster index is especially weak when a loss changes the party's class distribution.

## Independent late-map fixtures

Each row below starts a fresh instance with the stated full roster. It does **not** inherit the previous row's casualties. These fixtures test late-map combat feasibility independently of the unsuccessful continuous run.

| Map | Roster | Result | Gate | Kills / surrenders | Elapsed | Survivors |
|---|---|---|---:|---|---:|---|
| MAP03 | P4 | Victory | 96 | 118 / 10 | 333.6s | BAR01, GEN03 |
| MAP04 | P7 | Victory | 40 | 133 / 12 | 377.5s | GEN03, CAP01, CAP04 |
| MAP05 | P7 | Victory | 96 | 120 / 12 | 333.4s | All seven |
| MAP06 | P7 | Victory | 70 | 127 / 12 | 411.7s | BAR01, GEN01, CAP04, CAP07 |

The final fixture observed `boss_spawned=true`, `boss_max_phase=3`, `boss_min_hp=0`, `boss_defeated=true` and `boss_escaped=false`. Gate survival alone does not prove a boss kill, so those are separate assertions. The final audit reported `SIMULATION CAMPAIGN AUDIT: 33 passed, 0 failed`; individual maps took approximately 0.48–5.74 seconds of wall time in this cloud environment, without runtime exceptions.

Earlier policies exposed tactical sensitivity: firing every ability immediately wasted cooldowns before engagement and lost MAP05/MAP06 before the final wave. Holding Guard for the entire boss fight reached phase 2 at approximately 930 HP but stalled until the 1,000-second limit. Issuing the available Advance order resolved that fixture. No engine balance values were changed to obtain these outcomes.

## Story reward regressions

Gate capacity now has a separate `gate_max_hp`, normally 100 and bounded to 100–200. Tests demonstrate a 115-HP gate surviving 104 actual leakage damage at 11 HP, preserving current and maximum HP through JSON, rejecting malformed values and loading older saves without the new field.

The fourth `setup()` argument is an enemy HP multiplier, independent of the third argument's swarm difficulty. Tests verify a 0.92 multiplier lowers all nine enemy models' current/max HP by exactly 8% without changing the spawn queue, persists for future spawns after saving and defaults to 1.0 for older saves. Existing saved actors are not scaled twice.

Further work needs human assessment of recruitment choices, both early battles, casualty recovery, boss readability and campaign pacing across complete runs. These tests establish concrete mechanics and selected encounter feasibility; they do not establish that all 58 recruits, every composition or every story route has equivalent difficulty.

## Verified starter route to general recruitment

A bounded follow-up investigated the early-map difficulty without changing simulation data, starting supplies, health or damage. The original Snare/late-Guard policy lost MAP02 with all 15 Bar pairs and the sampled Kingdom pairs. That observation reflects this policy, not a proof that those characters cannot win.

The following Kingdom pair **wins MAP01 and then MAP02 with both starters surviving**:

- **KIN02 Cael Sunmere — DPS**.
- **KIN01 Sister Lysenne Vale — Healer**.

| Map | Gate | Elapsed, including planning | Kills / surrenders | Actual survivors |
|---|---:|---:|---|---|
| MAP01 | 100 | 202.8s | 82 / 6 | KIN02, KIN01 |
| MAP02 | 100 | 281.7s | 100 / 9 | KIN02, KIN01 |

MAP02 uses the actual two survivors from MAP01, in that order. Setup resets their health for the new map as the shipping campaign does. Both maps use normal difficulty, 100 gate HP and no story rewards. MAP02 victory ended with 219 earned supplies unspent. The two surviving starters can now recruit two generals through the normal campaign branch; this trial does not continue those four allies through all later maps.

The successful policy uses the same cast timing, eight-second planning waits, legal pad purchasing and upgrade rules described above, with these specific adjustments:

1. Recruit Cael first and Lysenne second. On MAP01, Guard at `(22,9)` and `(21,10)` respectively, retaining the usual Hearthward at `(20,7)`.
2. On MAP02, Guard Cael at `(20,10)` and Lysenne at `(21,11)`. This gives them time to attack near the tower-supported lanes rather than waiting beside the final gate.
3. On MAP02 buy **Bolt Cradles on all available pads**, skipping the Hearthward. The descending-x pad order is `(22,15), (20,6), (13,6), (9,16), (7,5)`. Buy what the current supplies allow, add more between waves, and then upgrade under the existing rules. Lysenne supplies the party's healing.
4. Use **Cinder Pots, costing 16 supplies each**, instead of Snare traps on both maps. Remaining supplies place pots on the same rounded enemy-track cells between x=12 and x=27, in descending x order. Their visible fuse and bounded area damage remain unchanged.

This ran from an ignored temporary copy of the manual audit (`.runtime/kingdom_forward_allbolt.gd`, log `.runtime/kingdom-forward-allbolt.log`). The copy changes only the starter IDs, MAP02 formation, MAP02 tower purchasing and `TRAP01`/12-supply threshold to `TRAP02`/16. Shipping source and the earlier 33-check fixture were left frozen.

A second observed route, Bar recruits **Tornel + Maela**, wins MAP01 at 100 gate HP and MAP02 at 63 gate HP using Cinder Pots, but both allies fall before the second victory. It establishes access to the generals through a costly win; the Kingdom route above is the verified option for preserving both starters.
