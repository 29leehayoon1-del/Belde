# BELDE visual production checklist

This checklist separates the visual model and concept package from the assets still needed for a playable release. A contact-sheet pose is a reference, not a completed animation clip. Nothing below asserts that engine resources, working browser synchronization, session enforcement, game balance or a downloadable build have been implemented.

Use `art-direction.md`, the per-character JSON and `world-and-animation.md` together. Character model data controls identity and ability specifics; the shared animation contract controls technical layout and timing. Resolve conflicting design notes before drawing final frames.

## 1. Lock scope before implementation

- [ ] Approve all **58 recruitable models**: bar 6, kingdom 15, village 10, royal capital 10, prison 12, monster generals 5. There are 53 recruits across the five locations and 5 monster generals; generals are not a second copy of the same five roster entries.
- [ ] Approve all **8 ordinary enemy species plus the Demon King**, including movement, attack, ability and surrender/noncombatant cues where applicable.
- [ ] Approve **6 battle-map layouts**, **5 recruitment locations**, the five-act storyboards, the rescue/negotiation scenes, and both final choices.
- [ ] Approve four class silhouettes, tower/trap/track families, the compact extension surface, detached editor, recruitment cards, combat HUD and title-card layout.
- [ ] Treat all HP, damage, healing, cooldown and movement numbers as proposed budgets until playtesting. Wealth, nobility and prison status are character context, not a license to give one origin a universal power advantage.

## 2. Character identity gate — repeat for every ID

- [ ] Stable ID, name, adult age/species age, origin, class, portrait, introduction and story hook match the JSON.
- [ ] Portrait, full body and downed pose agree on hair, skin, horns/ears, clothing, body proportions, dominant hand, weapon, accessory and accent colors.
- [ ] A grayscale silhouette distinguishes the recruit from the other members of the same class. Test at native gameplay size before adding ornament.
- [ ] Recruitment portrait feels like the same individual as the small sprite. Show age, expression and personality without depending on captions.
- [ ] Include a neutral standing model, front/side/back equipment notes and the SE key-pose reference. Other directions must preserve unique asymmetric equipment.
- [ ] Include an elevated ranged variant where applicable. Its platform and shield cue must remain separate from the unit body; the protection/accuracy tradeoff gets both a shield symbol and spread-reticle cue.
- [ ] Downed models preserve recognizable heads/equipment and a clear rescue point. Avoid gore, gratuitous restraints and visual jokes at prisoners' expense.

## 3. Clip and direction gate

Final frame counts, rates, action event timing and direction order must match the `animation_contract` in `data/world.json` and the written world specification. Do not derive sheet slicing from generated concept-board spacing.

Canonical one-direction schedule (repeat for all eight authored directions):

| Clip | Frames | Rate | Event/loop requirement |
| --- | ---: | ---: | --- |
| Idle | 4 | 6 fps | Seamless planted-foot breath loop |
| Walk | 6 | 10 fps | Alternating contact/passing loop |
| Run | 8 | 14 fps | Contact and airborne/passing beats |
| Basic attack | 6 | 12 fps | Tell 1–3; contact/release 4; recovery 5–6 |
| Ability A | 8 | 12 fps | Tell 1–3; release 4; active 4–5; recovery 6–8 |
| Ability B | 8 | 12 fps | Tell 1–3; release 4; active 4–5; recovery 6–8 |
| Hit | 3 | 12 fps | One-shot recoil and return |
| Downed | 6 | 10 fps | One-shot; hold endpoint |
| Surrender/truce | 4 | 8 fps | Lower weapon; hold peaceful endpoint |
| Portrait | 4 | 4 fps | Optional blink; first frame is static snapshot |

The eight core body clips total **49 frames per direction**, **392 body frames per character** and **22,736 body frames across 58 characters**, before extra clips, moving-attack variants, portraits or separate VFX. This is a remaining production inventory, not a count of finished drawings in this package. Enemy/boss attacks may hold their tell longer according to the individual model; do not shorten a designed warning to fit a generic playback rate.

- [ ] Produce complete **idle, walk, run, basic attack, ability A, ability B, hit and downed** clips for every recruit. A single walk-contact or run-passing pose does not satisfy a clip.
- [ ] Author eight directional views: **S, SW, W, NW, N, NE, E, SE**. Initial concept sheets show SE; the other seven are remaining production work.
- [ ] Check every loop over at least three repeats: no foot sliding, pivot drift, popping shadow, involuntary facing change or seam jump.
- [ ] Walk alternates left and right foot contact; run contains a visible passing/airborne beat appropriate to the species. Equipment follows body motion rather than wobbling independently.
- [ ] Every attack contains readable anticipation, a documented active event frame and recovery. The attack's visual contact and projectile emission occur on the planned event marker.
- [ ] Patrol attacks retain a stable locomotion base or explicitly authored moving-attack variant. A stationary sword-swing sheet cannot claim attack-while-walking coverage.
- [ ] Hit reactions stay short enough to read and do not silently imply a gameplay stun. Downed is a one-shot that holds its terminal frame; it never loops back upright.
- [ ] Ability clips have distinct silhouettes and effects from the basic attack and from one another. Review bodies with VFX hidden, then VFX with bodies hidden.
- [ ] Directional mirroring is reviewed individually: do not flip readable symbols, instrument strings, scabbards, shield emblems or handed weapons without correction.
- [ ] Add a visible clip inventory per ID and direction so missing frames cannot be mistaken for intentional holds.

## 4. VFX gate — two abilities per recruit

- [ ] Exactly **116 distinct ability entries** cover 58 recruits. Similar effects may share a material language, but names, shapes and timing must communicate each recruit's function.
- [ ] Each entry has tell, windup, active effect, impact, recovery and persistent-state cleanup notes; specify layers and the attachment/ground point.
- [ ] Heals use round/four-pip positive markers and upward motion; Tanker guards use square brackets; DPS uses directional strikes; Strategist traps use hexagons/dotted traces. Color supplements shape.
- [ ] Telegraph footprint matches intended area. Ground warnings remain visible through units, tower platforms and friendly effects.
- [ ] Friendly effects use filled pale centers; hostile warnings use hollow chevrons and broken pale edges. Validate in grayscale and common color-vision simulations.
- [ ] Provide projectile travel, impact, miss, blocked and shield-absorbed variations where the ability requires them; never reuse a hit flash as proof that a miss dealt damage.
- [ ] Persistent buffs, trap markers and healing trails end cleanly. No orphan particles remain after downing, cancellation, scene changes or surrender.
- [ ] Define a reduced-flash/reduced-shake look. Avoid rapid full-screen flashes; important information survives when decorative particles are reduced.

## 5. Enemy and boss gate

- [ ] Every mob has a readable footprint and silhouette at the same camera angle as allies, with idle/walk/run or species-appropriate movement, attack, hit, downed/defeated and special-ability clips.
- [ ] Swarm enemies remain distinguishable in a crowd. Differentiate species using body scale, gait and carried objects, not only recoloring.
- [ ] Each attack/ability has an explicit tell, windup, active frame, recovery and projectile/ground-effect shape; boss-scale attacks allow a substantially larger warning footprint.
- [ ] All five generals have hostile command and recruitable ally presentations that preserve identity. Their team markers, targeting cues and formation banners change when allegiance changes.
- [ ] Noncombatants use open hands/luggage and lack target reticles. Surrender uses lowered weapons plus a white tied cloth and an unambiguous action pose.
- [ ] Demon King model has an oversized body/VFX canvas, clear phase/stance distinctions, telegraph thumbnails, attack landmarks and both ending poses.
- [ ] Boss spectacle does not obscure the nearest enemy route, allied feet, gate health or a rescue prompt.

## 6. Environment and route gate

- [ ] Each of the six maps includes a top-down route plan, three-quarter art study, enemy entry/exit arrows, gate footprint, deployment bounds, tower pads, rescue/interaction points and clear terrain elevation.
- [ ] Main and alternate enemy routes are legible from the first wave. Chokepoints remain wide enough to distinguish multiple units; decorative roads do not imply usable routes accidentally.
- [ ] Allied patrol rails use cyan dashed double lines; enemy routes use ochre ground, footprints and red gateward arrows. Add shape/texture cues so the routes differ without color.
- [ ] Show route-node, turn, crossing, blocked-placement and disconnected-track states. A crossing illustration states which track passes above/below or how the lanes meet.
- [ ] Provide background, walkable ground, foreground occluder, collision silhouette, tactical overlay and lighting notes separately. Tall scenery can fade/outline around units in the eventual implementation.
- [ ] Reuse a consistent 32×32 tile grid. Mark tilesets, transitions, cliffs, stairs, water edges, rubble, breakable props and impassable silhouettes.
- [ ] Each map has at least one quiet readable area for decision dialogue and one wide composition for a major wave; storyboard cameras preserve landmark continuity.

## 7. Towers, traps and deployment modes

- [ ] Every tower family has build/ghost, construction, ready, firing, damaged, disabled and destroyed/salvage states, plus upgrade silhouettes that remain recognizable at a glance.
- [ ] Ranged occupancy has a separate socket/pivot and unobstructed weapon exit. The tower does not turn melee recruits into implausible ranged attackers.
- [ ] Trap families show setup, armed, triggered, spent and dismantled states. Arming/triggering footprints match the planned trigger area.
- [ ] Guard uses a circle, Patrol a double arrow and Advance a spearhead. Include selected/unselected, hover and unavailable icon states.
- [ ] Selected units display a readable base ring and class badge without covering foot placement, hostile warnings or pickup/rescue prompts.
- [ ] Drag previews include valid placement, invalid collision, out-of-bounds, blocked route, snapped placement, rotation, cancellation and confirmed placement. Invalid previews use hatching/crosses as well as color.
- [ ] Range rings, patrol arrows and upgrade footprints remain readable at native resolution and on all six map palettes.

## 8. Recruitment, story and ending visuals

- [ ] Five locations each have an establishing scene, recruiter foreground, candidate portrait space, candidate-list states, introduction dialogue frame and selection confirmation.
- [ ] Every candidate's card includes name, class icon/label, HP, basic damage/interval/range, two named abilities with cooldowns, readable visual ability thumbnails and a clear selection count.
- [ ] Initial recruitment clearly shows **two choices** from the selected bar/kingdom/village pool; monster-general negotiation shows **two of five** after victory.
- [ ] Act IV recovery art communicates the proposed rule: five newcomers after defeat or at most one surviving original ally; otherwise three. Flag this rule as an assumption for approval, not a settled implementation.
- [ ] Include early victory and defeat, surrender noticed/ignored, negotiation accepted/refused, rescue choice, siege casualty/survival, reinforcement and final-boss story panels.
- [ ] Forgiveness shows disarmament and accountability/reparations; refusal shows removal of the crown/authority. Both retain surviving allies in the composition without requiring graphic punishment.
- [ ] A reusable title-card system supports thousands of written combinations using prefixes/epithets/deeds and survivor/choice seals. This is a layout/composition system, not thousands of separately painted images.

## 9. Interface and synchronization visuals

- [ ] Desktop HUD covers wave progress, gate health, resources, selected unit, two cooldowns, upgrades, speed/pause, recruitment/rescue prompts, dialogue and end-of-act transition.
- [ ] Menus cover new run, continue, settings, input hints, accessibility, save-slot version warning, reconnect and error states. Settings distinguish motion, flash and screen-shake controls.
- [ ] Compact extension concept shows connection status, profile, selected unit/tool, recent edit and an explicit open-editor-window action. Detailed maps belong in the detached editor study.
- [ ] Editor concepts cover palette, grid snapping, route nodes, unit/tower placement, collision feedback, undo/redo, pending edit, accepted edit, rejected edit and authoritative-state refresh.
- [ ] PC-authoritative synchronization is visible through connected, editing, syncing, conflict, reconnecting and offline states. Never imply that a static mockup verifies a live connection.
- [ ] Include an expired-session/recovery view that does not visually imply a permanent lock after a crash.
- [ ] Use the requested paired-session warning text: **Multiple Game Instances Detected** — “Your game is currently active on another device or platform. Only one active PC gameplay session and one connected editor session are permitted.” Action: **Disconnect other session to continue**.
- [ ] Normal connected status treats the PC game and its authorized editor as one pair. Conflict illustrations distinguish a second gameplay launch from the permitted companion editor.
- [ ] Labels, status icons and focus states remain readable against pixel-art backgrounds. Text is not baked into sprites that need localization.

## 10. Export and handoff gate

- [ ] Ordinary ally artwork fits a 32×48 model inside a 64×64 production cell; large enemies use 96×96 and boss body uses 160×160 unless an explicitly documented exception is approved.
- [ ] Portraits export at 96×96; recruitment busts at 192×256; gameplay composition targets 640×360 with integer scaling and letterboxing.
- [ ] Body, shadow, weapon, projectile, impact, aura, ground warning and UI icon layers can be reviewed/exported separately. Do not bake a floor color into a sprite intended to be transparent.
- [ ] All ordinary clips use foot pivot **(32,56)** in a 64×64 cell; large enemies use **(48,84)** in 96×96, and the boss uses **(80,136)** in 160×160. All clips for one model share that documented ground pivot. Raised weapons and VFX may extend past the body footprint without moving the feet or selection center.
- [ ] PNG RGBA outputs use consistent cell dimensions, transparent backgrounds, no antialiasing, no accidental semitransparent halos, and enough atlas padding to avoid neighboring-frame bleed.
- [ ] Keep editable layered source files and a palette file alongside exports. Apply the naming convention `BELDE_<ID>_<STATE>_<DIR>_<FRAME>` and a manifest declaring canvas, pivot, frame rate, loop mode and event markers.
- [ ] Check actual alpha, dimensions, cell count, file names and sheet order with an asset audit. Visual inspection alone cannot establish a valid atlas.
- [ ] Preview at native size, 2× and 3× integer scale; verify silhouette readability, UI scale and alignment. Do not blur pixel clusters through fractional display scaling.
- [ ] Inspect a compiled preview of every final clip and note review status. A still image, generated GIF from repeated identical frames, or unexecuted import instruction is not animation validation.

## Current package versus next production pass

The current package is **visual preproduction**: full model descriptions, proposed statistics/abilities, key-pose concept boards, world/story direction and static interface studies. Generated lettering and tiny costume details may be inconsistent; authoritative identity and numbers live in the catalog.

Remaining asset production includes cleanup of every approved design, full directional frame drawing, moving-attack blends/variants, separate VFX sequences, transparent exports, atlas manifests, final UI/tile assets and an animation review. Engine imports, application behavior, live synchronization, session security, platform packaging and gameplay balancing belong to the later implementation phase. Do not mark those tasks complete from this art package.
