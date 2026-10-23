# Playing Belde — The Wrong Commander

Belde is a story-driven tower-defense campaign about a commander who receives the wrong royal orders and must decide whose lives those orders are worth. The desktop game owns combat and saves. The optional Chrome editor changes the same battlefield through the paired local bridge.

## Start a company

Choose the Bent Lantern bar, the Crownward Yard, or Reedwake village. Their recruitment pools contain six, fifteen, and ten adults respectively. Inspect a recruit's portrait, class, HP, basic attack, and two signature abilities, then choose exactly two. Training and social standing change their stories and equipment; origin is not a hidden power tier.

The game contains all 58 recruit records: 31 initial candidates, ten capital mercenaries, twelve prison volunteers, and five monster generals. A single run recruits only a small company from that roster.

## Prepare a defense

The battlefield uses a 32-by-20 tile grid. Ochre roads and enemy arrows show the invasion routes; cyan dotted tracks show allied patrols. Inspect the actual route overlay before placing defenses. You cannot place a tower on an enemy road, overlap occupied structures, or place objects outside the map.

Select a tower or trap in the palette and click a legal cell, or drag it onto the battlefield. A placement preview explains rejected positions. Drag a party icon to deploy its recruit; drag an existing ally to reposition them between waves. Select a unit to see its range, mode, health, and two cooldowns. Author connected patrol routes with the track tool.

Each map begins with 300 crowns before story modifiers. Towers cost 55 for the Palisade Roost, 45 for the Waybell Beacon, 65 for the Hearthward, and 80 for the Bolt Cradle. The three traps cost 12, 16, and 14. Tower upgrades cost 65 and then 95; three is the highest level. Defeated ordinary enemies grant four crowns, surrender grants three, and completed waves bring additional supplies. A company with no surviving combatants receives emergency tower supplies and can still continue.

The four tower families serve different jobs:

- **Palisade Roost:** protects a ranged occupant from projectile damage. Cover reduces incoming projectile damage by 25%, while basic ranged accuracy becomes 85% instead of the ground baseline of 100%. Healing and trap abilities gain no bonus; melee recruits cannot occupy ranged sockets.
- **Waybell Beacon:** reveals and marks nearby enemies. Upgrades extend its support radius.
- **Hearthward:** heals one wounded ally with a finite healing reserve. It works faster between waves and cannot provide unlimited free recovery.
- **Bolt Cradle:** fires slow, visible anti-siege bolts. It has a minimum range, so do not place it directly against the enemy lane.

Snare Stitch slows a single enemy, Cinder Pot bursts after a visible fuse, and Decoy Standard diverts a limited group of light enemies. Bosses resist ordinary taunts and hard control.

## Move, fight, and cast

**Guard** keeps a unit near its placement point. **Patrol** follows allied waypoints while tracking and attacking targets. **Advance** approaches enemies and engages. Moving units continue to attack; enemy and allied route markings remain distinct.

Healers prioritize wounded allies, especially Tankers and DPS when need is equal. DPS recruits supply the strongest basic attacks. Tankers protect the line with shields, interception, and threat control. Strategists place visible traps or decoys and retreat from close pressure. Every recruit has two named abilities with individual cooldowns and finite target budgets. Effects such as healing ticks, shields, slowing fields, short roots, and attack-speed boosts have separate timers rather than resetting one another indefinitely.

Select an ally and press **1** or **2**, or use its ability buttons. Watch the windup, range, and target state. A downed recruit cannot heal back into the fight during that battle. A later story rescue can recover one recently downed ally; otherwise casualties remain absent from the company and epilogue.

White surrender cloths and open hands identify nonhostile monsters. Your defenders do not target surrendered enemies or noncombatants. The enemy army includes many weak attackers, specialist support creatures, heavy siege bodies, and Avarren's clearly telegraphed final attacks. Break his oath anchors and move out of marked root strikes.

## Campaign branches

1. **The Wrong Commander:** recruit two allies and defend Hinge Gate.
2. **Friends and Monsters:** hold Lantern Ford and decide how to answer surrender. Victory opens a choice of two of the five generals; defeat skips their alliance. You can also decline the offered alliance.
3. **The Price of Victory:** choose between a missing ally and endangered families, then face the siege at Five-Banner Breach.
4. **The Choosing:** visit capital and prison recruitment. You receive five new places after a defeat or when at most one original ally remains; otherwise you receive three. Surviving generals remain part of the company. The roster supports the nine-person recovery case without silently dropping an ally. You may defend the escort road or take a shortcut. Escort victory adds 75 crowns to the next defense; the shortcut avoids the optional battle's risk and time.
5. **The Last Stand:** defend Crownroot Court, face Avarren at the Uncrowned Threshold, and choose forgiveness with reparations or refusal of pardon and a public hearing. A final defeat offers another rally or an evacuation ending instead of a progression lock.

Story choices change resources, rescue outcomes, available allies, and the final title. The title system draws from 2,000 authored candidate combinations and filters parts by actual choices: a merciful epithet requires mercy and pardon, road honors require the escort, and survivor portraits reflect the company that reached the ending. This is not a promise of thousands of separately painted ending scenes.

Normal speed is intended for the campaign's roughly half-hour pace; recruitment time, optional battles, losses, pauses, and chosen speed can change the duration. Numbers are implemented starting budgets with scenario checks. They have not undergone a large human balance playtest.

## Controls

| Action | Control |
| --- | --- |
| Place a tower or trap | Click a palette item then the grid, or drag the item onto the grid |
| Deploy or reposition an ally | Drag a party icon or existing unit to a valid cell |
| Inspect a unit | Click it |
| Change behavior | Guard, Patrol, or Advance buttons |
| Cast selected unit's abilities | **1** / **2**, or ability buttons |
| Begin the next wave | **Space**, or the next-wave button |
| Pause during combat | **Space** or pause button |
| Open pause menu / cancel a tool | **Esc** |
| Toggle grid | **G** |
| Toggle routes | **R** |
| Save | **F5** or save button |
| Undo / redo a planning edit | **Ctrl+Z** / **Ctrl+Shift+Z** |
| Upgrade selected tower | **U** or upgrade button |
| Change game speed | Cycle the **1× / 2× / 3×** speed control |
| Draw a patrol track | Choose track tool, then click-drag a connected path |

## Save and continue

The desktop game writes a version-two campaign save and backup in its user-data folder. Saves retain the campaign, surviving and fallen recruits, actual battle state, layout, settings, and pending editor changes. Invalid versions and malformed rosters are rejected instead of silently substituting different allies. Keep the application and its `.pck` file together when using an exported build.

## Paired editor

Start the game, install the native-messaging bridge and unpacked Chrome extension as described in the installation guide, then pair with the code shown by the game. The popup handles quick actions; the full editor gives more room for maps and history. The game validates every placement and remains authoritative.

Planning edits can be applied immediately. During combat, layout edits wait for a safe planning phase; the editor displays pending or rejected changes rather than pretending they already affected battle. A stale layout revision requires refreshing the editor state. Undo and redo use the same validation and economy as mouse placement.

One local PC gameplay process and one authorized editor session form a connected pair. A second editor is rejected, and heartbeat expiry releases a disconnected editor. Cross-device enforcement requires the optional profile coordinator to be configured; local pairing by itself does not discover another computer's game.
