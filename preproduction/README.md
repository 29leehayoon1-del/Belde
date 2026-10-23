# BELDE — The Wrong Commander

Original pixel-art visual preproduction for a five-act story-driven tower-defense game and connected editor.

**Start with `index.html`** in a browser. It works from disk without a server. It is a reference artbook, not the game or an extension.

## Contents

- `art/`: 21 generated original concept boards, generation briefs and a board manifest.
- `data/first-recruits.json`: Bar 6, Kingdom 15, Village 10.
- `data/late-recruits.json`: Capital 10, Prison 12, Monster Generals 5.
- `data/world.json`: eight enemy mobs, the Demon King, maps, visual storyboards and animation contract.
- `data/title-candidates.csv`: 2,000 unique full title-card candidates for later editorial review.
- `data/coverage.json`: verified asset inventory and explicit production scope.
- `design/`: art direction, complete model briefs, motion/VFX specifications and production acceptance checklist.
- `references/`: online documentation research with actual fetch outcomes.
- `tools/build_artbook.py`: rebuilds the static catalog after reference-data or board-manifest updates, using Python's standard library only.

## What is delivered

A visual identity, all 58 recruitable model definitions, exactly two proposed abilities per recruit, stat targets, recruitment introductions, portraits/appearances, motion and effect directions, enemy models, branching battle-map layouts, recruitment locations and interface concept designs. Image boards cover every recruit with reference key poses; the machine-readable catalog supplies authoritative names, abilities and design details.

## What still needs production

Generated boards are reference artwork. They are not transparent, uniformly sliced, pixel-perfect sprite atlases. Full per-frame motion clips, eight-direction variants, consistent hand-painted cleanup, UI fonts/icons, final tilesets and in-engine animation timing still require production and review. Numbers are balanced starting budgets, not verified balance or playtest results. No game logic, networking, authentication, bridge, extension, installer or executable is part of this visual-only pass.

The recovery-recruitment wording in the brief is ambiguous. This package proposes five newcomers after defeat or at most one surviving original ally, otherwise three; see the art direction and world design for the complete assumption.

## Review order

1. Confirm the silhouettes and palette in the concept boards.
2. Inspect each recruit's appearance, portrait, two abilities and motion directions in the catalog.
3. Check the six maps, route readability, monster surrender states and final-choice storyboard.
4. Approve or revise the visual direction before authoring production sprite sequences or implementing gameplay.

Read `design/board-review-notes.md` for specific concept-board interpretation notes. Generation briefs preserve the inputs used for initial images; current model data includes subsequent consistency corrections.
