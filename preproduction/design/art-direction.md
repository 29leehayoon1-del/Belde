# BELDE — The Wrong Commander

An original visual preproduction package. Scope: models, key poses, animation specifications, storyboards, interface studies and art handoff. No playable game, session server, browser extension, native bridge or executable is implemented.

## Visual identity

A wounded little kingdom that still contains warm windows, ridiculous helmets and people worth saving. Dark fairytale drama with humorous human details, not relentless gore. The camera is a three-quarter top-down battlefield view. Characters are readable at small sizes through silhouettes, weapon shape and posture. Recruitment portraits show expressive faces and lived-in clothing.

Foundation palette: ink `#151b2b`, night `#252b43`, slate `#4f5c73`, fog `#a8b5bd`, parchment `#eee0b7`, cream `#fff1cf`; wood `#60433b`, rust `#a15b46`, copper `#d99855`, gold `#f4c86b`; moss `#4a6456`, leaf `#83a970`, teal `#4ca6a8`, ice `#9be1dc`; threat `#ba4f61`, warning `#f39c64`, corruption `#744d91`. These are palette targets for concept generation, not a claim that generated raster images obey an indexed palette.

One clear light direction from upper left, 1px dark silhouette line, 2–3 clustered shades per material, restrained dithering. No antialiasing in final production sprites. Faces and weapons take priority over ornamental noise. Portraits may use larger cluster detail but retain character colors and silhouette.

## Role language

- Healer: round satchel/chime/crook silhouette, soft mint crosses made from four diamond pips, pale connecting threads. Never rely on green alone.
- DPS: forward lean, long blade/bow or asymmetric weapon, copper triangular slash. High visual energy, short readable flashes.
- Tanker: broad shoulder/shield mass, blue square guard brackets, heavy planted feet.
- Strategist: low utility belt, flags/wire/traps, amber hexagonal markers and dotted movement traces.

Enemy warning shapes are hollow red chevrons with white broken edges; ally effects have filled pale centers. Cyan dashed double rails indicate allied patrol tracks; ochre packed-earth routes carry enemy footprints and a red gateward arrow. Guard circle, patrol double arrow and advance spearhead remain identifiable in grayscale.

## Asset scales and naming

Gameplay target 640×360. Tile 32×32. Ordinary ally model 32×48 inside a 64×64 transparent production cell. Large enemies use 96×96; boss uses 160×160 with an oversized VFX layer. Portrait 96×96; recruitment bust 192×256. These are production specifications; generated contact sheets are larger reference boards, not uniformly sliced final atlases.

Asset keys: `BELDE_<ID>_<STATE>_<DIR>_<FRAME>`. Directions S, SW, W, NW, N, NE, E, SE; initial boards show SE. Keep handed weapons/shield insignia correct when authoring directions; do not mirror text or asymmetric equipment blindly. Separate body, shadow, weapon, projectile, impact, aura, UI icon and portrait layers.

Each character's eight-column visual reference shows portrait, idle, walk contact, run passing, basic attack active, ability A active, ability B active, downed/resting. Full clip frames and other directions are specified in the model data and world animation contract, and remain to be authored. A key pose is not an animation sequence.

## Gameplay readability

Animate anticipation before damage: hold a distinct windup, then one decisive contact frame and a recovery that preserves player counterplay. Use restrained screen shake only for boss or siege events. Heals bloom upward; shields wrap inward; enemy danger fills from edge to center. Enemies that surrender lower weapons and display an unmistakable white tied cloth; noncombatants show open hands and luggage. Neither uses a target reticle.

Towers add protection but reduce ranged accuracy through narrow firing slits. The visible tradeoff is a shield badge plus a spread reticle; no universal extra defense for melee units on platforms. Traps show setup, armed, triggered, spent and dismantled states. Downed allies remain recognizable and recoverable; there is no graphic dismemberment.

## Story choices and assumptions

The first choice opens one of the bar (6 candidates), kingdom (15) or village (10); recruit exactly two. Victory in the early defense permits choosing two of five monster generals. All five have full models even though only two join a run. Act IV offers capital mercenaries (10) and prison recruits (12): choose five newcomers after a defeat or if at most one original ally survives; otherwise choose three. The wording in the brief is ambiguous; this explicit recovery rule is a design proposal. No selection-flow logic has been coded.

All human combatants are adults; age diversity comes from young adults, middle-aged recruits and elders. Monster ages are explained in species terms. Social standing affects equipment storytelling, not innate worth. Proposed stats are starting balance budgets, not playtest results.

The ending recognizes both accountability and mercy: forgiveness disarms the Demon King and begins reparations; refusing forgiveness seals his crown and removes his authority without a gore spectacle. Survivor portraits, rescue choices and negotiations shape title cards.

## Deliverable honesty

Generated images are concept boards with key poses. They may contain lettering, proportion or equipment inconsistencies and require artist cleanup. They are not engine-ready transparent atlases or finished 8-direction animation packs. The JSON and written specifications cover every requested model and visual state; they make that remaining production work explicit rather than calling stills finished motion.
