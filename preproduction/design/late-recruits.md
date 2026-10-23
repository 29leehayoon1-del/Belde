# Late recruits and the five generals

Visual preproduction only. These are proposed designs and finite numerical budgets; no combat has been implemented, simulated, or playtested. The roster contains 10 Royal Capital recruits, 12 Prison recruits, and all 5 generals. Choose any two generals after a winning defense; all five retain art requirements because choices can change between runs.

Every hero uses a 32×48 body inside a 64×64 transparent sprite canvas, canonical 3/4 SE view, feet pivot (32,56), and 96×96 recruitment portrait. Production needs eight directions. Concept plates show representative key poses, not validated animation atlases.

Frame contract: idle 4 at 6 fps; walk 6 at 10 fps; run 8 at 14 fps; basic attack 6 at 12 fps (contact 4); each ability 8 at 12 fps (release 4); hit 3 at 12 fps; downed 6 at 10 fps; truce 4 at 8 fps. Frame/event numbers in prose are one-based: frame 4 is zero-based index 3. Do not mirror asymmetric anatomy, scars, props, or hearing aids.

Capital status buys a different silhouette, history, and tactical trade-off, not higher raw power. Prison characters retain dignity, agency, useful skills, and varied moral histories. Monster generals have readable inhuman bodies and understandable motives. Colors are reinforced by shape: white pennants mean surrender; supported seated poses plus rescue pennants mean downed.

## Finite effect budgets

- **Status:** Untested visual-preproduction budgets, not proven balance.
- **Duration:** All durations are per cast; entry and re-entry do not reset expiration.
- **Targets:** Counts mean distinct targets over the whole cast, not concurrent targets; cannot replace spent targets with new ones.
- **Ticks:** Periodic effects tick at 1 s intervals after release; target must remain valid and within effect area. No tick at time zero. Missing a tick never creates an extra tick later.
- **Placed effects:** One active instance per caster per ability; replacement expires the old instance without a damage or heal trigger.
- **Stacking:** Identical buffs, damage-over-time, traps, and area effects from one source do not stack; the stronger effect applies, with no lifetime refresh.
- **Targeting:** Bosses ignore taunt and displacement; explicit boss slow substitutions remain as authored.
- **Visual budget:** Every finite trigger should consume a visible pip or pulse. Active area overlays disappear exactly at expiration; no VFX suggests an extra healing or damage tick.

All seven Strategists move at 1.7 tiles/s. Cooldowns remain 10–28 seconds. The numbers below are design targets subject to simulation and playtesting, not a claim of established fairness.

## Royal Capital

### CAP01 · Ilyra Valecrest · DPS · age 22

**Introduction:** “I charge for my sword. My conscience comes free.”

**Model:** human woman; warm brown skin; long dark braid. slim fencer, split short coat, asymmetric brass shoulder guard. Tool: bell-guard rapier. Palette: #D7A748 / #284B5B / #D8B99A. Personality: precise, impatient, quietly generous.

**Story:** Pays village debts in secret; asks the player to spare surrendered enemies.

**Proposed numbers:** HP 86; basic 17 every 0.82 s; range 2.7 tiles; movement 1.7 tiles/s.

- **Gold Thread** — 14 s cooldown. Deal 44 single-target damage; needs a clear line; no crowd control. Visual: Rapier draws one bright stitched line; three diamond sparks converge at the enemy chest. Per-cast maxima: 1 distinct primary targets; 44 damage; 0 HP healing; 0 shield HP granted.
- **Parting Flourish** — 22 s cooldown. Deal 20 damage to up to 3 nearby enemies, then retreat 1 tile without crossing walls. Visual: A fan of three short ivory arcs opens; boot dust marks the backward step. Per-cast maxima: 3 distinct primary targets; 60 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | slim fencer, split short coat, asymmetric brass shoulder guard; subtle breath moves chest by 1 pixel, off-hand checks the bell-guard rapier; identity colors stay in the same clusters. |
| walk | heel-to-toe fencing steps; braid trails one pixel |
| run | leaning dash with coat tails split into a clear V |
| basic attack | six-frame lunge; a thin ivory diagonal lands on contact; brass spark at the point |
| ability a | Rapier draws one bright stitched line; three diamond sparks converge at the enemy chest. |
| ability b | A fan of three short ivory arcs opens; boot dust marks the backward step. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #284B5B cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; warm brown skin; long dark braid; emphasize slim fencer, split short coat, asymmetric brass shoulder guard; bell-guard rapier visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### CAP02 · Tovan Reedglass · Strategist · age 27

**Introduction:** “Give me a corner and ten seconds. I will give you a safer road.”

**Model:** human man; olive skin; round spectacles; wavy black hair. wide folded surveyor cape, triangular crossbow, ruler strapped to thigh. Tool: folding crossbow and survey stakes. Palette: #D7A748 / #506C73 / #B7775C. Personality: methodical, dry humor.

**Story:** Former city planner recognizes the siege tracks as ancient evacuation routes.

**Proposed numbers:** HP 108; basic 10 every 1.0 s; range 2.7 tiles; movement 1.7 tiles/s.

- **Survey Snare** — 16 s cooldown. Place a visible trap lasting 8 s; first enemy takes 24 damage and 30% slow for 3 s. Visual: Four brass stakes snap into a square; dotted amber tether becomes a solid square on trigger. Per-cast maxima: 1 distinct primary targets; 24 damage; 0 HP healing; 0 shield HP granted.
- **Surveyor's Retreat** — 24 s cooldown. Mark a 3-tile lane for 5 s; up to 3 distinct allies per cast gain 20% speed while retreating on it; no attack-speed bonus; re-entry cannot refresh the 5 s cast duration. Visual: Three dashed chevrons point backward; a pale arrow ribbon stays below feet. Per-cast maxima: 3 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | wide folded surveyor cape, triangular crossbow, ruler strapped to thigh; subtle breath moves chest by 1 pixel, off-hand checks the folding crossbow and survey stakes; identity colors stay in the same clusters. |
| walk | measured stride; ruler and cape sway opposite |
| run | short fast steps, crossbow tucked under one arm |
| basic attack | crossbow stock braces; a cream bolt with a square tail flies straight |
| ability a | Four brass stakes snap into a square; dotted amber tether becomes a solid square on trigger. |
| ability b | Three dashed chevrons point backward; a pale arrow ribbon stays below feet. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #506C73 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human man; olive skin; round spectacles; wavy black hair; emphasize wide folded surveyor cape, triangular crossbow, ruler strapped to thigh; folding crossbow and survey stakes visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### CAP03 · Bram Alabaster · Tanker · age 31

**Introduction:** “Your terms say protect the gate. Mine say protect the people behind it.”

**Model:** human man; deep brown skin; shaved head; neat black beard. broad rectangular shield, clipped officer cloak, square stance. Tool: tower shield and short mace. Palette: #D7A748 / #43495F / #9B6E51. Personality: patient, contractual, protective.

**Story:** Refuses a contract clause that would abandon prisoners during the siege.

**Proposed numbers:** HP 188; basic 9 every 1.25 s; range 1.2 tiles; movement 1.25 tiles/s.

- **Contract of Shelter** — 18 s cooldown. Give one adjacent ally a 38-point shield for 5 s; cannot stack. Visual: A brass rectangular frame closes around the ally; a shield stamp flashes once. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 38 shield HP granted.
- **Hold the Clause** — 24 s cooldown. Taunt up to 4 enemies within 2 tiles for 3 s and gain 20% damage reduction for those 3 s; one application per enemy; bosses ignore taunt. Visual: Mace strikes shield; three blocky sound rings and a square banner radiate outward. Per-cast maxima: 4 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | broad rectangular shield, clipped officer cloak, square stance; subtle breath moves chest by 1 pixel, off-hand checks the tower shield and short mace; identity colors stay in the same clusters. |
| walk | heavy alternating shield bob; feet remain visible |
| run | short shield-forward charge with cloak held flat |
| basic attack | mace lifts above shield and drops in a compact square impact |
| ability a | A brass rectangular frame closes around the ally; a shield stamp flashes once. |
| ability b | Mace strikes shield; three blocky sound rings and a square banner radiate outward. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #43495F cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human man; deep brown skin; shaved head; neat black beard; emphasize broad rectangular shield, clipped officer cloak, square stance; tower shield and short mace visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### CAP04 · Neme Solenne · Healer · age 36

**Introduction:** “Tell me where it hurts. Then tell me who else is missing.”

**Model:** human woman; tan skin; silver-streaked short curls. round medical satchel, high soft collar, one circular monocle. Tool: hinged lantern staff. Palette: #D7A748 / #78A89C / #F0D9AE. Personality: warm, exacting, fearless with bad news.

**Story:** Once treated both sides of a border war; knows a monster general by name.

**Proposed numbers:** HP 96; basic 8 every 1.0 s; range 3.1 tiles; movement 1.6 tiles/s. Heals 12 HP/s at baseline, prioritizing low-health Tanker/DPS.

- **Lantern Sutures** — 14 s cooldown. Heal the lowest-health ally in range for 36 HP; heal one adjacent ally for 12 HP. Visual: Three mint stitch marks bridge the wound; lantern closes after a small cross-shaped glint. Per-cast maxima: 2 distinct primary targets; 0 damage; 48 HP healing; 0 shield HP granted.
- **Gentle Ward** — 26 s cooldown. Create a 2-tile circle for 4 s; at most 3 distinct allies per cast recover 6 HP per 1 s tick while inside, maximum 4 ticks each (24 HP each; 72 HP total); no stacking or replacement targets. Visual: A broken mint ring grows inward, with four leaf shapes counting remaining seconds. Per-cast maxima: 3 distinct primary targets; 0 damage; 72 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | round medical satchel, high soft collar, one circular monocle; subtle breath moves chest by 1 pixel, off-hand checks the hinged lantern staff; identity colors stay in the same clusters. |
| walk | satchel swings low; lantern remains upright |
| run | robe hem lifted by one hand; lantern trailing small motes |
| basic attack | lantern shutter opens; one pale seed-shaped pulse targets an enemy |
| ability a | Three mint stitch marks bridge the wound; lantern closes after a small cross-shaped glint. |
| ability b | A broken mint ring grows inward, with four leaf shapes counting remaining seconds. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #78A89C cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; tan skin; silver-streaked short curls; emphasize round medical satchel, high soft collar, one circular monocle; hinged lantern staff visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### CAP05 · Daro Flintmantle · DPS · age 41

**Introduction:** “One clean shot costs less than a hundred brave mistakes.”

**Model:** dwarf man; copper skin; thick black moustache with bead tips. compact triangular cape, long rifle, broad leather knee pads. Tool: lever rifle with brass sight. Palette: #D7A748 / #865041 / #C3B18A. Personality: observant, laconic, careful.

**Story:** A former royal marksman who will not fire into a surrender flag.

**Proposed numbers:** HP 86; basic 17 every 0.84 s; range 3.3 tiles; movement 1.7 tiles/s.

- **Sightline** — 18 s cooldown. Deal 50 damage to the first enemy along a straight 5-tile line. Visual: A narrow cream guide line appears for 0.35 s, followed by one square muzzle flash. Per-cast maxima: 1 distinct primary targets; 50 damage; 0 HP healing; 0 shield HP granted.
- **Shattershot** — 22 s cooldown. Deal 18 damage to up to 3 enemies in a narrow cone; no piercing beyond them. Visual: Three ochre shard trails spread in a shallow fan; small stone-chip contact stars. Per-cast maxima: 3 distinct primary targets; 54 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | compact triangular cape, long rifle, broad leather knee pads; subtle breath moves chest by 1 pixel, off-hand checks the lever rifle with brass sight; identity colors stay in the same clusters. |
| walk | low centered march; rifle held diagonally across chest |
| run | rifle tucked parallel to ground; two boot-dust puffs |
| basic attack | two-frame aim, white muzzle cross, recoil and lever reset; no gore |
| ability a | A narrow cream guide line appears for 0.35 s, followed by one square muzzle flash. |
| ability b | Three ochre shard trails spread in a shallow fan; small stone-chip contact stars. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #865041 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show dwarf man; copper skin; thick black moustache with bead tips; emphasize compact triangular cape, long rifle, broad leather knee pads; lever rifle with brass sight visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### CAP06 · Suri Quillwake · Strategist · age 47

**Introduction:** “Every battlefield is a map somebody forgot to finish.”

**Model:** human nonbinary adult; dark skin; cropped salt-and-pepper hair. diamond-shaped kite rig folded on back, pouch bandolier. Tool: tension kite and chalk grenades. Palette: #D7A748 / #6B5B91 / #B99C79. Personality: playful, analytical, deeply loyal.

**Story:** Maps a safe passage between the prison and village before Act V.

**Proposed numbers:** HP 112; basic 9 every 1.0 s; range 2.6 tiles; movement 1.7 tiles/s.

- **False Road** — 18 s cooldown. Create one 30-HP decoy for 4 s; up to 3 distinct enemies per cast may target it; bosses ignore taunt; one active decoy per caster; no damage on expiration. Visual: A flat violet chalk silhouette unfolds like a paper person; dotted edges show it is a decoy. Per-cast maxima: 3 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.
- **Tripwire Waltz** — 24 s cooldown. Lay one 2-tile wire for 8 s; the first 2 distinct enemies each take 18 damage once and stumble for 0.4 s (36 damage total); expire after the second trigger; one active wire per caster. Visual: Two stakes connect with a bright zigzag; bells flick once per trigger, then the line snaps. Per-cast maxima: 2 distinct primary targets; 36 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | diamond-shaped kite rig folded on back, pouch bandolier; subtle breath moves chest by 1 pixel, off-hand checks the tension kite and chalk grenades; identity colors stay in the same clusters. |
| walk | bandolier bounces; kite spars make a narrow X silhouette |
| run | low sprint with folded kite tilting back |
| basic attack | underhand chalk pellet toss; powder square blooms on contact |
| ability a | A flat violet chalk silhouette unfolds like a paper person; dotted edges show it is a decoy. |
| ability b | Two stakes connect with a bright zigzag; bells flick once per trigger, then the line snaps. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #6B5B91 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human nonbinary adult; dark skin; cropped salt-and-pepper hair; emphasize diamond-shaped kite rig folded on back, pouch bandolier; tension kite and chalk grenades visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### CAP07 · Orel Brasshaven · Tanker · age 53

**Introduction:** “I have stood in worse rain than arrows. Stay close.”

**Model:** human woman; pale freckled skin; auburn-grey undercut. round kettle helm, circular buckler, barrel-shaped padded coat. Tool: round shield and hooked hammer. Palette: #D7A748 / #385F65 / #B99D91. Personality: boisterous, steadfast, tender to recruits.

**Story:** Keeps a roll of every civilian she escorted through earlier sieges.

**Proposed numbers:** HP 184; basic 10 every 1.3 s; range 1.2 tiles; movement 1.25 tiles/s.

- **Rainbreak** — 16 s cooldown. Gain a 48-point personal shield for 5 s. Visual: Four gold rivets light around a translucent round shield; each fades as shield is lost. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 48 shield HP granted.
- **Brassbound Rebuff** — 24 s cooldown. Push up to 3 small enemies back 1 tile and deal 12 damage each; large enemies take damage only. Visual: A broad low crescent and rolling dust line show direction; tiny enemies recoil without tumbling gore. Per-cast maxima: 3 distinct primary targets; 36 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | round kettle helm, circular buckler, barrel-shaped padded coat; subtle breath moves chest by 1 pixel, off-hand checks the round shield and hooked hammer; identity colors stay in the same clusters. |
| walk | round shield rocks opposite hammer; grounded hips |
| run | chin down; hammer flat to avoid catching others |
| basic attack | short shield bump followed by low hammer hook; blunt four-point hit marker |
| ability a | Four gold rivets light around a translucent round shield; each fades as shield is lost. |
| ability b | A broad low crescent and rolling dust line show direction; tiny enemies recoil without tumbling gore. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #385F65 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; pale freckled skin; auburn-grey undercut; emphasize round kettle helm, circular buckler, barrel-shaped padded coat; round shield and hooked hammer visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### CAP08 · Vessa Moonledger · Healer · age 59

**Introduction:** “I remember every name I have saved. Yours can be next.”

**Model:** human woman; medium brown skin; long silver hair in two loops. crescent eyeglasses, narrow robe, rectangular ledger on hip. Tool: silver tuning fork and ink ledger. Palette: #D7A748 / #7C859E / #C7B1A4. Personality: wry, nurturing, never forgets a promise.

**Story:** Her missing apprentice is among the prison recruits, enabling a gentle reunion.

**Proposed numbers:** HP 102; basic 8 every 1.05 s; range 3.0 tiles; movement 1.6 tiles/s. Heals 12 HP/s at baseline, prioritizing low-health Tanker/DPS.

- **Borrowed Breath** — 12 s cooldown. Heal one ally for 30 HP and cleanse one movement-slow effect. Visual: Two pale blue brackets rise beside the target; broken slow-chain icon dissolves upward. Per-cast maxima: 1 distinct primary targets; 0 damage; 30 HP healing; 0 shield HP granted.
- **Name in the Book** — 26 s cooldown. For 5 s, the lowest-health ally within range gains 24 shield; if shield survives, heal 16 HP. Visual: A small open-book silhouette floats over a squared shield; one page closes at expiration. Per-cast maxima: 1 distinct primary targets; 0 damage; 16 HP healing; 24 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | crescent eyeglasses, narrow robe, rectangular ledger on hip; subtle breath moves chest by 1 pixel, off-hand checks the silver tuning fork and ink ledger; identity colors stay in the same clusters. |
| walk | even staff-assisted steps; hair loops lift a pixel |
| run | forward lean; robe separates into two readable panels |
| basic attack | tuning fork flick sends a small paired-wave projectile |
| ability a | Two pale blue brackets rise beside the target; broken slow-chain icon dissolves upward. |
| ability b | A small open-book silhouette floats over a squared shield; one page closes at expiration. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #7C859E cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; medium brown skin; long silver hair in two loops; emphasize crescent eyeglasses, narrow robe, rectangular ledger on hip; silver tuning fork and ink ledger visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### CAP09 · Jorek Emberline · DPS · age 65

**Introduction:** “Do not mistake slow speech for a slow draw.”

**Model:** human man; light brown skin; long white moustache; left hearing aid. narrow archer silhouette, broad sunhat, curved longbow. Tool: recurve bow and cloth-fletched arrows. Palette: #D7A748 / #766D45 / #D0B08A. Personality: patient, humorous, skeptical of glory.

**Story:** Remembers the demon king before the war and challenges the official story.

**Proposed numbers:** HP 90; basic 16 every 0.85 s; range 3.3 tiles; movement 1.7 tiles/s.

- **Old Hunter** — 16 s cooldown. Deal 42 damage and reveal a hidden enemy for 5 s; no bonus against bosses. Visual: A pale ring narrows to a feather-shaped pointer, then a single arrow leaves a dotted trail. Per-cast maxima: 1 distinct primary targets; 42 damage; 0 HP healing; 0 shield HP granted.
- **Pinned Hem** — 22 s cooldown. Deal 20 damage and root one non-boss enemy for 1.2 s; bosses are slowed 20% for 2 s. Visual: Two low arrow feathers cross at the target feet; floor tether remains clearly visible. Per-cast maxima: 1 distinct primary targets; 20 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | narrow archer silhouette, broad sunhat, curved longbow; subtle breath moves chest by 1 pixel, off-hand checks the recurve bow and cloth-fletched arrows; identity colors stay in the same clusters. |
| walk | bow held upright, knees flex gently, hat stays level |
| run | hat cord trails; bow angled clear of knees |
| basic attack | draw silhouette opens into a C; release gives a short white string snap |
| ability a | A pale ring narrows to a feather-shaped pointer, then a single arrow leaves a dotted trail. |
| ability b | Two low arrow feathers cross at the target feet; floor tether remains clearly visible. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #766D45 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human man; light brown skin; long white moustache; left hearing aid; emphasize narrow archer silhouette, broad sunhat, curved longbow; recurve bow and cloth-fletched arrows visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### CAP10 · Maela Dawnforge · Tanker · age 71

**Introduction:** “Steel bends. People can, too. Hold until they choose better.”

**Model:** dwarf woman; dark umber skin; long white braid; cane-sized hammer. hexagonal shield, thick shawl, strong low center of gravity. Tool: forge shield and compact smith hammer. Palette: #D7A748 / #8A5460 / #C1A687. Personality: stern, affectionate, deliberate.

**Story:** Forged the prison gate and insists it must open before the final defense.

**Proposed numbers:** HP 192; basic 9 every 1.25 s; range 1.1 tiles; movement 1.25 tiles/s.

- **Tempered Guard** — 20 s cooldown. Give self and one adjacent ally 24 shield each for 5 s. Visual: Two hexagonal amber panels interlock; three rivets indicate the remaining shield state. Per-cast maxima: 2 distinct primary targets; 0 damage; 0 HP healing; 48 shield HP granted.
- **Anvil Stand** — 26 s cooldown. For 4 s, cannot move and takes 30% less damage; basic attack rate is unchanged. Visual: Boots plant on a low anvil outline; four square sparks lock the stance in place. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | hexagonal shield, thick shawl, strong low center of gravity; subtle breath moves chest by 1 pixel, off-hand checks the forge shield and compact smith hammer; identity colors stay in the same clusters. |
| walk | measured heavy steps; hex shield edge catches light |
| run | stomping trot, braid swings as one large readable mass |
| basic attack | hammer taps shield then forward; short amber rectangle marks contact |
| ability a | Two hexagonal amber panels interlock; three rivets indicate the remaining shield state. |
| ability b | Boots plant on a low anvil outline; four square sparks lock the stance in place. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #8A5460 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show dwarf woman; dark umber skin; long white braid; cane-sized hammer; emphasize hexagonal shield, thick shawl, strong low center of gravity; forge shield and compact smith hammer visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

## Prison

### PRI01 · Eris Wren · Strategist · age 18

**Introduction:** “I can find a door in any wall. Usually the legal kind.”

**Model:** human woman; brown skin; short uneven dark curls. oversized courier scarf, small angular sling, many folded papers. Tool: paper-wrapped stone sling. Palette: #B7AC98 / #8571A8 / #A26F4F. Personality: bright, restless, resilient.

**Story:** Imprisoned for carrying forbidden letters; exposes a surrender offer that was intercepted.

**Proposed numbers:** HP 104; basic 10 every 0.95 s; range 2.4 tiles; movement 1.7 tiles/s.

- **Message in Dust** — 16 s cooldown. Place a dust pouch trap for 8 s; first enemy takes 20 damage and 35% slow for 3 s. Visual: A folded envelope mark opens into a low lavender dust fan with stepped edges. Per-cast maxima: 1 distinct primary targets; 20 damage; 0 HP healing; 0 shield HP granted.
- **Runner’s Signal** — 24 s cooldown. For 4 s, two nearby allies gain 20% movement speed; no attack-speed increase. Visual: Two folded-paper chevrons orbit the selected feet; scarf color ties the effect to Eris. Per-cast maxima: 2 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | oversized courier scarf, small angular sling, many folded papers; subtle breath moves chest by 1 pixel, off-hand checks the paper-wrapped stone sling; identity colors stay in the same clusters. |
| walk | quick toe-led walk; scarf forms a forked tail |
| run | high-knee courier sprint with scarf streaming cleanly |
| basic attack | sling makes one compact circle; square paper trail shows the stone path |
| ability a | A folded envelope mark opens into a low lavender dust fan with stepped edges. |
| ability b | Two folded-paper chevrons orbit the selected feet; scarf color ties the effect to Eris. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #8571A8 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; brown skin; short uneven dark curls; emphasize oversized courier scarf, small angular sling, many folded papers; paper-wrapped stone sling visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### PRI02 · Pell Ashbrook · Healer · age 20

**Introduction:** “I am not a miracle. But I am here, and that counts.”

**Model:** human man; pale skin; short sandy hair; burn scar on right hand. loose sleeves, clover-shaped medicine pouch, small wooden cup. Tool: herbal cup and knotted reed staff. Palette: #B7AC98 / #86A37B / #BA8B69. Personality: gentle, anxious, surprisingly stubborn.

**Story:** Jailed for treating a surrendered monster; his testimony changes Act II dialogue.

**Proposed numbers:** HP 102; basic 8 every 1.0 s; range 2.9 tiles; movement 1.6 tiles/s. Heals 12 HP/s at baseline, prioritizing low-health Tanker/DPS.

- **Common Remedy** — 12 s cooldown. Heal one ally for 34 HP over 2 s: exactly 2 ticks of 17 HP at 1 s intervals; no overheal conversion or stacking. Visual: Three leaf-shaped motes spiral inward and disappear into a small stitched cross. Per-cast maxima: 1 distinct primary targets; 0 damage; 34 HP healing; 0 shield HP granted.
- **Warm Hands** — 24 s cooldown. Heal up to 3 adjacent allies for 18 HP each after a 0.8 s channel; interruptible. Visual: Both hands glow with soft square edges; three rising steam curls show the channel. Per-cast maxima: 3 distinct primary targets; 0 damage; 54 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | loose sleeves, clover-shaped medicine pouch, small wooden cup; subtle breath moves chest by 1 pixel, off-hand checks the herbal cup and knotted reed staff; identity colors stay in the same clusters. |
| walk | careful steps avoiding spilling cup; shoulders relax on recovery |
| run | cup sealed under thumb; staff held backward |
| basic attack | a reed flick launches one rounded green seed pulse |
| ability a | Three leaf-shaped motes spiral inward and disappear into a small stitched cross. |
| ability b | Both hands glow with soft square edges; three rising steam curls show the channel. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #86A37B cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human man; pale skin; short sandy hair; burn scar on right hand; emphasize loose sleeves, clover-shaped medicine pouch, small wooden cup; herbal cup and knotted reed staff visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### PRI03 · Kaive Thornwake · DPS · age 24

**Introduction:** “If you want loyalty, start with a straight answer.”

**Model:** human nonbinary adult; deep brown skin; shaved sides and high twist. cropped prison coat, twin short sticks, narrow bent-knee silhouette. Tool: paired hardwood batons. Palette: #B7AC98 / #9A667F / #916244. Personality: blunt, funny, distrustful of rank.

**Story:** A striking dockworker accused of sabotage; protects former strikebreakers despite anger.

**Proposed numbers:** HP 94; basic 16 every 0.85 s; range 2.7 tiles; movement 1.7 tiles/s.

- **Dockside Rhythm** — 14 s cooldown. Deal 20 damage twice to one enemy over 0.6 s; interruptible between hits. Visual: Two cream beat marks appear in sequence; alternating baton arcs never merge into a blur. Per-cast maxima: 1 distinct primary targets; 40 damage; 0 HP healing; 0 shield HP granted.
- **Clear the Deck** — 22 s cooldown. Deal 18 damage to up to 3 adjacent enemies; gain 15% move speed for 2 s. Visual: Low half-ring of sawdust and three blocky contact stars; boots leave two bright speed ticks. Per-cast maxima: 3 distinct primary targets; 54 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | cropped prison coat, twin short sticks, narrow bent-knee silhouette; subtle breath moves chest by 1 pixel, off-hand checks the paired hardwood batons; identity colors stay in the same clusters. |
| walk | loose shoulder sway; batons held low and apart |
| run | low sprinter posture with alternating baton swing |
| basic attack | two short perpendicular swishes; second contact has a diamond impact spark |
| ability a | Two cream beat marks appear in sequence; alternating baton arcs never merge into a blur. |
| ability b | Low half-ring of sawdust and three blocky contact stars; boots leave two bright speed ticks. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #9A667F cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human nonbinary adult; deep brown skin; shaved sides and high twist; emphasize cropped prison coat, twin short sticks, narrow bent-knee silhouette; paired hardwood batons visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### PRI04 · Ruma Stonefield · Tanker · age 29

**Introduction:** “A door keeps danger out. Sometimes it must keep hope in.”

**Model:** human woman; olive skin; dark hair wrapped in cream cloth. broad basketlike improvised shield, rolled blanket shoulders. Tool: reinforced door shield and wooden mallet. Palette: #B7AC98 / #6E8894 / #BF8F73. Personality: practical, protective, unimpressed.

**Story:** A tenant organizer whose improvised shields protected families from a forced eviction.

**Proposed numbers:** HP 188; basic 9 every 1.25 s; range 1.2 tiles; movement 1.25 tiles/s.

- **Doorway Promise** — 18 s cooldown. Grant one adjacent ally 40 shield for 4 s. Visual: A simple doorway outline encloses the ally; pale crossbar indicates shield health. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 40 shield HP granted.
- **Brace the Frame** — 26 s cooldown. For 3 s, root self and intercept 35% damage to one adjacent ally, capped at 45 damage. Visual: A wide violet bracket joins Ruma and the ally; bracket cracks visibly at the cap. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | broad basketlike improvised shield, rolled blanket shoulders; subtle breath moves chest by 1 pixel, off-hand checks the reinforced door shield and wooden mallet; identity colors stay in the same clusters. |
| walk | shield tilted toward incoming lane; blanket roll bobs |
| run | short forceful strides, shield steadied with both elbows |
| basic attack | shield corner jab; mallet follows with low rectangular impact |
| ability a | A simple doorway outline encloses the ally; pale crossbar indicates shield health. |
| ability b | A wide violet bracket joins Ruma and the ally; bracket cracks visibly at the cap. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #6E8894 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; olive skin; dark hair wrapped in cream cloth; emphasize broad basketlike improvised shield, rolled blanket shoulders; reinforced door shield and wooden mallet visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### PRI05 · Senna Glassroot · Strategist · age 33

**Introduction:** “Broken things still have edges. Let us use them wisely.”

**Model:** elf woman; cool brown skin; short ash-blond bob; prosthetic left forearm. triangular apron, round ceramic trap canisters, compact stance. Tool: ceramic seed traps and a handbow. Palette: #B7AC98 / #7BA49C / #9A7370. Personality: inventive, cautious, quietly mischievous.

**Story:** Accused of poisoning when her warning about contaminated city wells was ignored.

**Proposed numbers:** HP 106; basic 11 every 1.05 s; range 2.6 tiles; movement 1.7 tiles/s.

- **Glassroot Patch** — 18 s cooldown. Create one 2-tile patch for 5 s; at most 4 distinct enemies per cast take 6 damage per 1 s tick while inside, maximum 5 ticks each (30 each; 120 total), and 20% slow only while inside; no stacking or replacement targets. Visual: Six large teal shard sprouts rise from a dotted floor patch; safe paths remain visible. Per-cast maxima: 4 distinct primary targets; 120 damage; 0 HP healing; 0 shield HP granted.
- **Hollow Pot** — 24 s cooldown. Place one 32-HP decoy pot for 4 s; up to 3 distinct enemies may target it; when destroyed by damage, deal 16 damage once to at most 3 adjacent enemies (48 total); expiration deals no damage; one active pot per caster. Visual: A hollow clay pot wobbles with two triangular eye marks, then breaks into four broad chips. Per-cast maxima: 3 distinct primary targets; 48 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | triangular apron, round ceramic trap canisters, compact stance; subtle breath moves chest by 1 pixel, off-hand checks the ceramic seed traps and a handbow; identity colors stay in the same clusters. |
| walk | prosthetic hand steadies canister; apron swings in one shape |
| run | canisters clipped tight; quick side-leaning sprint |
| basic attack | handbow snaps a blunt ceramic bead; turquoise chip star on impact |
| ability a | Six large teal shard sprouts rise from a dotted floor patch; safe paths remain visible. |
| ability b | A hollow clay pot wobbles with two triangular eye marks, then breaks into four broad chips. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #7BA49C cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show elf woman; cool brown skin; short ash-blond bob; prosthetic left forearm; emphasize triangular apron, round ceramic trap canisters, compact stance; ceramic seed traps and a handbow visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### PRI06 · Alren Duskmead · DPS · age 38

**Introduction:** “I know what a bad order costs. I will not follow another.”

**Model:** human man; warm tan skin; cropped dark beard; one clouded eye. long worn scarf, triangular hunting knife, coiled rope belt. Tool: short hunting spear and rope. Palette: #B7AC98 / #A78650 / #BC8F69. Personality: soft spoken, alert, remorseful.

**Story:** Deserted after being ordered to burn a surrendered village; must confront an old officer.

**Proposed numbers:** HP 88; basic 17 every 0.84 s; range 2.7 tiles; movement 1.7 tiles/s.

- **Measured Thrust** — 16 s cooldown. Deal 46 damage to one enemy at up to 2 tiles. Visual: Spear aligns with a long narrow cream wedge; point flashes once at the far limit. Per-cast maxima: 1 distinct primary targets; 46 damage; 0 HP healing; 0 shield HP granted.
- **Cut the Tether** — 24 s cooldown. Deal 24 damage and clear one root/slow from self; move back 1 tile if open. Visual: A tan rope loop breaks at the feet; one sharp diagonal cut and a small retreat cloud. Per-cast maxima: 1 distinct primary targets; 24 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | long worn scarf, triangular hunting knife, coiled rope belt; subtle breath moves chest by 1 pixel, off-hand checks the short hunting spear and rope; identity colors stay in the same clusters. |
| walk | quiet heel-raised walk; spear point stays low |
| run | forward-leaning ranger sprint with scarf tucked close |
| basic attack | two-handed spear thrust; narrow ivory triangle and a single dust tick |
| ability a | Spear aligns with a long narrow cream wedge; point flashes once at the far limit. |
| ability b | A tan rope loop breaks at the feet; one sharp diagonal cut and a small retreat cloud. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #A78650 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human man; warm tan skin; cropped dark beard; one clouded eye; emphasize long worn scarf, triangular hunting knife, coiled rope belt; short hunting spear and rope visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### PRI07 · Ysol Pennmark · Healer · age 43

**Introduction:** “I cannot erase what happened. I can stay while you heal.”

**Model:** human nonbinary adult; pale freckled skin; dark red shoulder-length hair. square spectacles, long scarf with stitched names, soft rounded coat. Tool: ribbon-bound journal and willow wand. Palette: #B7AC98 / #8C82AD / #C8A28C. Personality: compassionate, candid, attentive.

**Story:** A banned historian; can connect surviving recruits’ stories without rewriting their losses.

**Proposed numbers:** HP 100; basic 8 every 1.0 s; range 3.0 tiles; movement 1.6 tiles/s. Heals 12 HP/s at baseline, prioritizing low-health Tanker/DPS.

- **Margin Notes** — 14 s cooldown. Heal an ally for 28 HP and give 12 shield for 3 s. Visual: Two lavender note brackets settle around the ally; a tiny page fold marks the shield. Per-cast maxima: 1 distinct primary targets; 0 damage; 28 HP healing; 12 shield HP granted.
- **Shared Chapter** — 26 s cooldown. For 4 s, up to 3 distinct nearby allies each recover 5 HP per 1 s tick, maximum 4 ticks each (20 each; 60 total); no replacement targets or stacking; channel ends if Ysol is downed. Visual: Three dotted page ribbons connect to low open-book icons; no screen-filling beam. Per-cast maxima: 3 distinct primary targets; 0 damage; 60 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | square spectacles, long scarf with stitched names, soft rounded coat; subtle breath moves chest by 1 pixel, off-hand checks the ribbon-bound journal and willow wand; identity colors stay in the same clusters. |
| walk | journal pressed to chest; scarf names make a calm two-pixel rhythm |
| run | coat opens slightly; wand held forward to balance |
| basic attack | wand draws a small square; pale paper mote launches from its center |
| ability a | Two lavender note brackets settle around the ally; a tiny page fold marks the shield. |
| ability b | Three dotted page ribbons connect to low open-book icons; no screen-filling beam. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #8C82AD cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human nonbinary adult; pale freckled skin; dark red shoulder-length hair; emphasize square spectacles, long scarf with stitched names, soft rounded coat; ribbon-bound journal and willow wand visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### PRI08 · Garrick Mossbar · Tanker · age 49

**Introduction:** “I was called a monster before I ever met one.”

**Model:** orc man; muted sage skin; one broken tusk; long dark locs. very wide shoulders, rounded quilted vest, short barrel shield. Tool: oak barrel shield and iron-capped club. Palette: #B7AC98 / #798C67 / #947459. Personality: reserved, gentle, difficult to hurry.

**Story:** Wrongly jailed after defending a child; refuses to become proof of the guards’ prejudice.

**Proposed numbers:** HP 198; basic 9 every 1.3 s; range 1.1 tiles; movement 1.25 tiles/s.

- **Oakskin Resolve** — 18 s cooldown. Gain 46 personal shield for 5 s and 15% slow resistance while shielded. Visual: Three broad wooden plates overlap the torso; green rivets dim with shield loss. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 46 shield HP granted.
- **No Further** — 24 s cooldown. Stop up to 3 small enemies for 0.7 s and deal 10 damage each; bosses take damage only. Visual: Club plants in the ground; a short horizontal bar and three root stubs define the boundary. Per-cast maxima: 3 distinct primary targets; 30 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | very wide shoulders, rounded quilted vest, short barrel shield; subtle breath moves chest by 1 pixel, off-hand checks the oak barrel shield and iron-capped club; identity colors stay in the same clusters. |
| walk | slow broad steps; shoulder silhouette stays level |
| run | grounded bounding trot; locs swing as two large groups |
| basic attack | club sweeps low without spinning; blunt leaf-shaped hit burst |
| ability a | Three broad wooden plates overlap the torso; green rivets dim with shield loss. |
| ability b | Club plants in the ground; a short horizontal bar and three root stubs define the boundary. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #798C67 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show orc man; muted sage skin; one broken tusk; long dark locs; emphasize very wide shoulders, rounded quilted vest, short barrel shield; oak barrel shield and iron-capped club visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### PRI09 · Mirren Cindersong · DPS · age 55

**Introduction:** “They took my stage. They did not take my timing.”

**Model:** human woman; deep brown skin; long grey hair tied with orange thread. tall narrow poncho, short curved blade, ember-red ankle wraps. Tool: curved saber and flint striker. Palette: #B7AC98 / #AD6A51 / #C09B80. Personality: proud, theatrical, loyal to fellow prisoners.

**Story:** A performer jailed for satire; her final recruitment scene turns a prison chant into courage.

**Proposed numbers:** HP 92; basic 16 every 0.82 s; range 2.7 tiles; movement 1.7 tiles/s.

- **Cinder Refrain** — 18 s cooldown. Deal 30 damage plus exactly 4 ticks of 4 damage at 1 s intervals over 4 s to one enemy (46 damage total); burns do not stack or refresh. Visual: A short ember ribbon wraps the blade; four square sparks count the burn duration. Per-cast maxima: 1 distinct primary targets; 46 damage; 0 HP healing; 0 shield HP granted.
- **Second Verse** — 24 s cooldown. Deal 24 damage to up to 2 adjacent enemies; if both survive, gain 10 shield for 3 s. Visual: Two distinct low crescents cross like musical parentheses; a tiny flame-free shield glints. Per-cast maxima: 2 distinct primary targets; 48 damage; 0 HP healing; 10 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | tall narrow poncho, short curved blade, ember-red ankle wraps; subtle breath moves chest by 1 pixel, off-hand checks the curved saber and flint striker; identity colors stay in the same clusters. |
| walk | dancer’s planted heel turns; poncho lifts as one wedge |
| run | long rhythmic stride; blade close to hip |
| basic attack | curved saber cuts a restrained orange crescent, followed by a soft heel stamp |
| ability a | A short ember ribbon wraps the blade; four square sparks count the burn duration. |
| ability b | Two distinct low crescents cross like musical parentheses; a tiny flame-free shield glints. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #AD6A51 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; deep brown skin; long grey hair tied with orange thread; emphasize tall narrow poncho, short curved blade, ember-red ankle wraps; curved saber and flint striker visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### PRI10 · Oda Reedlock · Strategist · age 61

**Introduction:** “Every lock was made by a person. So was every excuse.”

**Model:** human woman; medium brown skin; salt-white cropped hair; missing left little finger. long rectangular apron, ring of large keys, forked hook staff. Tool: lockpick hook and weighted keys. Palette: #B7AC98 / #7D8995 / #B18B72. Personality: shrewd, motherly, distrusts easy answers.

**Story:** A locksmith punished for opening debtors’ cells; can open a civilian escape lane in Act IV.

**Proposed numbers:** HP 114; basic 9 every 1.0 s; range 2.5 tiles; movement 1.7 tiles/s.

- **False Lock** — 18 s cooldown. Place a visible lock trap for 8 s; first enemy is rooted 1 s and takes 20 damage; boss slow20% 2 s. Visual: A violet keyhole floor mark snaps into two square brackets around feet. Per-cast maxima: 1 distinct primary targets; 20 damage; 0 HP healing; 0 shield HP granted.
- **Open Passage** — 24 s cooldown. Create one 3-tile safe retreat marker for 5 s; up to 3 distinct allies per cast gain 20% move speed while on it; re-entry cannot refresh the 5 s duration; one active marker per caster. Visual: Three open-door icons become low dashed arrows; the path stays underneath all units. Per-cast maxima: 3 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | long rectangular apron, ring of large keys, forked hook staff; subtle breath moves chest by 1 pixel, off-hand checks the lockpick hook and weighted keys; identity colors stay in the same clusters. |
| walk | keys bounce in a slow readable arc; staff touches ground every other step |
| run | apron tied back; keys held in fist to silence them |
| basic attack | a single weighted key toss; blunt ring-shaped contact flash |
| ability a | A violet keyhole floor mark snaps into two square brackets around feet. |
| ability b | Three open-door icons become low dashed arrows; the path stays underneath all units. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #7D8995 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human woman; medium brown skin; salt-white cropped hair; missing left little finger; emphasize long rectangular apron, ring of large keys, forked hook staff; lockpick hook and weighted keys visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### PRI11 · Tessara Claywell · Healer · age 68

**Introduction:** “Drink. Sit if you must. You can be brave after breakfast.”

**Model:** dwarf woman; warm umber skin; white coiled bun; copper nose ring. round potter’s apron, oval clay flask, short cushioned cape. Tool: warm clay flask and carved spoon. Palette: #B7AC98 / #B78B74 / #D2BA99. Personality: firm, funny, attentive to hunger.

**Story:** Arrested for sheltering escaped prisoners; knows the village’s endangered grain stores.

**Proposed numbers:** HP 108; basic 7 every 1.05 s; range 2.9 tiles; movement 1.6 tiles/s. Heals 12 HP/s at baseline, prioritizing low-health Tanker/DPS.

- **Clay Cradle** — 14 s cooldown. Heal one ally for 32 HP and reduce incoming damage 10% for 2 s. Visual: A shallow earthen bowl silhouette cups the ally’s feet; two soft steam squares rise. Per-cast maxima: 1 distinct primary targets; 0 damage; 32 HP healing; 0 shield HP granted.
- **Hearth Circle** — 28 s cooldown. Create one 2-tile circle for 4 s; up to 3 distinct allies per cast recover 5 HP per 1 s tick while inside, maximum 4 ticks each (20 each; 60 total), and cleanse one slow on first entry only; no stacking or replacement targets. Visual: A dotted terracotta circle with three cup symbols; steam curls point inward without flames. Per-cast maxima: 3 distinct primary targets; 0 damage; 60 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | round potter’s apron, oval clay flask, short cushioned cape; subtle breath moves chest by 1 pixel, off-hand checks the warm clay flask and carved spoon; identity colors stay in the same clusters. |
| walk | stable tiny steps; flask held in both hands |
| run | surprisingly quick rolling trot; cape held down by flask strap |
| basic attack | spoon flicks a pale clay bead; round cream contact puff |
| ability a | A shallow earthen bowl silhouette cups the ally’s feet; two soft steam squares rise. |
| ability b | A dotted terracotta circle with three cup symbols; steam curls point inward without flames. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #B78B74 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show dwarf woman; warm umber skin; white coiled bun; copper nose ring; emphasize round potter’s apron, oval clay flask, short cushioned cape; warm clay flask and carved spoon visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### PRI12 · Varrin Quietgate · Tanker · age 75

**Introduction:** “I guarded this place for forty years. Now I will help it change.”

**Model:** human man; pale olive skin; long white eyebrows; clean-shaven head. tall spare frame, long padded coat, narrow kite shield. Tool: kite shield and blunted watch spear. Palette: #B7AC98 / #6E7E89 / #C2A486. Personality: solemn, observant, patient.

**Story:** A retired warden imprisoned after testifying against abuse; owes survivors a patient hearing.

**Proposed numbers:** HP 174; basic 10 every 1.2 s; range 1.3 tiles; movement 1.25 tiles/s.

- **Old Watch** — 22 s cooldown. Taunt up to 4 nearby enemies for 3 s and gain 18% damage reduction for those 3 s; one application per enemy; bosses ignore taunt. Visual: Three pale watch ticks rotate once around the shield; a small bell-ring graphic appears. Per-cast maxima: 4 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.
- **Last Hinge** — 26 s cooldown. Give the lowest-health adjacent ally 36 shield for 5 s and self 12 shield. Visual: A narrow door hinge unfolds into two connected panels, larger panel on the ally. Per-cast maxima: 2 distinct primary targets; 0 damage; 0 HP healing; 48 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | tall spare frame, long padded coat, narrow kite shield; subtle breath moves chest by 1 pixel, off-hand checks the kite shield and blunted watch spear; identity colors stay in the same clusters. |
| walk | deliberate straight-backed walk; spear used as a light brace |
| run | measured short run, shield stays aligned with face |
| basic attack | shield nudge then blunt spear jab; thin square impact |
| ability a | Three pale watch ticks rotate once around the shield; a small bell-ring graphic appears. |
| ability b | A narrow door hinge unfolds into two connected panels, larger panel on the ally. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #6E7E89 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show human man; pale olive skin; long white eyebrows; clean-shaven head; emphasize tall spare frame, long padded coat, narrow kite shield; kite shield and blunted watch spear visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

## Monster General

### GEN01 · General Veyra of the Pale Wing · Healer · age 25

**Introduction:** “We came for a home. I will not make one from your graves.”

**Model:** mothfolk woman; 42 seasonal years / adult-equivalent25; soft charcoal face, pearl antennae. tall folded moth wings shaped like a cloak, oval lantern abdomen. Tool: silk spindle and luminous scales. Palette: #C7C5E5 / #70878A / #DECDA1. Personality: empathetic, hesitant, quietly brave.

**Story:** Her troops carry children and wounded; protecting surrender flags enables her alliance.

**Proposed numbers:** HP 96; basic 8 every 1.0 s; range 3.2 tiles; movement 1.6 tiles/s. Heals 12 HP/s at baseline, prioritizing low-health Tanker/DPS.

- **Mercy Dust** — 16 s cooldown. Heal up to 3 nearby allies for 18 HP each; no hostile damage. Visual: Three pearl moth scales float down; each becomes a small outlined cross at landing. Per-cast maxima: 3 distinct primary targets; 0 damage; 54 HP healing; 0 shield HP granted.
- **Silk Shelter** — 24 s cooldown. Grant one ally a 36-point shield for 5 s and cleanse one slow effect. Visual: A pearl cocoon outline weaves around the target with a clear open face; a thread knot marks shield. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 36 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | tall folded moth wings shaped like a cloak, oval lantern abdomen; subtle breath moves chest by 1 pixel, off-hand checks the silk spindle and luminous scales; identity colors stay in the same clusters. |
| walk | six small foot placements but two readable leg groups; wings breathe |
| run | light low flutter with feet skimming; wings remain folded enough to read path |
| basic attack | spindle launches one pale scale that bursts into four tiny diamonds |
| ability a | Three pearl moth scales float down; each becomes a small outlined cross at landing. |
| ability b | A pearl cocoon outline weaves around the target with a clear open face; a thread knot marks shield. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #70878A cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show mothfolk woman; 42 seasonal years / adult-equivalent25; soft charcoal face, pearl antennae; emphasize tall folded moth wings shaped like a cloak, oval lantern abdomen; silk spindle and luminous scales visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### GEN02 · General Orun Basalt-Vow · Tanker · age 34

**Introduction:** “I was told your walls were empty. I can see that was a lie.”

**Model:** stoneborn nonbinary adult; 108 years / adult-equivalent34; granite face with warm clay seams. huge trapezoid shoulders, small careful hands, broken arch crown. Tool: stone forearm shield and palm strike. Palette: #7E898C / #C4A475 / #6A6B8C. Personality: measured, literal, protective of small lives.

**Story:** Ordered to break the gate; changes sides when shown the civilian refuge behind it.

**Proposed numbers:** HP 198; basic 9 every 1.3 s; range 1.1 tiles; movement 1.25 tiles/s.

- **Basalt Covenant** — 18 s cooldown. Gain 50 personal shield for 5 s; cannot stack with another personal shield. Visual: Three charcoal slabs orbit close then slot onto forearms; warm seams show remaining shield. Per-cast maxima: 1 distinct primary targets; 0 damage; 0 HP healing; 50 shield HP granted.
- **Sheltering Arch** — 26 s cooldown. Give up to 2 adjacent allies 22 shield each for 5 s. Visual: An arch-shaped stone outline grows above allies and splits into two protective cornerstones. Per-cast maxima: 2 distinct primary targets; 0 damage; 0 HP healing; 44 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | huge trapezoid shoulders, small careful hands, broken arch crown; subtle breath moves chest by 1 pixel, off-hand checks the stone forearm shield and palm strike; identity colors stay in the same clusters. |
| walk | weighty two-beat step; one seam pulse per planted foot |
| run | slow powerful bounding stride, no cartoon speed lines |
| basic attack | one palm pushes forward; compressed rectangular stone burst at contact |
| ability a | Three charcoal slabs orbit close then slot onto forearms; warm seams show remaining shield. |
| ability b | An arch-shaped stone outline grows above allies and splits into two protective cornerstones. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #C4A475 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show stoneborn nonbinary adult; 108 years / adult-equivalent34; granite face with warm clay seams; emphasize huge trapezoid shoulders, small careful hands, broken arch crown; stone forearm shield and palm strike visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### GEN03 · General Kharu Redtusk · DPS · age 46

**Introduction:** “A victory that spends every child is only another kind of defeat.”

**Model:** boarfolk man; 59 years / adult-equivalent46; rust fur; one tusk capped in bronze. low broad head, narrow waist, wrapped curved glaive, frayed commander sash. Tool: single curved glaive. Palette: #A96D50 / #633D4E / #C4A56E. Personality: blunt, grief-struck, loyal to the surrendered.

**Story:** Lost his family in earlier raids; can accept restraint without being absolved of past harm.

**Proposed numbers:** HP 96; basic 16 every 0.86 s; range 2.7 tiles; movement 1.7 tiles/s.

- **Tusklight Sweep** — 18 s cooldown. Deal 20 damage to up to 3 adjacent enemies; no knockback. Visual: Three short rust arcs fan from the blade; bronze tusk cap flashes to cue the windup. Per-cast maxima: 3 distinct primary targets; 60 damage; 0 HP healing; 0 shield HP granted.
- **Oathbound Strike** — 24 s cooldown. Deal 48 damage to one enemy after 0.6 s windup; canceled if target leaves range. Visual: Glaive edge lights with two angular gold notches; a clear target chevron closes at impact. Per-cast maxima: 1 distinct primary targets; 48 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | low broad head, narrow waist, wrapped curved glaive, frayed commander sash; subtle breath moves chest by 1 pixel, off-hand checks the single curved glaive; identity colors stay in the same clusters. |
| walk | two grounded hoofbeats; glaive horizontal at waist |
| run | forward shoulder-led charge; sash splits behind one readable silhouette |
| basic attack | one deliberate rising glaive cut; wide rust crescent and blunt gold impact |
| ability a | Three short rust arcs fan from the blade; bronze tusk cap flashes to cue the windup. |
| ability b | Glaive edge lights with two angular gold notches; a clear target chevron closes at impact. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #633D4E cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show boarfolk man; 59 years / adult-equivalent46; rust fur; one tusk capped in bronze; emphasize low broad head, narrow waist, wrapped curved glaive, frayed commander sash; single curved glaive visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | No ranged tower assignment; portrait shows a crossed-out tower socket with plain-language melee-only tooltip; never generate a false ranged attack. |

### GEN04 · General Nix Hollowbranch · Strategist · age 57

**Introduction:** “If the road to peace is a trap, I would like to inspect the knots.”

**Model:** foxfolk nonbinary adult; 81 years / adult-equivalent57; dusk-grey fur; white muzzle. one large brush tail, crooked half-mask carried at belt, antler-shaped baton. Tool: branch baton and woven decoy charms. Palette: #8B8A9B / #C0AA7E / #5F7F79. Personality: wry, wary, fiercely protective of refugees.

**Story:** Used misdirection to hide monster refugees; mistrusts both royal propaganda and the demon king.

**Proposed numbers:** HP 106; basic 10 every 1.0 s; range 2.6 tiles; movement 1.7 tiles/s.

- **Hollow Double** — 18 s cooldown. Create one 32-HP decoy for 4 s; up to 3 distinct enemies per cast may target it; bosses ignore taunt; one active decoy per caster; no damage on expiration. Visual: A grey leaf-fox silhouette unfolds from a woven charm; dotted ears show the false body. Per-cast maxima: 3 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.
- **Briar Courtesy** — 24 s cooldown. Place one 2-tile briar patch for 5 s; at most 4 distinct enemies per cast take 6 damage per 1 s tick while inside, maximum 5 ticks each (30 each; 120 total), and 20% slow only while inside; no stacking or replacement targets. Visual: Three teal zigzag roots rise just above ground; a pale dotted perimeter keeps the route readable. Per-cast maxima: 4 distinct primary targets; 120 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | one large brush tail, crooked half-mask carried at belt, antler-shaped baton; subtle breath moves chest by 1 pixel, off-hand checks the branch baton and woven decoy charms; identity colors stay in the same clusters. |
| walk | quiet digitigrade steps; tail balances wide turns |
| run | low foxlike sprint; tail flattens as a clear trailing wedge |
| basic attack | baton flick launches a small woven dart with a forked pale tail |
| ability a | A grey leaf-fox silhouette unfolds from a woven charm; dotted ears show the false body. |
| ability b | Three teal zigzag roots rise just above ground; a pale dotted perimeter keeps the route readable. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #C0AA7E cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show foxfolk nonbinary adult; 81 years / adult-equivalent57; dusk-grey fur; white muzzle; emphasize one large brush tail, crooked half-mask carried at belt, antler-shaped baton; branch baton and woven decoy charms visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

### GEN05 · General Siltwake of Nine Reeds · Strategist · age 73

**Introduction:** “Rivers survive by changing course. Perhaps kings should learn.”

**Model:** newtfolk woman; 96 flood years / adult-equivalent73; muted blue-green skin; orange throat fan. long flat tail, reed crown, short waterproof cloak, circular shield basket. Tool: reed blowpipe and clay tide jars. Palette: #668F91 / #BE8F61 / #6D6A91. Personality: patient, sardonic, remembers every flood.

**Story:** Her scouts reveal the final arena’s flood channels; she demands safe passage for noncombatants.

**Proposed numbers:** HP 114; basic 9 every 1.0 s; range 2.5 tiles; movement 1.7 tiles/s.

- **Low Tide Jar** — 16 s cooldown. Place one puddle for 5 s; up to 6 distinct enemies per cast move 30% slower while inside; leaving removes the slow; no damage, stacking, refresh, or replacement targets; one active puddle per caster. Visual: A clay jar breaks into four chips; a low teal puddle with white concentric steps spreads. Per-cast maxima: 6 distinct primary targets; 0 damage; 0 HP healing; 0 shield HP granted.
- **Reed Alarm** — 24 s cooldown. Mark one 3-tile lane for 6 s; the first 4 distinct enemies entering are revealed for 3 s and take 20 damage once each (80 damage total); expire after 4 entries; one active lane per caster. Visual: Three reed stakes with diamond bells form a dashed lane; each triggered bell flashes a square ripple. Per-cast maxima: 4 distinct primary targets; 80 damage; 0 HP healing; 0 shield HP granted.

| State | Character-specific art direction |
|---|---|
| idle | long flat tail, reed crown, short waterproof cloak, circular shield basket; subtle breath moves chest by 1 pixel, off-hand checks the reed blowpipe and clay tide jars; identity colors stay in the same clusters. |
| walk | tail traces a shallow S; knees bend low without sliding |
| run | short quick scamper; tail lifts to avoid clipping track markers |
| basic attack | blowpipe expands cheek by one pixel; a pale reed dart leaves two dotted wake marks |
| ability a | A clay jar breaks into four chips; a low teal puddle with white concentric steps spreads. |
| ability b | Three reed stakes with diamond bells form a dashed lane; each triggered bell flashes a square ripple. |
| hit | One-pixel shoulder recoil and brief outline flash; no body strobe or blood; retain readable facing. |
| downed | Weapon lowers, knees fold, then a supported seated silhouette with #BE8F61 cloak/cloth spread; a small rescue pennant replaces combat markers. No graphic injuries. |
| surrender or truce | Weapon placed low; both hands or open palm visible; outlined white pennant above shoulder; character remains distinct from downed pose. |
| recruitment snapshot | Waist-up 3/4 portrait; show newtfolk woman; 96 flood years / adult-equivalent73; muted blue-green skin; orange throat fan; emphasize long flat tail, reed crown, short waterproof cloak, circular shield basket; reed blowpipe and clay tide jars visible only along one edge; calm eye line to player; warm key light and one cool rim pixel. |
| tower variant | Waist-high battlement overlays lower legs; upper body leans over rail. The reticle widens for 85% tower accuracy versus 100% ground accuracy; a projectile shield icon marks 25% incoming projectile-damage reduction. No bonus to range, damage, attack interval, healing, or traps. Keep identity silhouette unchanged. |

## Production boundaries

The documents establish identity, key poses, VFX language, and an initial numerical envelope. They do not claim generated art contains every animation frame, that sprites have been sliced, or that play balance is proven. Eligible ranged units may occupy towers: incoming projectile damage is reduced by 25%, while basic ranged attack accuracy changes from 100% on ground to 85% in a tower. There is no bonus to range, damage, attack interval, healing, or traps. Melee units remain ineligible for tower assignment. This is an untested design target. Guard, Patrol, and Advance share the same costume and body.

Single-target VFX fit a 96×96 effect canvas; area effects use a 192×128 ground overlay. Keep travel lanes visible. Friendly support uses mint brackets, hostile telegraphs rust triangles, and surrender a white pennant plus lowered weapons. Communicate through shapes as well as color.
