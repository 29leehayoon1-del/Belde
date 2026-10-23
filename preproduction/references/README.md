# Visual research

Research performed 2026-10-22. Direct documentation requests returned HTTP proxy 403. Official source mirrors below returned HTTP 200; these sources, rather than inaccessible pages or image-search thumbnails, informed this package. This is targeted reference research, not an exhaustive survey or a claim that this is the best tower-defense game.

- [Godot: multiple resolutions](https://github.com/godotengine/godot-docs/blob/master/tutorials/rendering/multiple_resolutions.rst): integer scaling preserves consistent pixel sizes. Use a 640×360 gameplay design resolution with integer scaling and letterboxing. Editor and artbook use independent layouts.
- [Godot: 2D sprite animation](https://github.com/godotengine/godot-docs/blob/master/tutorials/2d/2d_sprite_animation.rst): separate named animation clips and explicit frame rates. The accompanying contract fixes clip timing and visual event markers; actual Godot resources are intentionally deferred.
- [Chromium: Action API](https://github.com/chromium/chromium/blob/main/chrome/common/extensions/api/action.json): an action popup is a small browser surface; provide a compact status/quick-edit view and a separate full editor window. Exact production popup sizing must be checked against the targeted Chrome release.
- [Chrome: Native Messaging](https://github.com/GoogleChrome/developer.chrome.com/blob/main/site/en/docs/extensions/mv3/nativeMessaging/index.md): an installed host communicates with the extension through structured messages. Connection state, validation, conflict and reconnect feedback need explicit visual states. This package implements neither host nor extension.

Original character and scene designs are used throughout. The supplied game links are mood references, not copied sprite sources. No commercial game's character, sprite sheet, logo, or interface is included.

Raw fetch outcomes and short source observations are recorded in `research.json`.
