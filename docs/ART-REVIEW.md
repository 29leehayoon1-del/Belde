# Gameplay art review

The game now has actual PNG gameplay artwork, rather than rendering labeled preproduction boards as units. The original boards remain in `preproduction/art` for comparison. All new image creation and corrections used the image-generation tool; files were copied unchanged. Pillow was used only to inspect alpha channels, dimensions, hashes and sampling bounds. No color-key removal, pixel recoloring, scripted drawing or image resampling was used to manufacture these assets.

## Installed coverage

| Asset | Files | Coverage |
| --- | ---: | --- |
| Allied pose atlases | 11 PNGs | All 58 recruit IDs: Bar 6, Kingdom 15, Village 10, Capital 10, Prison 12, Generals 5 |
| Enemy pose atlases | 3 PNGs | MOB01–MOB08 and BOSS01 Avarren |
| Battlefield background atlas | 1 PNG | MAP01–MAP06, three columns by two rows |
| Menu illustration | 1 PNG | Tornel and Maela overlooking the warm gate, with surrendering monsters; quiet space on the left for live menu text |

The 67 actors have eight indexed pose/effect slots each: idle, left-foot walk contact, right-foot walk contact, run, attack, ability A, ability B, downed or surrender. That is 536 sampled slots, including the effect-layer exceptions below. These are gameplay key poses for the current prototype, **not finished full-frame, eight-direction animation packs**. Walking can alternate the two contact poses; further in-between frames, directional views, hit reactions and polished release/recovery clips remain future art work.

## Sampling contract

- `game/assets/actors/manifest.json`: dictionary keyed by all 58 recruit IDs.
- `game/assets/enemies/manifest.json`: dictionary keyed by the eight MOB IDs and BOSS01.
- Each entry declares `file`, zero-based `row`, `rows`, `cols: 8`, and a `frames` dictionary.
- Column order is idle 0, walk_a 1, walk_b 2, run 3, attack 4, ability_a 5, ability_b 6, downed 7.
- Use `row_bounds_px[row]` and `row_bounds_px[row+1]` for the sampled vertical range. Generated images did not preserve mathematically equal row spacing; an equal-height fallback clips some heads or feet.
- `idle_bounds_px` is `[x,y,width,height]` relative to the sampled idle cell. It describes visible alpha ink (threshold 128), excluding tiny isolated specks and detached neighboring-row fragments. Scale from the idle ink height, retain source aspect ratio, and anchor the feet at its bottom edge; do not stretch every cell to a square. This is read-only metadata analysis, not a pixel edit.
- Columns divide the image width into eight equal fractions. Enemy images can have widths that are not integer multiples of eight; keep sampling coordinates fractional or round both boundaries consistently.
- Avarren is one horizontal strip inside a larger transparent canvas; its manifest supplies the tight strip in `row_bounds_px`.
- `game/assets/world/manifest.json` maps MAP01–06 to a `file`, `col`, `row`, `cols: 3`, `rows: 2`, and an explicit `rect_px`. Each scene is 512×512 in the 1536×1024 atlas. The gameplay field can scale this scenic backdrop; actual editable routes, collision, units and telegraphs are drawn separately.
- `game/assets/ui/manifest.json` names the menu illustration at `res://assets/ui/title.png`.

Actors face the canonical south-east three-quarter direction. Weapon asymmetry and other compass directions have not been authored. Preserve nearest-neighbour sampling for pixel-art presentation.

## Effect layers

The image model retained a few effect-only ability cells. Their entries explicitly declare `effect_only_frames`, so the runtime can keep the idle body visible underneath that effect:

| ID | Effect-only slots |
| --- | --- |
| BAR01 | ability_a |
| KIN08 | ability_a |
| KIN09 | ability_a |
| KIN12 | ability_a |
| VIL03 | ability_a |
| PRI05 | ability_a, ability_b |
| PRI07 | ability_b |
| MOB07 | ability_a |
| MOB08 | ability_a |

This is an explicit layered-body exception, not a claim that those cells contain complete animated actors. Other ability poses can include translucent decoys or shield recipients as part of the drawn effect; these are illustrative pixels, not extra game entities.

The generals received a second image-tool correction: their first-column portrait-like models became full-body idle poses, Siltwake's movement/attack prop was corrected to a short blowpipe, and Veyra's lantern/staff was replaced by the canonical short silk spindle and luminous scales. A trial Tornel ability-body correction crossed its column boundary, so the clean original effect layer was retained instead and marked for an idle underlay.

## Checks performed

`game/assets/actors/atlas-review.json` records native dimensions, source output filename, SHA-256, transparent-pixel fraction, alpha samples, vertical row bounds and per-slot visible-alpha bounding boxes. All 14 actor/enemy atlases are RGBA and have real transparent pixels; roughly 35–61% of their pixels are fully transparent. Every one of the 536 sampled slots contains visible content. The battlefield and title images are opaque illustrations as intended.

All 58 recruit IDs and nine enemy IDs resolve to existing files. Source-output hashes were checked against the installed PNGs. No labels, grid borders or portrait cards remain in the gameplay atlases. The six scenery fields contain no painted enemy tracks, patrol dots, text or HUD.

Visual inspection found minor remaining cell-edge halos/contacts around Bar row 5/6 and Prison row 2/3/6. The supplied per-row bounds avoid the larger equal-grid clipping issue, but they do not establish final pixel-perfect isolation. Some movement poses are close variants and some weapons/VFX still need an artist's consistency pass. These are known prototype-art limits; automated nonempty/alpha checks do not validate anatomy, identity, motion timing or combat readability.

## Remaining art work

Review actual in-game scale and foot placement, refine the small cell-edge contacts, replace composited effect exceptions where a new body gesture is required, and author the remaining directional/transition frames. Audit every weapon and ability against the JSON roster before calling this final production art. Combat balance, session behavior, editor synchronization and executable validation belong to the separate game implementation and its tests; this art review makes no claims about those systems.
