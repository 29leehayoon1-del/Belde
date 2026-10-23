# BELDE — The Wrong Commander: world, animation and interface models

Visual preproduction only. This package describes intended art and readable behavior; it does not implement the PC game, browser extension, synchronization, or combat. Statistics are starting targets, not playtested balance. Generated reference sheets still require frame-by-frame production cleanup.

## Art direction

A warm, weathered dark fairytale: coal navy skies, parchment faces and labels, copper hardware, teal ally light, amber danger. Every monster species includes individuals who can surrender or simply need passage. Show intent through posture and badges, never through species alone. Native 32px tiles and 64px actor cells use hard pixel clusters; no blur, antialiased painted edges, or noisy texture. Terrain is quieter than units, units quieter than telegraphs.

| Role | Shape | Motion language |
| --- | --- | --- |
| Healer | Rounded cross and leaf fan | Gather inward, open palms, rising arcs |
| DPS | Double chevron | Narrow anticipation, fast contact, clean recovery |
| Tanker | Square shield | Heavy planted contacts, broad silhouette |
| Strategist | Amber hexagonal marker | Low placement crouch, thread/marker, retreat |

Palette: ink `#151b2b`, night `#252b43`, slate `#4f5c73`, fog `#a8b5bd`, parchment `#eee0b7`, cream `#fff1cf`, wood `#60433b`, rust `#a15b46`, copper `#d99855`, gold `#f4c86b`, moss `#4a6456`, leaf `#83a970`, teal `#4ca6a8`, ice `#9be1dc`, threat `#ba4f61`, warning `#f39c64`, corruption `#744d91`.

## Animation production contract

Canonical actor canvas **64×64px**, ordinary ink box **32×48px**, fixed foot pivot **(32,56)**. Ground shadow remains a separate layer. Eight directions in sheet row order: **S, SW, W, NW, N, NE, E, SE**. One action per sheet; columns are ordered frames. Names use `actor_id/action/direction/frame_001`. Frame numbers below are one-based. Asymmetric weapons and handedness need authored corrections; mirrored blockouts are not final assets.

Portraits are **96×96px**, eye line y35, face readable at half size. Large enemies use96×96px,pivot(48,84). Boss uses **160×160px**, foot pivot **(80,136)**, separate160/320px VFX. Healthbars, labels, ranges, telegraphs and target circles are never baked into body art.

| Action | Frames | FPS | Duration per frame (ms) | Motion / event |
| --- | ---: | ---: | --- | --- |
| idle | 4 | 6 | 166.667 | One-pixel breath across four poses; planted foot fixed; equipment lags one frame. |
| walk | 6 | 10 | 100.0 | Contacts 1/4, passing poses 3/6; one-pixel vertical bob; small opposed arm arc. |
| run | 8 | 14 | 71.429 | Contacts 1/5, airborne 3/7; lean three pixels; two-pixel bob; dust only on contact. |
| basic_attack | 6 | 12 | 83.333 | Attack-specific silhouette; release/contact frame4; no hit before readable windup. |
| ability_a | 8 | 12 | 83.333 | Distinct class-shaped anticipatory glyph; release frame 4; body and VFX separate; enemy/boss long windup uses stretched tell frames. |
| ability_b | 8 | 12 | 83.333 | Distinct class-shaped anticipatory glyph; release frame 4; body and VFX separate; enemy/boss long windup uses stretched tell frames. |
| hit | 3 | 12 | 83.333 | One-pixel recoil, warm rim then return; avoid sustained flicker. |
| downed | 6 | 10 | 100.0 | Weapon drops away from silhouette; kneel to side-lie; static breathing end pose with rescue icon. |
| surrender | 4 | 8 | 125.0 | Lower weapon, open both hands, raise parchment cloth, settle; endpoint loops breathing. |
| noncombatant | 4 | 6 | 166.667 | Bundle or child-sized companion silhouette; open hands; no combat equipment or target ring. |
| portrait | 4 | 4 | 250.0 | Optional blink and tiny shoulder breath only; first frame is the static recruitment snapshot. |
| celebrate | 6 | 8 | 125.0 | Personal gesture, not a shared weapon lift; used only after safe wave completion. |

Basic attack: anticipation frames1–3,contact/release4,recovery5–6. Both abilities: tell1–3,release4,active4–5,recovery6–8. Enemy/boss ability durations deliberately stretch the tell/recovery poses while preserving the release event; individual windups below override the baseclip timing. The visual release event must match actual future hit timing. Projectiles, contact flashes, trails, ground decals and body motion are separate exports.

Walk contacts are frames1/4,passing3/6. Run contacts1/5,airborne3/7. Root motion stays out of art; moving foot contacts are checked later at 60/80px/s. Two-pixel body bob maximum prevents bouncing faces. Patrol attacks need separate upper/lower body layers; keep the planted foot rather than restarting walk on every shot.

Layer order: shadow → ground telegraph → rear weapon/cape → body → front weapon → ability effect → status icon. Contact flash at most two frames. Avoid strobe; reduced motion replaces shake with a quiet border pulse. RGBA sRGB at native1x, nearest-neighbour presentation, transparent backgrounds. Final atlas data records duration, pivot, release frame and attachment points.

## Enemy model index

Eight ordinary species plus Avarren. Use the shared idle/walk/run/attack/hit/downed contract and the species-specific details below. Surrender is a full four-frame weapon-lowering gesture followed by an open-hand parchment badge; it cancels hostile tells. Noncombatants never display a red target ring.

### MOB01 — Bramble Nib

**Role:** numerous light melee. **Draft:** 30 HP, 4 damage every 1.2s, 0.9 tiles/s.

Small stooped seedfolk in acorn caps, twig spears and oversized copper buttons. Three-point cap silhouette; exposed pale seed face.

**Walk:** Six-frame heel-toe waddle; cap lags one frame. **Run:** Short bounding hop-run; spear points back.

**Basic attack:** Thin twig poke; pale seed-shaped contact fleck. **Tell:** Spear lifts above cap; tiny serrated floor triangle. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Bright frightened seed eyes; one patched cap edge.

- **Burr Rush — 12s cooldown.** Tell: Three leaf-arrow marks ahead. Windup 0.65s. Active: Rush up to2tiles along the marked corridor. Recovery 0.5s. VFX: Three low amber leaf streaks; no screen shake. Target effect: Six damage to the first collision target only, once per rush.
- **Seed Shelter — 18s cooldown.** Tell: Cap shuts and square bark outline appears. Windup 0.8s. Active: Stationary shell lasts2s. Recovery 0.6s. VFX: Matte bark plates build from feet outward. Target effect: 35% damage reduction; cannot move/attack during shelter.

**Surrender:** Spear laid sideways; both tiny hands raised. Acorn cap no longer bobs aggressively. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB02 — Wickling

**Role:** fast fragile runner. **Draft:** 22 HP, 3 damage every 1.0s, 1.35 tiles/s.

Wax-bodied lantern spirits with booted wick-feet and a glass-cage backpack. Teardrop face and tiny blue flame crest.

**Walk:** Pendulum lantern swing; tiny alternating boot contacts. **Run:** Elongated flame backward; fast scissor step.

**Basic attack:** Warm spark spat in a short lob; clear falling arc. **Tell:** Lantern shutter opens and a hollow diamond marks target. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Glass chimney reflection; timid ember expression.

- **Lantern Skip — 14s cooldown.** Tell: Two dotted step circles show destination. Windup 0.7s. Active: Dash1.5tiles; destination remains visible. Recovery 0.45s. VFX: Separated teal afterimages, max3. Target effect: Cannot pass structures; avoids first projectile during dash, not invulnerable afterward.
- **Dim Veil — 22s cooldown.** Tell: Lantern lowered and grey dotted ring spreads. Windup 0.8s. Active: 2tile mist for2s. Recovery 0.7s. VFX: Low transparent grey scallops, silhouette remains visible. Target effect: At most three nearby hostile allies gain 10% evasion for 2s within two tiles. Select nearest first; identical veils do not stack or refresh one another. Does not obscure the map or surrender badges.

**Surrender:** Closes lantern shutter and carries it in both hands; flame shrinks to a calm dot. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB03 — Mireback

**Role:** slow shielded escort. **Draft:** 90 HP, 8 damage every 1.6s, 0.5 tiles/s.

Broad amphibian porter with a reed-basket shell, flat face and wooden lid shield. Two stubby legs support a trapezoid body.

**Walk:** Heavy left/right weight shift; basket settles after each step. **Run:** Urgent squat shuffle, never a weightless sprint.

**Basic attack:** Wooden lid shove with broad rectangular dust impact. **Tell:** Lid turns edge-on; rectangular impact zone marks adjacent tile. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Gentle broad eyes, one reed tucked behind ear.

- **Reed Bulwark — 20s cooldown.** Tell: Reed squares knit over front arc. Windup 0.9s. Active: Front-facing protection lasts3s. Recovery 0.6s. VFX: Three large reeds and a square rim; rear stays exposed. Target effect: 40% front damage reduction;10% back vulnerability.
- **Muddy Footing — 16s cooldown.** Tell: One broken-outline tile turns umber. Windup 0.8s. Active: Mud persists4s on one tile. Recovery 0.6s. VFX: Low opaque edge, clear center; no giant splash. Target effect: The one-tile field can slow at most six distinct mobile actors by 20% during its 4s lifetime, regardless of side; each target is affected once, for at most 2s. Towers unaffected; identical slows do not stack.

**Surrender:** Lid set down like a table, palms up. Basket revealed to contain blankets. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB04 — Ashwing Scout

**Role:** flying flanker. **Draft:** 38 HP, 5 damage every 1.1s, 1.1 tiles/s.

Soot-grey moth person with triangular cloak-wings and cream face mask; legs remain visible when perched.

**Walk:** Low hover uses eight beat poses and shadow at true tile. **Run:** Two compact fast beats then glide; no vertical teleport.

**Basic attack:** Needle gust directed along a thin fan-shaped cone. **Tell:** Wings spread into large V and cone border fills from source. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Large amber moth eyes and stitched cream mask; no monstrous teeth.

- **Cinder Fan — 16s cooldown.** Tell: Narrow three-ray cone, dotted interior. Windup 0.85s. Active: One gust reaches3tiles. Recovery 0.65s. VFX: Pale tapered wind slivers, amber tips. Target effect: Seven damage to at most three targets, maximum 21 total damage per cast; ground shadows always show actual position.
- **Perch Feint — 21s cooldown.** Tell: Parchment feather points to intended perch. Windup 0.8s. Active: Land on route-side marker for1.5s. Recovery 0.5s. VFX: Small feather arc, never crosses a wall. Target effect: Next basic attack gains1range; landing exposes scout to ground melee.

**Surrender:** Lands, folds wings down, holds needle flat in both hands. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB05 — Bellbone

**Role:** support summoner. **Draft:** 52 HP, 3 damage every 1.4s, 0.65 tiles/s.

Adult bone spirit wrapped in a mossy shawl, carrying a little handbell and satchel. Oval skull, rounded shawl, long thin legs.

**Walk:** Careful ankle roll; bell held still to avoid accidental sound. **Run:** Long low strides; shawl trails but feet stay visible.

**Basic attack:** Bell pulse drawn as one expanding broken ring. **Tell:** Bell raised to eye line; dotted ring shows support radius. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Warm hollow eye lights and a hand-sewn shawl clasp.

- **Kindred Chime — 18s cooldown.** Tell: Three small cross-shaped notes over allies. Windup 1.0s. Active: Pulse heals up to3nearby hostile allies. Recovery 0.8s. VFX: Parchment cross-notes and soft teal rim. Target effect: Restore 12 HP each to at most three nearby hostile allies, maximum 36 healing per cast. Select lowest percentage HP first; cannot overheal; bell can be interrupted.
- **Gather the Lost — 26s cooldown.** Tell: Empty ground circle with small footprint glyph. Windup 1.25s. Active: One Bramble Nib joins at a marked route entry. Recovery 0.9s. VFX: Leaf fragments draw inward into existing silhouette. Target effect: One Bramble Nib per cast, at most two reinforcements per Bellbone per wave; never conjures inside defenses.

**Surrender:** Bell placed on ground; hands crossed on chest; summons immediately stop. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB06 — Quarry Horn

**Role:** heavy siege bruiser. **Draft:** 180 HP, 12 damage every 1.8s, 0.42 tiles/s.

Stone-skinned horned laborer with a mining apron and short blunt pick. Broad triangular torso, asymmetric chipped horn, enormous hands.

**Walk:** Four weight shifts over six frames; shoulders counter-rotate. **Run:** Slow charging jog with visibly planted heavy feet.

**Basic attack:** Pick strikes down; stone chips point out from contact tile. **Tell:** Pick raised overhead for0.9s; square impact tile flashes amber edge. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Work-worn eyes and dust mask around neck, not a demon snarl.

- **Fault Stamp — 22s cooldown.** Tell: Two adjacent tiles outlined with cracked squares. Windup 1.15s. Active: Ground pulse hits the two marked tiles. Recovery 1.0s. VFX: One low jagged ring and chips, no random screen debris. Target effect: Fourteen damage and 0.5s stagger to at most four distinct targets across both marked tiles, maximum 56 total damage per cast. Each target can be hit only once; tiles can be vacated.
- **Carry the Line — 28s cooldown.** Tell: Stone arms form a shield above a wounded ally. Windup 1.1s. Active: Escort one nearby ally for3s. Recovery 0.8s. VFX: Square stone halo connects two ground circles. Target effect: Redirect 25% of one nearby hostile ally’s damage to self for 3s; one target, cannot combine with other redirection and cannot redirect redirected damage.

**Surrender:** Pick flat on floor; kneels and opens huge hands. Chipped horn catches warm light. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB07 — Thistle Knitter

**Role:** trap engineer. **Draft:** 48 HP, 5 damage every 1.2s, 0.75 tiles/s.

Spiny hedgehog artisan in a tool belt, carrying spool and hooked needle. Rounded back spikes, narrow booted feet.

**Walk:** Spool bounces opposite lead leg; needle kept low. **Run:** Quick forward lean, spines compress into a clean wedge.

**Basic attack:** Hooked needle jab, tiny diamond impact flecks. **Tell:** Spool spins; diamond tile cursor becomes striped. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Mismatched spectacles and earnest brow.

- **Briar Stitch — 15s cooldown.** Tell: Diamond trap outline remains visible for0.8s. Windup 0.8s. Active: One trap arms after1s and lasts6s. Recovery 0.6s. VFX: Four corner thorns and central diamond, no hidden hazard. Target effect: First mobile ally crossing takes four damage and 30% slow for 1.5s; exactly one target and one trigger. At most two live traps per Thistle Knitter; new placement replaces the oldest.
- **Unravel — 24s cooldown.** Tell: Scissor glyph on one friendly placed trap. Windup 1.0s. Active: Disables a nearby trap for3s. Recovery 0.7s. VFX: Copper thread line snaps outward. Target effect: Disable one placed player trap for 3s. Cannot remove built towers; disabled trap returns with a clear countdown. Same target cannot be disabled again until it has been active for 3s.

**Surrender:** Needle and spool hung on belt, paws raised; traps disarm with fading diamonds. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### MOB08 — Hollow Courier

**Role:** ranged skirmisher. **Draft:** 44 HP, 7 damage every 1.4s, 0.85 tiles/s.

Hare-like masked messenger in a long split coat with a short sling and sealed satchel. Long ears and distinct split-coat silhouette.

**Walk:** Springy heel-toe steps; satchel lag. **Run:** Forward ears stream back; split coat makes two clear tails.

**Basic attack:** Sling rotates twice then releases a single glowing pebble. **Tell:** Sling circle and a thin dotted parabola identify the targeted area. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** One Folded ear and ink on the mask edge.

- **Echo Stone — 17s cooldown.** Tell: Target tile shows concentric broken circles. Windup 0.9s. Active: Pebble lands after0.5s flight. Recovery 0.65s. VFX: Pale cyan arc and double-ring contact. Target effect: Eight damage to at most three targets in a 0.65-tile radius, maximum 24 total damage per cast; destination stays marked during flight.
- **False Trail — 23s cooldown.** Tell: Three footprints blink toward a safe lane-side tile. Windup 0.75s. Active: Retreat1tile and drop an obvious paper decoy. Recovery 0.55s. VFX: Parchment silhouette with dotted edge, no false healthbar. Target effect: One paper decoy can absorb one nonpiercing projectile for 2s; at most one live decoy per Courier. Cannot capture or rescue objectives.

**Surrender:** Sling tied closed; presents sealed letter and empty hand. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

### BOSS01 — Avarren, the Uncrowned

**Role:** demon king / final negotiable adversary. **Draft:** 2400 HP, 18 damage every 1.6s, 0.4 tiles/s.

Tall antler-crowned monarch with a cracked obsidian mantle, soft exposed face and luminous root-veins. Crown is broken and off-center; four-finger open hands.160pxcanvas.

**Walk:** Deliberate planted steps; mantle opens after foot contact. **Run:** Low urgent stride only in exposed third phase; no jump cuts.

**Basic attack:** Open palm sweeps a clearly marked2tile arc; copper splinters dissolve on contact. **Tell:** Palm turns outward, crown gutters teal, floor arc fills for1s. Windup frames1–3; release4; recovery5–6.

**Idle/hit/downed:** Breathing and species-specific accessory follow-through; four-frame shared contract. Use the three-frame shared recoil; preserve species silhouette. Collapse without gore; rescue/capture badge distinguishes from permanent loss.

**Portrait:** Weathered adult face, tired amber eyes; monster and human motifs woven together.

- **Crown of Roads — 16s cooldown.** Tell: Three route segments display alternating serrated amber outlines. Windup 1.4s. Active: Successive roots strike each marked segment0.5s apart. Recovery 1.2s. VFX: Three large roots travel visibly from boss; break into copper leaves. Target effect: Eighteen damage to at most six distinct targets across all three segments, maximum 108 total damage per cast. Each target can be hit only once per cast. Never marks every escape route; a safe lane is always visible.
- **Unkept Oath — 28s cooldown.** Tell: Mantle folds inward; square shield rim and two breakable anchors appear. Windup 1.8s. Active: Two anchors feed a shield for6s. Recovery 1.5s. VFX: Teal threads connect boss and anchors; shield becomes a visible cracked shell. Target effect: One shield absorbs at most 120 damage; at most two anchors exist. Destroying either anchor breaks the shield and exposes the boss for 3s. Recasting replaces existing anchors rather than stacking them.

**Surrender:** Crown set on ground; open palm and lowered antlers; all arena telegraphs dissolve from outside inward. **Noncombatant:** Weapon stowed, open-hand parchment badge, no red target outline. Some members arrive carrying provisions or wounded companions; hostility is never inferred from species.

Boss phases: 100–70% crown amber/closed mantle; 70–35% crown teal/open mantle and anchors; below 35% crown breaks and face warms. Existing tells can shorten by at most15%; no untelegraphed phase-transition damage. Always leave one safe road. BossHP assumes6–8 endgame units and remains unvalidated.

## Six battle maps

Each plan uses a **32×20 tile grid**, 32px/tile, native field1024×640; a640×360gameplayviewport pans over it and presents at1280×720(2x). The overview is a composition reference, not a runtime fit-to-screen promise. Coordinates are tile centers, x right/y down. Enemy paths are ochre earth with hollow red chevrons and pale broken edges; ally patrols use cyan dashed double rails and round waypoint loops. Ordinary crossings are never implied by decoration. The one MAP03 crossing is an explicit raised footbridge, with different elevation and no shared junction. Routing and collision still require validation during a later implementation phase.

Tower pads do not block enemy routes. Ground=0, platforms=1, roofs=2; a parchment lip and shadow signal elevation. Ranged shelter trades 25% incoming-projectile protection for 85% accuracy instead of the ground baseline of 100%; range, damage and attack interval do not change. Place no foreground props over feet or telegraphs.

### MAP01 — Hinge Gate (Act I)

Old gatehouse with two readable orchard lanes; a broken wrong-commander banner lies in foreground.

**Light:** Dawn / copper rim light. **Goal:** Defend gate while learning recruitment, placement and two allies.

- Enemy `enemy-main`: (1, 8) → (9, 8) → (15, 10) → (24, 10) → (29, 10).
- Enemy `enemy-branch`: (1, 14) → (9, 14) → (15, 10).
- Ally `patrol-north`: (5, 5) → (12, 5) → (20, 5) → (26, 5).
- Ally `patrol-south`: (4, 17) → (12, 17) → (20, 17) → (27, 17).
- Tower pad centers: (8, 6), (14, 6), (20, 7), (23, 13), (12, 15).
- Objectives: Main gate at (29,10), HP 100; lose when HP reaches 0, triggering the recovery branch.

Training straw figures at lower safe edge; all active lanes remain brighter than decorative paths.

### MAP02 — Lantern Ford (Act II)

Two river channels split around a low sanctuary island; surrendered monsters gather near the shallow ford.

**Light:** Overcast blue / warm lantern islands. **Goal:** Survive many weak enemies and protect a marked negotiation circle.

- Enemy `enemy-main`: (1, 7) → (8, 7) → (13, 9) → (21, 9) → (29, 10).
- Enemy `enemy-branch`: (1, 14) → (9, 14) → (16, 12) → (24, 12) → (29, 10).
- Ally `patrol-north`: (4, 4) → (11, 4) → (18, 4) → (26, 4).
- Ally `patrol-south`: (4, 17) → (11, 17) → (20, 17) → (27, 17).
- Tower pad centers: (7, 5), (13, 6), (20, 6), (9, 16), (22, 15).
- Objectives: Negotiation sanctuary at(16,10), gate(29,10); surrendered units use a protected off-lane route.

Water darkens outside walkable banks; reeds never conceal telegraphs.

### MAP03 — Five-Banner Breach (Act III)

A ruined aqueduct frames three converging invasion fronts and two rescue enclosures.

**Light:** Storm grey / ember rescue beacons. **Goal:** Choose which rescue gets support; withstand major siege; if won choose2of5generals.

- Enemy `enemy-main`: (1, 8) → (10, 8) → (17, 10) → (25, 10) → (29, 10).
- Enemy `enemy-branch`: (1, 14) → (10, 14) → (17, 10).
- Enemy `enemy-north`: (6, 1) → (6, 5) → (10, 8).
- Ally `patrol-north`: (3, 4) → (10, 4) → (18, 4) → (26, 4).
- Ally `patrol-south`: (4, 18) → (12, 18) → (20, 18) → (27, 18).
- Tower pad centers: (8, 6), (14, 6), (21, 7), (9, 16), (22, 16).
- Objectives: Rescue lanterns at(12,5)/(21,17); gate(29,10). Both saving paths cost attention, never require sacrificing a named ally.

Third lane enters at(6,1)and joins(10,8); aqueduct deck casts no opaque combat shadows.

### MAP04 — The Return Road (Act IV)

A crossroads beneath capital walls, with distant prison windows and a mercy camp along the verge.

**Light:** Quiet violet evening / amber camp. **Goal:** Optional recovery skirmish shows new recruits and allows safe roster rearrangement.

- Enemy `enemy-main`: (1, 8) → (9, 8) → (17, 10) → (29, 10).
- Enemy `enemy-branch`: (1, 13) → (9, 13) → (17, 10).
- Ally `patrol-north`: (4, 4) → (12, 4) → (20, 4) → (27, 4).
- Ally `patrol-south`: (4, 17) → (12, 17) → (20, 17) → (27, 17).
- Tower pad centers: (8, 6), (16, 6), (23, 7), (8, 15), (22, 15).
- Objectives: Camp banner at(29,10); failure here never causes permanent roster soft-lock.

Before combat the same vista is a choice screen; recruitment nodes rendered as roof silhouettes with literal location names.

### MAP05 — Crownroot Court (Act V / first half)

The final palace courtyard is crossed by roots, two outer routes and bright destructible oath anchors.

**Light:** Moonlit teal / fractured gold. **Goal:** Reach boss forecourt while keeping surviving allies alive and coordinating traps/towers.

- Enemy `enemy-main`: (1, 7) → (10, 7) → (18, 9) → (25, 10) → (29, 10).
- Enemy `enemy-branch`: (1, 14) → (11, 14) → (18, 12) → (25, 10).
- Ally `patrol-north`: (4, 4) → (11, 4) → (19, 4) → (27, 4).
- Ally `patrol-south`: (4, 18) → (11, 18) → (19, 18) → (27, 18).
- Tower pad centers: (7, 5), (14, 5), (22, 7), (9, 16), (22, 16).
- Objectives: Inner gate at(29,10); oath anchor scenery at(20,5)/(20,16)becomes readable mechanics in next map.

Root texture stays low contrast except active tells; palace facade frames center-right destination.

### MAP06 — The Uncrowned Threshold (Act V / climax)

Circular throne garden framed by broken antlers, a safe negotiation dais and two oath anchors.

**Light:** Teal dusk turning warm dawn. **Goal:** Defeat Avarren, then choose pardon or refusal of pardon; no timed moral decision.

- Enemy `enemy-main`: (1, 8) → (9, 8) → (17, 9) → (24, 10) → (28, 10).
- Enemy `enemy-branch`: (1, 14) → (9, 14) → (17, 12) → (24, 10).
- Ally `patrol-north`: (4, 4) → (11, 4) → (18, 4) → (26, 4).
- Ally `patrol-south`: (4, 18) → (11, 18) → (18, 18) → (26, 18).
- Tower pad centers: (7, 6), (14, 6), (21, 6), (8, 16), (21, 16).
- Objectives: Boss dais(25,10); breakable anchors(20,5)/(20,16); choice dais(25,10)after combat.

Safe balcony strips along y4/y18 stay free of enemy-route spawns; crowns/roots never obscure enemy feet.

## Towers, traps and unit deployment

All tower upgrades retain the base silhouette and add exactly one readable tier feature. No tower turns into a visually unrelated building. Friendly structures show class-compatible sockets; a ranged occupant remains visible.

- **Palisade Roost (Ranged unit shelter):** Low square timber base, peaked shield roof, visible shooter window. Tier1→3: I: Four posts and cloth roof.; II: Copper braces and wider window.; III: Shield slats and two lanterns.. Target tradeoff: One ranged occupant receives 25% reduction to incoming projectile damage; its ranged basic-attack accuracy is 85%, compared with 100% on the ground. Range, damage and attack interval remain unchanged. No healing or trap bonuses. Unit remains visibly inside; cover does not reduce melee or area damage.
- **Waybell Beacon (Route/target support):** Slender bellpost inside a diamond stone plinth, open center. Tier1→3: I: Single bell.; II: Two bells and teal ribbon.; III: Three-bell copper crossbeam.. Target tradeoff: Highlights at most six flying enemies within four tiles and reveals the next branch. Upgrade radii are four/five/six tiles; target cap stays six. No damage bonus.
- **Hearthward (Limited between-wave recovery):** Round low brazier with cross-shaped stone rim, soft leaf smoke. Tier1→3: I: Single pot.; II: Two pots and bandage shelf.; III: Small canvas canopy.. Target tradeoff: Heals one ally at 8 HP/s between waves or 4 HP/s during combat, with a finite 60 HP healing reserve per wave. No overhealing; multiple Hearthwards cannot heal the same ally simultaneously. Clearly different from Healer unit casts.
- **Bolt Cradle (Fixed anti-siege defense):** Wide copper-and-timber crossbow on squat stepped base. Tier1→3: I: Single bow.; II: Winch and side braces.; III: Twin limbs with one projectile barrel.. Target tradeoff: One nonpiercing bolt deals 18 damage to one target every 2s; range four tiles, minimum range 1.5. Slow visible flight, fixed firing arc and cost distinguish it from DPS units.

- **Snare Stitch:** Six amber corners and a hexagonal center. States: Preview transparent → Arming dotted border → Armed hexagon corners → Trigger thread arc → Cooling empty hexagon. Four damage and 25% slow for 2s to the first eligible enemy crossing; one target and one charge. Slow does not stack with itself. Never hide the ground target.
- **Cinder Pot:** Round amber pot inside a chevron frame. States: Preview → Fuse anticipation → Ring active → Smoke decay → Spent pot. 12 damage to at most four enemies in a one-tile radius, maximum 48 total damage per pot. One trigger after a 0.8s visible fuse; no ally damage; fire outline remains clear over all terrain.
- **Decoy Standard:** Parchment forked banner with an obvious hollow body. States: Preview → Raising → Active pulse → Hit paper burst → Folded. Taunts at most three light mobs for 1.5s within two tiles; does not affect bosses; one use. Reapplication does not extend the taunt.

**Guard:** square anchor at fixed feet, upper body turns and attacks. **Patrol:** rounded waypoint loop, cyan dashed double-rail route, attack while walking using upper/lower body separation. **Advance:** forward chevrons and one target flag, stop at engagement range. A brief rooted cast has a visible foot-lock glyph rather than unexplained jitter.

## Five-act storyboard

Pacing is a 30-minute target, not a proven duration. Dialogue and moral decisions pause combat. Loss branches remain playable.

### I. The Wrong Commander — 0–5 minutes

**Keyframe:** Two mismatched allies before an oversized broken standard; warm sunrise offers hope.

- A misplaced order sends a novice commander to Hinge Gate.
- Choose one recruitment district: Bar (6), Kingdom (15), or Village (10). Each district introduces all available adults with portrait, name, class and two abilities.
- Select exactly two initial allies; inspect without time pressure, place defenses, and learn Guard/Patrol/Advance.

Art locations: MAP01. Memory flags: starting district, first two allies, dialogue stance.

### II. Friends and Monsters — 5–11 minutes

**Keyframe:** A Bellbone lays down a bell while hostile silhouettes continue on a separate lane.

- Large waves of weak mobs test route coverage.
- Weapons lowered and open palms identify some nonattackers; wounded couriers carry letters.
- A winning defense triggers a surrender offer. The negotiation scene pauses combat; player can accept, decline or seek guarantees.

Art locations: MAP02. Memory flags: sanctuary treatment, surrender response, civilian rescue.

### III. The Price of Victory — 11–18 minutes

**Keyframe:** Five monster banners lower beneath the aqueduct while two rescue lights blink beyond the breach.

- Two rescue beacons and a major siege force allocation decisions.
- Victory opens introductions for all five monster generals; choose exactly two as allies.
- Defeat does not recruit generals; survivors retreat and casualties are acknowledged without gore.

Art locations: MAP03. Memory flags: rescues, siege result, chosen generals, original ally survival.

### IV. The Choosing — 18–24 minutes

**Keyframe:** Capital carriage and prison door face one another across a warm camp lantern.

- Return to the crossroads; Royal Capital (10 candidates) and Prison (12) open in addition to early districts.
- Assumption resolving ambiguous original rule: choose five newcomers after defeat or with zero to one surviving original ally; choose three after victory with both original allies. Existing recruits and earned generals remain; no duplicate recruitment.
- The recovery battle is optional, with no permanent-loss soft lock. Short camp conversations reflect alliances and grievances.

Art locations: MAP04. Memory flags: recovery or reinforcement, newcomers, prison/capital stance.

### V. The Last Stand — 24–30 minutes

**Keyframe:** The crown rests between outstretched hands; surviving companions frame both possible decisions.

- Surviving allies and newcomers defend the courtyard and enter Avarren’s threshold.
- Three readable boss phases expose the crown and oath anchors.
- After combat, choose forgive or refuse pardon. Pardon breaks the crown voluntarily and opens a shared road; refusal seals the crown and begins a public reckoning. Neither choice is treated as a joke or selected on a timer.
- An illustrated epilogue shows the actual survivors, rescued civilians and remembered choices, then a procedural title.

Art locations: MAP05, MAP06. Memory flags: final survivors, boss choice, final dialogue, rescued communities.

**Explicit Act IV assumption:** five additional recruits after any loss or when at most one original recruit survives; otherwise three after a win with both original recruits. Existing survivors and the two earned generals stay. Counts describe new hires, not a total party reset. New hires cannot duplicate existing people. If gold would prevent a minimally viable recovery roster, camp aid covers the minimum. This resolves the user’s overlapping conditions; it needs design approval before rules are implemented.

## Five recruitment-location models

All recruitable humanoids are adults; diverse ages, bodies, skin tones and disabilities remain compatible with recognizable class tools. Rough bar patrons are not an ethnic caricature. Village poverty is depicted through resources and repairs, never lower inherent worth. Prison portraits receive the same dignity and scale as noble portraits.

- **The Bent Lantern — 6 recruits.** Warm crowded timber bar, six personal stools/tools establish every recruit silhouette; rough clothing, adult ages and body types varied. Intro camera: Doorway to counter-wide tableau, then96px portraitandfullsprite.
- **The Crownward Yard — 15 recruits.** Three five-person training groups in pale stone cloisters; polished equipment with visible repairs, no interchangeable identical helmets. Intro camera: Wide courtyard to banner grouping, then individual portrait.
- **Reedwake Common — 10 recruits.** Two five-person groups around communal well and harvest carts; practical layered clothes, improvised well-kept tools. Poverty affects access and story, not inherent worth/stat budget. Intro camera: Low well foreground frames two groups; pick person without moving portrait layout.
- **Glassmarket Contracts — 10 recruits.** Two five-person contract tables beneath copper awnings; cosmopolitan mercenaries, royal couriers and veterans, varied skin tones and builds. Intro camera: Market panorama to contract desk then portrait.
- **The Quiet Cells — 12 recruits.** Three four-person groups in a daylit stone hall with open doors; blankets, letters and personal objects; dignified varied adults, no torture spectacle. Intro camera: Outside bars to open hall; portrait uses the same respectful scale as noble recruits.

Recruitment card 420×600: 96px portrait; Name · Age · class shape and label; one-sentence voice intro; HP/basic damage/interval/range/movement; ability A/B name, effect, cooldown and 64px VFX thumbnail; full sprite and motion strip; Recruit button and party capacity. Two pinned cards enable direct comparison. No social-rank power score. Show explicit names and keep editable live text out of generated portrait art.

## UI visual states — static concepts only

**Gameplay Hud:** Top-left gateHPandwave;top-centeracttitleandtime;top-rightpause/sync;bottomsix-to-eightunitcardswithclassshape,HP,twoabilitycooldownwedges; selected unit expands to show exact cooldown seconds. HUD pixels remain at4xnearest scale.

**Pause:** Frozen battlefield with dark navy scrim; Resume, Roster, Route edit, Settings, Save/Exit. Show pending editor changes as a count and do not silently apply them.

**Extension Popup:** Compact 360×540 concept: connected-pair badge, current map thumbnail, selected object controls, Undo/Redo, and Open Full Editor button. Actual browser popup size remains within browser constraints.

**Detached Editor:** 1280×800 concept: 64px left tool rail, central map canvas, right 280px properties panel, bottom history and connection status. Tools: select, tower, unit, track, trap, erase. Native pixel Preview at 1x/2x/4x.

**Undo Redo:** Two explicit toolbar buttons andCtrl+Z/Ctrl+Shift+Zlegend;history shows object name and proposed/reverted state, never exposes internal protocols.

**Synchronization:** Game remains authoritative: Synced check badge, Pending outlined clock, Conflict split diamond with Review changes, Disconnected broken chain. Conflict compare shows PC state and proposed edit, with Apply/Discard only when safe. During combat, queue edits until a safe phase.

**Accessibility:** Shape, text and color coding; readable 4.5:1 body contrast; minimum 16px HUD text at presentation resolution; independent VFX intensity and camera-shake toggles; nonflashing cooldowns; paused recruitment and decision timers.

Drag/drop storyboard: rest(handle) → pickup(shadow/origin outline) → drag(foot ghost,range,collision footprint) → valid(teal brackets,snapped tile) / invalid(hatch,lock,reason) → drop80mssettle / cancelreturn. Undo/redo replay a labeled ghost; no silent cost or edit.

The PC game is intended as authoritative. Static UI includes Synced, Pending, Conflict and Disconnected; conflict compares the live PC state against the proposed edit. During combat, map changes queue for a safe phase. These boards do not implement Native Messaging, transport, authentication or heartbeats.

Session warning exact copy:

> **Multiple Game Instances Detected**  
> Your game is currently active on another device or platform. Only one active PC gameplay session and one connected editor session are permitted.  
> **Disconnect other session to continue**

One PC plus its authorized editor is a connected pair, not two launches. A reconnect state must account for expiring heartbeats so crashes do not imply permanent lockout.

## Endings and title-card art

**Forgive:** Avarren places the broken crown in open hands; teal roots unwind into warm gold leaves. Human and monster silhouettes share the repaired road. Mercy entails reconstruction and accountability, not instant absolution.

**Refuse pardon:** crown sealed in a copper/parchment chest; companions escort Avarren toward public reckoning or banishment according to prior choices. Somber dawn, no celebratory gore. Surviving companions stay present in both variants. Empty places in the epilogue hold the names and tools of the lost.

Titles use10 epithets × 10 deeds × 10 legacies=**1,000 candidate combinations**, with modular location/class/mercy seals rather than1,000 unique illustrations. Two ending verses (“Under an Open Crown” / “Beneath a Sealed Crown”) yield **2,000 full title-card combinations**, from 1,000 base phrases. Extra dialogue variants can expand the library. Editorial deduplication and context checks are still required; a combinatorial count is not1,000 authored meaningful outcomes. Example: “Lantern-Bearing Keeper of the Gate of the Dawn Pact.” See structured lists in world.json.

## Review gates before any implementation

1. Review every recruit/species silhouette at 1x and in monochrome. Distinct adult faces and tools must survive downscaling.
2. Approve idle,walk,run,basic,abilityA,abilityB,hit,downed/surrender andportrait for every actor; concept sheets alone do not establish production animation coverage.
3. Validate direction consistency, pivots, frame timing, contacts and release events when actual production sheets are made.
4. Check route graphs, bridges, placement footprints and map readability without VFX.
5. Simulate class budgets, cooldowns, tower tradeoffs, casualty recovery and30minute pacing in a separate future implementation task.
6. Approve Act IV assumption and final mercy/refusal wording. No game code, browser extension, balance test or export is claimed in this package.


## Finite effect caps and stacking

These are proposed balance constraints for later playtesting, not implemented rules. Area damage, aura healing/evasion, taunts and trap effects have explicit finite target counts in each model above. Per-cast caps count distinct actors, so re-entry never multiplies a capped effect. Select nearest eligible targets first; healing selects lowest percentage HP first, with stable actor ID breaking ties.

Copies of the same slow, evasion buff, redirection or taunt do not stack or extend one another; the strongest eligible effect applies. One trap per tile, at most three live allied traps per placing Strategist and twelve allied traps total, with any stricter per-ability limits still applying. Replacement and consumption require visible fade/spent states.
