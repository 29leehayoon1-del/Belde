# First recruitment visual models

Visual preproduction design; proposed statistics and cooldowns are not playtested. Animation descriptions are pose plans, not rendered production frame files.

31 recruits: Bar 6, Kingdom 15, Village 10. These models precede visual generation; no game implementation is included.

Each model uses a 32×48 body on a 64×64 canvas, ground pivot (32,56), a three-quarter SE hero view and a 96×96 recruitment portrait. All have idle, walk, run, basic attack, two ability poses/effects, hit and downed specifications in the companion JSON. Production directional frame sheets remain a later art task; concept sheets must not be called completed runtime animation assets.

Class budgets are shared across origins: Healer 100 HP; DPS 90; Tanker 180; Strategist 110. Cooldowns are 12–26 seconds. All figures are hypotheses for later playtesting.

## Bar

### BAR01 · Tornel Ashhand · DPS · age 31

Tornel — DPS. I can break a charge. Tell me who deserves to survive it.

**Appearance:** Broad shoulders, close-cropped copper hair, soot-dark skin, mended red sleeveless coat; chipped front tooth. **Silhouette:** Triangle shoulders, exposed forearms, two unequal hatchets. **Palette:** #A84E37, #E0A85D, #403344. **Weapon:** Paired throwing hatchets.

**Story:** A kiln worker who became a caravan guard after the royal levy closed his furnace.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Plant left heel, rotate torso, release one spinning hatchet with the offhand already drawing the second.

**Ability A — Kiln Splitter (16s):** Throw through up to 3 enemies in a line for 28 damage each; maximum total 84. Visual: #E0A85D square sparks and a short terracotta slash; never a screen flash. Pose: Two-handed overhead windup, forward chop, three-frame recovery.

**Ability B — Ashen Tempo (24s):** Gain 25% basic attack speed for 5 seconds; no cooldown reset. Visual: Three small ember ticks orbit the hatchet grips and expire one at a time. Pose: Tap blades together once, lower shoulders into a compact ready stance.

**Portrait:** Three-quarter grin, cracked eyebrow, hatchet head visible at lower right. One blink; optional one-pixel breath; hold long enough to read.

### BAR02 · Maela Rootglass · Healer · age 58

Maela — Healer. Sit. Breathe. Fighting on an empty stomach is foolish.

**Appearance:** Heavyset Black woman, silver locs tied with teal beads, patched indigo apron over traveling wool. **Silhouette:** Round apron, tall bottle rack, single crooked staff. **Palette:** #3E6F73, #CBAF79, #353247. **Weapon:** Tonic sling and ash staff.

**Story:** The tavern cook treats refugees without asking which uniform they wore.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Swing a corked tonic pouch underhand; pale teal mist strikes an enemy for the basic damage.

**Ability A — Last Ladle (14s):** Heal the lowest-health ally within 3 tiles for 32 HP; prioritize Tanker and DPS on equal health percentage. Visual: Teal broth-ring rises from feet to shoulders, plus-sign leaf particles. Pose: Brace the staff, draw a small cup and flick its contents forward.

**Ability B — Warm Table (24s):** Create a 2-tile-radius field for 5 seconds; select up to 2 allies once on release. Heal each selected ally inside for exactly 4 HP per 1-second tick, at most 5 ticks each; maximum 20 per ally and 40 total. No replacement targets or re-entry ticks. Visual: Low woven teal circle with amber bowl icon; safe tiles stay readable. Pose: Lower cooking pot with both hands; steam curls in two repeating loops.

**Portrait:** Kind tired eyes above a scarf, teal bead framing one cheek, no caricature. One blink; optional one-pixel breath; hold long enough to read.

### BAR03 · Orok Vell · Tanker · age 45

Orok — Tanker. Stay behind the barrel. I have been hit harder than this.

**Appearance:** Stocky green-gray half-orc, broken nose, one tusk capped in brass; purple quilted vest. **Silhouette:** Very wide shield barrel, short powerful legs, brass shoulder cap. **Palette:** #6F8165, #806080, #BC935D. **Weapon:** Reinforced barrel shield and short club.

**Story:** A former pit fighter who refuses to let frightened conscripts become entertainment.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Shield-jab with a short club follow-through; feet remain planted.

**Ability A — Barrel Wall (16s):** Gain a 38-HP personal shield lasting 5 seconds. Visual: Brass staves snap into a visible segmented shield rim. Pose: Set shield down, grip both top handles, lean into it.

**Ability B — Enough (22s):** Taunt up to 4 enemies within 2 tiles for 3 seconds and reduce incoming damage by 20% during that time. Visual: Purple broken-circle shout ring and four small shield target markers. Pose: Stamp once and beat the shield with the club; recover low.

**Portrait:** One capped tusk, amused brow, shield curved behind shoulder. One blink; optional one-pixel breath; hold long enough to read.

### BAR04 · Sable Tern · Strategist · age 27

Sable — Strategist. Everyone has a tell. Armies are only larger tables.

**Appearance:** Lean brown-skinned person with white forelock, hearing aid, short checker scarf and asymmetrical charcoal coat. **Silhouette:** One long scarf tail, square trap satchel, low center of gravity. **Palette:** #454D62, #E6C572, #8BB4A5. **Weapon:** Spring snares and weighted chalk darts.

**Story:** A cardsharp who reads movement better than promises and pays debts in warning signals.

**Proposed stats:** 110 HP; 10 damage / 1.0s; range 2.5 tiles; movement 1.9 tiles/s.

**Basic attack:** Flick a chalk dart from two fingers while the other hand guards the trap pouch.

**Ability A — House Snare (14s):** Place a visible trap within 3 tiles; first enemy takes 18 damage and is rooted for 1.5 seconds; expires after 12 seconds. Visual: Cream checker teeth close with mint corner brackets; no gore. Pose: Crouch, slide flat snare along floor, spring backward.

**Ability B — False Exit (22s):** Place a 2-tile decoy zone for 4 seconds; up to 3 non-boss enemies are slowed 35% inside. Visual: Dashed yellow doorway and mint footprints point away from civilians. Pose: Mark an arc with chalk then take two quick retreat steps.

**Portrait:** Quizzical half smile, white forelock, visible hearing aid and checker scarf. One blink; optional one-pixel breath; hold long enough to read.

### BAR05 · Fen Marrick · DPS · age 22

Fen — DPS. Pick a mark. I will already be moving when it falls.

**Appearance:** Small wiry woman with warm brown skin, cropped black curls, amber goggles and a patched saffron jacket. **Silhouette:** Compact crossbow, oversized goggle circles, one rolled sleeve. **Palette:** #C3913E, #4C6769, #DFC89B. **Weapon:** Lever crossbow.

**Story:** A courier who learned to shoot at milestones because the roads stopped being safe.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Tuck stock into shoulder, fire a square-tipped bolt, work lever with the offhand.

**Ability A — Three Milestones (18s):** Fire 3 bolts at the current target for 18 damage each over 0.6 seconds. Visual: Three amber line streaks with staggered diamond impacts. Pose: Short recoil triplet, lever opens once after third bolt.

**Ability B — Courier Step (24s):** Dash up to 2 safe tiles and gain 15% damage for 4 seconds; cannot cross occupied or blocked tiles. Visual: Teal boot afterimages, thin amber route arrow fading in 0.4 seconds. Pose: Fold crossbow close, lean forward and make a low running vault.

**Portrait:** Goggles pushed to forehead, uneven grin, bolt fletching by cheek. One blink; optional one-pixel breath; hold long enough to read.

### BAR06 · Bruna Caskward · Tanker · age 67

Bruna — Tanker. This door has kept worse people out. Get behind it.

**Appearance:** Tall elderly woman, freckled light skin, shaved gray sides with long braid, old facial burn and oxblood coat. **Silhouette:** Long rectangular door shield, iron knee brace, straight upright stance. **Palette:** #783F47, #A6A5A0, #D2AC75. **Weapon:** Tavern-door shield and iron baton.

**Story:** The innkeeper fought in the last siege and keeps the names of both armies on her ledger.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Rotate door edge forward, strike low with baton, recover behind the painted wood.

**Ability A — On My Tab (18s):** Intercept 30% of damage dealt to one adjacent ally for 5 seconds, capped at 40 redirected damage. Visual: Oxblood tether between two shield icons; intercepted hits chip bright wood flecks. Pose: Hook shield outward to cover the ally; baton points toward cover.

**Ability B — Closing Time (24s):** Push up to 3 nearby non-boss enemies back 1 tile and deal 16 damage each; bosses are slowed 20% for 2 seconds instead. Visual: Wide cream wooden crescent with three dust puffs. Pose: Two-step shoulder shove, heel anchors, shield returns upright.

**Portrait:** Gray braid, scar edge, level protective stare, wood grain behind her. One blink; optional one-pixel breath; hold long enough to read.

## Kingdom

### KIN01 · Sister Lysenne Vale · Healer · age 32

Lysenne — Healer. The oath says preserve life. It names no kingdom.

**Appearance:** Dark-skinned woman with a short natural halo of hair, ivory mail mantle, moss-green sash and practical boots. **Silhouette:** Rounded bell staff above a clean triangular mantle. **Palette:** #E5DDC8, #6C8C68, #9A8755. **Weapon:** Bell staff.

**Story:** A palace medic who kept healing deserters after a royal order forbade it.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Strike the bell once; a pale green square note travels toward the enemy.

**Ability A — Mercy Bell (14s):** Heal one ally within 3 tiles for 32 HP; removes one movement slow. Visual: Two green bell rings and a small broken-chain icon. Pose: Lift bell to eye height and roll wrist into a clear ringing arc.

**Ability B — Sanctuary Measure (24s):** Grant up to 2 allies within 2 tiles a 20-HP shield for 5 seconds; no healing overflow. Visual: Ivory bracket shields with a green lit seam. Pose: Draw a horizontal staff line and bring the bell to the chest.

**Portrait:** Calm green eyes, close natural hair, ivory collar with a small repaired seam. One blink; optional one-pixel breath; hold long enough to read.

### KIN02 · Cael Sunmere · DPS · age 24

Cael — DPS. I never missed in the lists. Help me choose where to aim.

**Appearance:** Light-brown-skinned knight with a long black braid, clean white tabard, bronze bracer and one unarmored shooting shoulder. **Silhouette:** Tall recurved bow, diagonal braid, slim kite-shaped cloak. **Palette:** #E4D9BA, #B18B4F, #46697B. **Weapon:** Royal recurve bow.

**Story:** A tournament archer discovering that medals do not tell him which orders are right.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Draw to cheek, pause one readable anticipation frame, release and lower bow.

**Ability A — Solar Thread (16s):** A piercing arrow deals 34 damage to the first target and 17 to one enemy behind it. Visual: Thin gold line ending in a four-point diamond; small white tail. Pose: Turn hips, draw high, release through a shoulder-width arc.

**Ability B — Measured Volley (24s):** For 5 seconds, every basic attack adds 4 damage; no effect on abilities. Visual: Four gold bowstring ticks pulse in sequence. Pose: Check fletching, breathe out, settle into formal archer stance.

**Portrait:** Long braid and focused brow, polished bronze shoulder catching warm light. One blink; optional one-pixel breath; hold long enough to read.

### KIN03 · Dame Ivara Stonewake · Tanker · age 40

Ivara — Tanker. A wall is only useful if someone opens a door in it.

**Appearance:** Broad dark-brown-skinned woman with tightly braided crown hair, steel plate and muted blue cloak, shield worn smooth. **Silhouette:** Huge rounded pauldron paired with narrow oval shield. **Palette:** #6B7D8B, #344A65, #BDAC87. **Weapon:** Oval shield and mace.

**Story:** The gate captain who remembers every person who waited outside it.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Shield anchors; mace makes a tight horizontal check at knee height.

**Ability A — Gatehold (16s):** Gain 36 HP of shield for 5 seconds and resist knockback while shield remains. Visual: Blue arch locks above the shield rim with three pale stone blocks. Pose: Lower shoulder, lock shield foot into the ground.

**Ability B — Make Room (22s):** Taunt up to 3 enemies within 2 tiles for 3 seconds; give one adjacent ally 15% movement speed for 3 seconds. Visual: Blue ring on enemies, pale open-gate chevron above the ally. Pose: Sweep mace inward to draw eyes, step aside behind shield.

**Portrait:** Braided crown, steady expression, visible dents and no ornamental crown. One blink; optional one-pixel breath; hold long enough to read.

### KIN04 · Oriel Quill · Strategist · age 53

Oriel — Strategist. The map is wrong wherever it forgets a person.

**Appearance:** Pale olive-skinned person, dark wavy hair graying at temples, copper spectacles and blue surveyor coat. **Silhouette:** T-square staff, rolled map cylinder and broad triangular hat. **Palette:** #587C91, #BC895D, #D9D0AD. **Weapon:** Survey darts and folding caltrops.

**Story:** A royal engineer whose maps reveal villages omitted from official relief routes.

**Proposed stats:** 110 HP; 10 damage / 1.0s; range 2.5 tiles; movement 1.9 tiles/s.

**Basic attack:** Slide a marked survey dart along the T-square and flick it forward.

**Ability A — Survey Net (14s):** Lay a visible 1-tile trap lasting 12 seconds; first enemy takes 16 damage and is slowed 40% for 4 seconds; consumed on that trigger. Visual: Copper coordinate cross and pale blue measuring tape loop. Pose: Set T-square on ground, unfold a tiny gridded net and step back.

**Ability B — Fallback Line (24s):** Mark a 3-tile line for 6 seconds; up to 3 distinct allies crossing gain 15% move speed for 4 seconds, once per ally per cast. Re-entry never refreshes the buff. Visual: Dashed pale-blue line with copper safe-direction arrows. Pose: Unroll map strip, snap a chalk line, retreat two short steps.

**Portrait:** Spectacles low on nose, blue hat brim, ink mark across cheek. One blink; optional one-pixel breath; hold long enough to read.

### KIN05 · Serit Halden · DPS · age 19

Serit — DPS. They taught me the stance. You will have to teach me the rest.

**Appearance:** Brown-skinned young woman with a black bob, crimson training sash, steel breastplate and oversized quilted gloves. **Silhouette:** Large horizontal arbalest over a small square shoulder silhouette. **Palette:** #7D4652, #AFB7BB, #D2B078. **Weapon:** Hand-cranked arbalest.

**Story:** A new knight admitted by scholarship, determined to bring everyone home.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Brace arbalest, squeeze trigger, manage a visible stiff recoil and crank down.

**Ability A — Bolt of Proof (18s):** One heavy bolt deals 48 damage; 0.45-second visible windup. Visual: Crimson core bolt with cream rectangular impact sparks. Pose: Kneel with planted rear foot and brace stock against both forearms.

**Ability B — Steady Hands (24s):** Gain 20% attack speed for 5 seconds and immunity to attack-speed reduction during the buff. Visual: Crimson wrist ribbons settle into two steady parallel strips. Pose: Exhale, flatten elbows, tap the sight into place.

**Portrait:** Nervous determination, black bob tucked behind ear, red sash at collar. One blink; optional one-pixel breath; hold long enough to read.

### KIN06 · Sir Bastien Rook · Tanker · age 61

Bastien — Tanker. I have held this road before. Let us change how it ends.

**Appearance:** Weathered tan man, full white beard, one glass eye and dark green half-plate covered in old repair rivets. **Silhouette:** Broad square shield, short plume and heavy repaired gauntlet. **Palette:** #4E6758, #B4ADA0, #A08152. **Weapon:** Riveted tower shield and cudgel.

**Story:** A retired royal guard recalled into a war he believes should have ended a generation ago.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Shield rim checks the foe; cudgel follows in a compact downward tap.

**Ability A — Rivet Resolve (18s):** Reduce incoming damage by 25% for 5 seconds; no stacking with other reduction sources beyond a 50% cap. Visual: Five pale rivets light sequentially around a green shield outline. Pose: Flex gauntlet, settle shield edge and make a slow bracing exhale.

**Ability B — Old Guard (24s):** Shield the two nearest allies within 2 tiles for 16 HP each for 5 seconds. Visual: Two small green rook silhouettes rise briefly behind recipients. Pose: Raise cudgel in salute, then plant it beside the shield.

**Portrait:** White beard, single glass eye with soft catchlight, patched green collar. One blink; optional one-pixel breath; hold long enough to read.

### KIN07 · Miren Goldleaf · Healer · age 46

Miren — Healer. Their herbs are ours. Perhaps their grief is, too.

**Appearance:** East Asian-featured woman with warm skin, dark bun threaded with gold leaves and a cream surgeon robe over boots. **Silhouette:** Open fan of herb cases and a short crescent medicine staff. **Palette:** #D6CA9F, #80905B, #9B704E. **Weapon:** Herb needles and medicine staff.

**Story:** The royal botanist cultivates the same plants that monster refugees use in mourning rites.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Snap a blunt seed-needle forward from a two-finger grip.

**Ability A — Goldleaf Stitch (12s):** Heal one ally for 26 HP immediately and one 6-HP tick after 2 seconds; maximum 32 HP total. Visual: Gold leaf stitch circles close gently over a green cross. Pose: Pinch two leaves, spiral wrist and press the staff forward.

**Ability B — Bitter Remedy (26s):** Heal up to 2 allies within 2 tiles for 20 HP each and remove one damage-over-time effect from each. Visual: Cream leaves absorb purple droplets and dissolve into green squares. Pose: Open herb fan, make a broad circular sweep below shoulder height.

**Portrait:** Gold leaves in bun, smile creases, cream robe with rolled practical sleeves. One blink; optional one-pixel breath; hold long enough to read.

### KIN08 · Neris Moth · Strategist · age 29

Neris — Strategist. Step where I step. Listen before you draw.

**Appearance:** Deep-brown-skinned person with shaved hair, one silver eyebrow stud, short slate cloak and violet officer sash. **Silhouette:** Twin compact trap reels, crescent hood lying flat, narrow boots. **Palette:** #5C5978, #8494A0, #CBBDA4. **Weapon:** Tripwire reels and blunt throwing discs.

**Story:** A scout ordered to erase evidence who instead learned how to preserve it.

**Proposed stats:** 110 HP; 10 damage / 1.0s; range 2.5 tiles; movement 1.9 tiles/s.

**Basic attack:** Skip a flat disc in a shallow wrist arc, then check the path behind.

**Ability A — Mothwire (14s):** First enemy crossing a 2-tile wire takes 14 damage and is rooted 1.5 seconds; expires after 12 seconds. Visual: Violet dotted thread with clear white endpoint stakes. Pose: Kneel, cast one reel outward, tug taut, withdraw.

**Ability B — Quiet Corridor (24s):** Create a 3-tile corridor for 5 seconds; affect up to 3 distinct enemies per cast. Affected enemies inside lose 20% accuracy, minimum hit chance 65%; the debuff ends on leaving. No target reselection after the cap is spent. Visual: Slate moth-wing brackets, translucent dotted eye icon with slash. Pose: Open cloak corners once and toss two smoke capsules to the edges.

**Portrait:** One silver brow stud, thoughtful eyes, violet sash crossing the chest. One blink; optional one-pixel breath; hold long enough to read.

### KIN09 · Adelia Flint · DPS · age 36

Adelia — DPS. The horses went to the children. I can fight on foot.

**Appearance:** Muscular light-skinned woman with auburn undercut, gold freckles, blue cavalry tunic and scarred leather throwing arm. **Silhouette:** Three javelins fan above one shoulder, short split riding cloak. **Palette:** #55788B, #B56B43, #D6BB80. **Weapon:** Balanced javelins.

**Story:** A cavalry officer who dismounted when the refugees could not keep pace.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Draw javelin past ear, twist hips, throw with a clear forward arm line.

**Ability A — Flint Spear (18s):** Deal 42 damage and reduce target armor by 10% for 4 seconds; does not stack with itself. Visual: Amber spear streak, cracked blue armor badge. Pose: Take one long planted stride and throw from the shoulder.

**Ability B — Ride the Wind (24s):** Gain 20% movement speed and 15% basic attack damage for 4 seconds. Visual: Blue split-cloak afterimages and three small cream wind squares. Pose: Set free hand flat, lean into a forward runner stance.

**Portrait:** Auburn undercut, freckles, blue collar with cavalry badge turned inward. One blink; optional one-pixel breath; hold long enough to read.

### KIN10 · Kest Ardent · Tanker · age 28

Kest — Tanker. I swore to protect a people, not a chair.

**Appearance:** Tall dark-skinned trans man, closely shaved curls, pearly steel armor, ochre cloak, square jaw and ritual wrist beads. **Silhouette:** Narrow triangular heater shield, upright spear and tall rectangular body. **Palette:** #B29A58, #B8C5C8, #465C66. **Weapon:** Heater shield and short spear.

**Story:** A palace sentry whose patience has survived more tests than his faith in the court.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Short spear jab from behind the shield, return immediately to guard.

**Ability A — Hold the Oath (16s):** Gain a 34-HP shield for 5 seconds; next basic attack during shield deals 8 bonus damage. Visual: Ochre knot icon and pearl shield edge with one bright spear point. Pose: Touch wrist beads, raise shield and level spear.

**Ability B — Stand With Me (24s):** Taunt up to 4 enemies for 2.5 seconds and grant up to 2 adjacent allies 10% damage reduction for 3 seconds; one application per target per cast. Visual: A low ochre ring joins allied feet; enemy markers are square and hollow. Pose: Plant spear butt, open shield arm toward allies, close guard.

**Portrait:** Wrist beads at lower frame, warm determined expression, ochre collar. One blink; optional one-pixel breath; hold long enough to read.

### KIN11 · Brother Jonis Reed · Healer · age 70

Jonis — Healer. Age has made me slower. It has not made me choose fewer lives.

**Appearance:** Elderly Southeast Asian-featured man, tan skin, long white mustache, bald head and simple lavender cleric coat. **Silhouette:** Circular prayer wheel, stooped but stable back, small cane. **Palette:** #82758F, #D7C9AF, #669C96. **Weapon:** Prayer wheel and cane.

**Story:** A court chaplain who records the names of enemy wounded beside his own.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Turn the wheel; a muted teal prayer bead arcs toward the enemy.

**Ability A — Names Remembered (14s):** Heal one ally for 30 HP and grant 10% damage reduction for 2 seconds. Visual: Two teal bead rings and a small lavender page icon. Pose: Roll wheel with thumb and extend an open palm.

**Ability B — Still Breathing (26s):** Select one lowest-health ally within 3 tiles; channel for at most 5 seconds, healing 7 HP per 1-second tick, at most 5 ticks and 35 HP total. Channel ends if out of range; no retargeting or immediate extra tick. Visual: A thin teal breathing line gently rises and falls above the target. Pose: Brace cane, sit weight into hips, keep one steady open hand.

**Portrait:** White mustache, kind lines around eyes, lavender collar and wheel edge. One blink; optional one-pixel breath; hold long enough to read.

### KIN12 · Romra Vey · DPS · age 43

Romra — DPS. My blade once answered orders. Now it answers me.

**Appearance:** Tall brown-skinned woman with vitiligo, salt-and-pepper long braid, crimson half-cape and bronze lamellar. **Silhouette:** Crescent glaive and a single high shoulder crest. **Palette:** #9C4B55, #BA8B54, #455C68. **Weapon:** Rune glaive casting short-range arc blades.

**Story:** An executioner who abandoned her post rather than condemn a surrendered general.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Draw glaive in a tight diagonal cut, releasing a short amber crescent.

**Ability A — Sever the Order (18s):** A crescent hits up to 3 enemies for 26 damage each; maximum 78 damage. Visual: Bronze crescent with crimson squared trailing corners. Pose: Pivot on rear heel, sweep glaive across a clean shoulder-width arc.

**Ability B — Stay Your Hand (26s):** Deal 28 damage and interrupt one non-boss enemy cast; boss receives damage without interrupt. Visual: A crimson broken-sigil stamp over a pale impact star. Pose: Stop glaive shaft abruptly, then make a precise forward thrust.

**Portrait:** Vitiligo visible around one eye, long braid, stern mouth softening at corners. One blink; optional one-pixel breath; hold long enough to read.

### KIN13 · Valen Brook · Tanker · age 34

Valen — Tanker. A crossing is a promise. I intend to keep it.

**Appearance:** Wide pale-skinned man with ginger beard, shaved head, blue brigandine and a left lower-leg prosthesis. **Silhouette:** Low broad shield, metal boot silhouette, wide planted stance. **Palette:** #536D83, #B3734C, #BBB9A6. **Weapon:** Buckler brace and short hammer.

**Story:** A bridge guard who returned to service to keep routes open for evacuation.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Anchor the prosthetic foot, shield bump, compact hammer swing.

**Ability A — Bridgebrace (16s):** Gain 36-HP shield for 5 seconds; shielded Valen counts as one obstacle for ordinary enemy pathing. Visual: Blue bridge arch rests above feet; two cream pillar sparks. Pose: Drop stance and lock buckler brace against chest.

**Ability B — Safe Crossing (24s):** Give up to 2 allies within 2 tiles 18-HP shields for 5 seconds. Visual: Two small blue bridge tiles briefly appear below allies. Pose: Raise hammer once, trace a short clear route with shield edge.

**Portrait:** Ginger beard, broad grin, blue collar; prosthesis visible in full-body model. One blink; optional one-pixel breath; hold long enough to read.

### KIN14 · Thea Larkspur · Strategist · age 23

Thea — Strategist. Give me six seconds and a little room to be wrong.

**Appearance:** Brown woman with curly shoulder-length hair, round glasses, ivory field coat, teal gloves and ink-splashed cuffs. **Silhouette:** Wide compass case, short feather plume and angular folding barricade pack. **Palette:** #4C8B8A, #D5CCB2, #A57961. **Weapon:** Folding caltrops and ink darts.

**Story:** A junior tactician who grades battle plans by the number of people they spare.

**Proposed stats:** 110 HP; 10 damage / 1.0s; range 2.5 tiles; movement 1.9 tiles/s.

**Basic attack:** Flick an ink dart with a quick writing motion.

**Ability A — Larkspur Patch (14s):** Trap a 1-tile patch for 12 seconds; first enemy takes 12 damage and is slowed 45% for 4 seconds. Visual: Teal flower-shaped corner markers and cream visible caltrop centers. Pose: Unfold a small hinged plate and scoot backward on one heel.

**Ability B — Second Draft (24s):** Reduce one ally basic attack cooldown by 30% for 4 seconds; does not affect abilities. Visual: Ivory page outline with teal double-chevron rhythm ticks. Pose: Scratch a short mark on a slate, snap it shut toward the ally.

**Portrait:** Round glasses, escaping curls, teal glove holding a small chalk stub. One blink; optional one-pixel breath; hold long enough to read.

### KIN15 · Emrys Dawnwell · Healer · age 55

Emrys — Healer. Light travels farther when someone carries it.

**Appearance:** Dark-skinned man with gray curls, a facial birthmark, golden-brown physician cloak and pale linen wraps. **Silhouette:** Two low lanterns, round shoulders and narrow staff. **Palette:** #A7844D, #DACCAF, #5B9A95. **Weapon:** Twin wick lantern staff.

**Story:** The royal physician followed the wounded out of the capital rather than await permission.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Sweep one lantern outward; a teal ember travels in a soft curve.

**Ability A — Wick Renewal (12s):** Heal one ally within 3 tiles for 30 HP. Visual: Teal flame becomes a cream diamond over the target, then sinks gently. Pose: Cup the nearer lantern, lift staff tip, open palm.

**Ability B — Dawn Watch (26s):** For 5 seconds, select up to 2 allies within 2 tiles once on release; heal each for exactly 4 HP per 1-second tick while in range, at most 5 ticks each; maximum 20 per ally and 40 total. No replacement targets or extra re-entry ticks. Visual: Two lantern-shaped anchors joined by a low teal dotted ring. Pose: Set lanterns at staff ends level and make a slow protective sweep.

**Portrait:** Gray curls, birthmark on left cheek, warm golden cloak under teal lantern light. One blink; optional one-pixel breath; hold long enough to read.

## Village

### VIL01 · Toma Hearth · Tanker · age 49

Toma — Tanker. I am not a knight. I know how to hold a weight.

**Appearance:** Broad tan man with dark stubble, patched blue worker coat, red work scarf and massive callused hands. **Silhouette:** Round millstone shield, bulky mittens, thick short boots. **Palette:** #54717E, #9A594B, #BAAA83. **Weapon:** Millstone-faced shield and mallet.

**Story:** The miller saved grain for strangers and now needs help saving the mill.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Slide shield forward and bring mallet down in a controlled compact arc.

**Ability A — Stonefast (16s):** Gain 38-HP shield for 5 seconds; movement speed is reduced 20% while it lasts. Visual: Pale stone ring with blue corner anchors. Pose: Brace both knees and press shield down until dust squares lift.

**Ability B — Turn the Wheel (24s):** Push up to 3 non-boss enemies back 1 tile and deal 14 damage each; bosses slowed 20% for 2 seconds. Visual: Half-circle millwheel spokes and three beige dust puffs. Pose: Roll shield edge across front, follow with a short shoulder drive.

**Portrait:** Dark stubble, red scarf, flour dust on brow, steady modest expression. One blink; optional one-pixel breath; hold long enough to read.

### VIL02 · Pella Moss · Healer · age 21

Pella — Healer. They shake just like we do. Hold still; this will help.

**Appearance:** Young dark-skinned woman with short coiled hair, moss-green shawl, repaired apron and reed basket. **Silhouette:** Round basket, big layered shawl and small crooked branch staff. **Palette:** #6E8C5D, #C2A97B, #745B59. **Weapon:** Reed staff and seed pouches.

**Story:** An apprentice midwife whose first battlefield patients were frightened goblins.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Flip a seed pouch upward with the staff; green mote hits with a soft leaf impact.

**Ability A — Moss Poultice (12s):** Heal one ally for 26 HP immediately and 3 HP per 1-second tick for exactly 2 ticks; maximum 32 HP total. Visual: Three moss squares settle into a cream cross. Pose: Pull a poultice from basket, press palms together, release the light.

**Ability B — Soft Landing (26s):** Shield up to 2 allies within 2 tiles for 18 HP each for 5 seconds. Visual: Round woven reed rings with low green leaves at the feet. Pose: Sweep shawl open with one arm and lower staff across the front.

**Portrait:** Coiled hair, green shawl, concentrated warm gaze, basket handle visible. One blink; optional one-pixel breath; hold long enough to read.

### VIL03 · Rusk Alder · DPS · age 38

Rusk — DPS. I can follow a trail. You decide whether we should.

**Appearance:** Lean pale man with brown skin weathering, long tied-back hair, a small beard, tan patched coat and blue hood. **Silhouette:** Very long yew bow, narrow hood, one low quiver. **Palette:** #89704F, #536E80, #BBAE85. **Weapon:** Yew hunting bow.

**Story:** A hunter who knows which monster tracks lead toward nests rather than battle.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Draw from a low crouch; release arrow with almost no upper-body sway.

**Ability A — Alder Needle (16s):** Deal 38 damage and reveal the target through visual cover for 4 seconds. Visual: Pale blue arrow streak with a small open-eye leaf icon. Pose: Kneel, hold bow near horizontal and release a deliberate low shot.

**Ability B — Huntsman Focus (24s):** Gain 20% basic attack damage for 5 seconds; breaks if manually redeployed. Visual: Two beige sight brackets and a blue steady-breath line. Pose: Set rear foot, lower hood brim and settle into still aim.

**Portrait:** Tied-back brown hair, stubble, patched blue hood and attentive eyes. One blink; optional one-pixel breath; hold long enough to read.

### VIL04 · Anwen Wicket · Strategist · age 64

Anwen — Strategist. Roots take time. Traps do not. Keep your feet clear.

**Appearance:** Small elderly dark-brown-skinned woman, white close curls, mustard apron, blue skirt and heavy gardening gloves. **Silhouette:** Long fork silhouette, round hip seed bag and tiny broad hat. **Palette:** #B69A4A, #536C82, #D5BF94. **Weapon:** Garden fork and twine snares.

**Story:** A gardener who organized the village evacuation before any herald arrived.

**Proposed stats:** 110 HP; 10 damage / 1.0s; range 2.5 tiles; movement 1.9 tiles/s.

**Basic attack:** Flick a small wooden peg from the fork tines in a short forward snap.

**Ability A — Wicket Snare (14s):** Place a visible 1-tile trap lasting 12 seconds; first enemy takes 16 damage and is rooted 1.5 seconds; consumed on that trigger. Visual: Mustard knot icon, blue twine line and cream stake tips. Pose: Set fork, tie one quick loop, shuffle backward with hands raised.

**Ability B — Mind the Path (24s):** Mark a 3-tile safe lane for 5 seconds; up to 3 distinct allies crossing gain 20% move speed for 3 seconds, once per ally per cast. Re-entry never refreshes the buff. Visual: Short blue boot arrows bordered by mustard seed dots. Pose: Trace lane with fork handle, point sharply toward the exit.

**Portrait:** White curls, gardening gloves tucked under chin, kind uncompromising eyes. One blink; optional one-pixel breath; hold long enough to read.

### VIL05 · Jori Penn · DPS · age 18

Jori — DPS. I can do this. Just do not ask me to pretend I am not afraid.

**Appearance:** Freckled light-brown-skinned young adult, black curly fringe, oversized plum coat and patched high-top work boots. **Silhouette:** Long sling arc, bulky coat cuff, narrow quick legs. **Palette:** #79536F, #C5A36E, #536E73. **Weapon:** Stone sling.

**Story:** A shepherd who used to scare crows and now hears the fear behind an invading horn.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Spin sling twice at shoulder height, release with a full visible follow-through.

**Ability A — Shepherd Star (16s):** A dense sling stone deals 40 damage to one enemy. Visual: Cream four-point impact with plum speed ticks. Pose: Plant front boot, widen spinning circle once, release high.

**Ability B — Scatter Flock (24s):** Strike up to 3 enemies for 22 damage each in a small cone; maximum 66 damage. Visual: Three beige pebbles spread with short plum dotted trails. Pose: Load three tiny pebbles, duck and sweep sling in a low broad arc.

**Portrait:** Curly fringe, freckles, plum collar too large at shoulders, resolute shy smile. One blink; optional one-pixel breath; hold long enough to read.

### VIL06 · Seli Rainjar · Healer · age 33

Seli — Healer. We gave them water. They came back to warn us.

**Appearance:** Tall brown-skinned woman with dark braided ponytail, one cloudy eye, blue rain cape and copper water flasks. **Silhouette:** Two round flasks, slanted rain hood, long reed wand. **Palette:** #5A8A9E, #B5835C, #D5CCAA. **Weapon:** Reed wand and filtered-water flasks.

**Story:** A well keeper whose village shared water with the first retreating monsters.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Send a small blue water bead from the wand with a wrist roll.

**Ability A — Clearwater (14s):** Heal one ally for 30 HP and cleanse one poison damage-over-time effect. Visual: Blue droplets form a cream cross; purple poison bead breaks. Pose: Uncap flask with thumb, draw a tight reed circle.

**Ability B — Raincloth (24s):** Give one ally a 32-HP shield lasting 5 seconds; when it expires, heal 6 HP if the ally survives. Visual: Blue cloth-shaped shield with copper edge stitches and a final single droplet. Pose: Whip rain cape corner outward and point flask toward target.

**Portrait:** One cloudy eye, dark braid, blue hood pushed back, copper flask neck at bottom. One blink; optional one-pixel breath; hold long enough to read.

### VIL07 · Bran Heddle · Tanker · age 57

Bran — Tanker. Cloth tears. People should not have to.

**Appearance:** Heavyset olive-skinned man with gray mustache, bald crown, brown quilted vest and red weaver sash. **Silhouette:** Wide loom-frame shield, rolled blanket shoulders and soft rounded body. **Palette:** #8B6D50, #9F5757, #BDB89A. **Weapon:** Loom-frame shield and wooden shuttle club.

**Story:** A weaver who stitched banners for every faction until the cloth became funeral wraps.

**Proposed stats:** 180 HP; 10 damage / 1.25s; range 1.2 tiles; movement 1.35 tiles/s.

**Basic attack:** Frame shield closes like a gate; shuttle club makes a short flat strike.

**Ability A — Warp and Weft (16s):** Gain 36-HP shield for 5 seconds; shield texture makes remaining protection visible in 3 strips. Visual: Three red woven bands cover the shield face and unravel as damaged. Pose: Pull frame tight with both hands, brace at the hips.

**Ability B — Mend the Line (24s):** Grant two adjacent allies 16-HP shields lasting 5 seconds. Visual: Two red thread loops with cream corner knots. Pose: Cast a shuttle underhand between allies, tug thread back into frame.

**Portrait:** Gray mustache, soft eyes, red sash crossing quilted work clothes. One blink; optional one-pixel breath; hold long enough to read.

### VIL08 · Nima Coppers · Strategist · age 26

Nima — Strategist. It is not scrap if it can buy us another second.

**Appearance:** Short South Asian-featured person with brown skin, black side braid, burn-marked ochre apron and green work trousers. **Silhouette:** Bulky tool roll, square goggles, small spring-loaded trap boxes. **Palette:** #A77B42, #66806A, #D0BD94. **Weapon:** Springbox traps and rivet darts.

**Story:** A tinsmith who makes alarm bells from discarded royal armor.

**Proposed stats:** 110 HP; 10 damage / 1.0s; range 2.5 tiles; movement 1.9 tiles/s.

**Basic attack:** Snap a rivet dart from a handheld spring jig.

**Ability A — Copperjaw (14s):** Place a visible 1-tile springbox lasting 12 seconds; first enemy triggering it takes 20 damage and is slowed 30% for 4 seconds; consumed on that trigger. Visual: Ochre square jaws, green bolt markers and a clear spring zigzag. Pose: Place box, wind key one half-turn and hop back.

**Ability B — Alarm String (24s):** Mark up to 3 enemies within a 2-tile zone for 4 seconds; marked enemies take 10% more basic attack damage. Visual: Small green bell icons with ochre ringing brackets. Pose: Tug a string between two stakes then point the ringing bell outward.

**Portrait:** Square goggles, black side braid, soot dot on nose, ochre apron strap. One blink; optional one-pixel breath; hold long enough to read.

### VIL09 · Osa Thistledown · Healer · age 74

Osa — Healer. Sit close. The version they taught you leaves someone out.

**Appearance:** Very old pale-skinned woman with a wide nose, white plait, plum shawl, bark-textured cane and patched wool mittens. **Silhouette:** Bent forked cane, fluffy shawl, slow compact steps. **Palette:** #85667E, #AF9D72, #CAD0AE. **Weapon:** Thistle cane and charm bundles.

**Story:** A storyteller who remembers when the demon king was still called by a mortal name.

**Proposed stats:** 100 HP; 8 damage / 1.0s; range 3.0 tiles; movement 1.6 tiles/s.

**Basic attack:** Shake cane charm; a pale green thistle mote drifts toward enemy.

**Ability A — Thistle Thread (14s):** Heal one ally for 32 HP; grant no additional offensive bonus. Visual: Plum thread curls around a cream cross with three pale-green seed motes. Pose: Wrap a short thread around cane tip and unwind it toward the ally.

**Ability B — Do Not Fade (26s):** Select one lowest-health ally within 3 tiles; channel for at most 5 seconds, healing 7 HP per 1-second tick, at most 5 ticks and 35 HP total. Channel ends beyond 3 tiles; no retargeting or immediate extra tick. Visual: A low plum story-ribbon with seed motes pulsing at one-second intervals. Pose: Brace cane with both hands, bow head and keep the ribbon steady.

**Portrait:** White plait, deep laugh lines, plum wool framing determined bright eyes. One blink; optional one-pixel breath; hold long enough to read.

### VIL10 · Fenna Briar · DPS · age 30

Fenna — DPS. I know where a branch will fall. People are harder.

**Appearance:** Athletic dark-skinned woman with an auburn braided topknot, cream shirt, green orchard apron and leather arm wrap. **Silhouette:** Three pruning knives in a fan, rolled apron, high topknot. **Palette:** #637C59, #D1C4A0, #AA704F. **Weapon:** Balanced pruning knives.

**Story:** An orchard keeper whose terraces became a refugee camp rather than a battlefield.

**Proposed stats:** 90 HP; 16 damage / 0.8s; range 3.0 tiles; movement 1.8 tiles/s.

**Basic attack:** Rotate knife once in fingers and throw from a short elbow-led arc.

**Ability A — Briar Pair (16s):** Throw two knives for 24 damage each at one enemy. Visual: Two cream slash lines with green leaf-tail squares. Pose: Cross wrists, draw two knives, release right then left.

**Ability B — Orchard Arc (24s):** Hit up to 3 enemies for 24 damage each in a shallow fan; maximum 72 damage. Visual: Three green leaf-shaped streaks and amber seed impact pixels. Pose: Turn on planted heel and sweep throwing arm across a compact fan.

**Portrait:** Auburn topknot, leather arm wrap, orchard leaf behind one ear. One blink; optional one-pixel breath; hold long enough to read.

## Shared animation and numeric contract

All 31 models now use ground pivot **(32,56)** and eight authored directions **S, SW, W, NW, N, NE, E, SE**. Common clips are idle 4 frames at 6 fps; walk 6 at 10; run 8 at 14; basic attack 6 at 12; each ability 8 at 12; hit 3 at 12; downed 6 at 10. Basic contact/projectile spawn is **one-based frame 4 / zero-based index 3**. Both ability releases use the same explicit indexing. Shared ability anticipation occupies frames 1–3, release frame 4, effect follow-through frame 5, and the three-frame recovery occupies frames 6–8 (all one-based). Serit holds the third anticipation frame an extra 0.20 seconds so her heavy bolt retains its stated 0.45-second windup without moving the authored release pose. These are animation specifications, not produced frame files.

The JSON preserves flat stat fields and adds a common nested `stats.basic_attack` object with damage, interval, range and delivery; `baseline_heal_hp_per_second` aliases the original healing field. Each ability preserves its prose and adds slot, effect/VFX aliases, animation metadata and numeric `budget_limits`.

Area support lanes affect at most three distinct allies per cast; Quiet Corridor affects at most three distinct enemies; Stand With Me protects at most two adjacent allies. Single-trigger traps last at most 12 seconds. Warm Table and Dawn Watch select at most two allies on release and allow five one-second healing ticks per ally: **40 HP total**. Still Breathing and Do Not Fade select one ally and allow five one-second ticks: **35 HP total**. Pella's poultice totals **32 HP** including two 3-HP ticks; Miren's stitch totals **32 HP** including one delayed 6-HP tick. Exiting, re-entering or changing targets cannot create extra ticks, refresh durations or exceed a per-cast budget.

These limits make the proposal bounded and comparable. No combat implementation or playtesting has occurred, so numerical balance remains unverified.
