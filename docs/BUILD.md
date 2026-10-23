# Building and checking Belde

The desktop project is in `game/`. It uses the **official Godot 4.6.3 standard editor**, GDScript and the Compatibility renderer. A C compiler builds the optional Chrome Native Messaging host. The connected editor is a Chrome Manifest V3 extension, not another copy of the game.

## Development environment

On the prepared cloud machine, the verified tools and dependencies are retained under `.tools/`. They are development dependencies, not files the player must download. Use the existing checkout; each cloud task is already isolated, so no Git worktree is needed.

From the repository root:

```sh
source tools/runtime_env.sh
godot --headless --editor --path game --quit
godot --path game
```

`runtime_env.sh` keeps Godot's XDG data, configuration and caches under this checkout. It never changes `HOME`. Player builds use the normal platform application-data location instead. Local `.tools/`, `.runtime*/`, `build/`, `dist/` and Godot import caches are ignored by Git.

## Recreate the export prerequisites

On the Debian 13 x86-64 cloud build machine:

```sh
python tools/setup_godot.py
python tools/setup_native_tools.py
source tools/runtime_env.sh
```

The first command reuses an existing official Godot 4.6.3 editor when available. If it is absent or another version is installed, it downloads the official Linux x86-64 editor into `.tools/godot/editor/`, verifies its SHA-512 against both a pinned digest and the official checksum list, and links `.tools/bin/godot`. It then prepares the official 1.26 GB export-template archive once. Its SHA-512 must also match both the pinned verified checksum and Godot's official `SHA512-SUMS.txt`; a mismatch stops extraction. Templates are registered under the workspace XDG data directory. Valid downloads are reused. On another development OS, install the matching official Godot 4.6.3 editor yourself before using this Linux-host setup fallback.

The second command downloads seven pinned Debian packages, verifies each package's SHA-256 obtained from Debian's signed archive metadata, and extracts them locally. It supplies a MinGW Windows cross-compiler and Xvfb without installing system packages. This fallback is for the Debian 13 x86-64 build host. On another Linux distribution, use an appropriate native C compiler, MinGW and Xvfb for that host instead of assuming Debian binaries will run.

Trust records are in `.tools/godot/editor-verification.json`, `.tools/godot/verification.json`, `.tools/godot/macos-thin-provenance.json` and the tracked `tools/toolchain-packages.json`. No TLS, package-signature or checksum checks are disabled.

Godot's official macOS templates contain universal binaries. `setup_godot.py` derives Intel and Apple Silicon templates by extracting the exact matching architecture byte ranges from those verified Mach-O binaries, equivalent to `lipo -thin`. It does not alter executable instructions or replace expected checksums. The derived templates receive separate SHA-256 provenance records. Godot applies its built-in ad-hoc signature to each exported application.

## Checks that exercise the implementation

```sh
source tools/runtime_env.sh
python tools/run_checks.py
```

This runs the authored campaign/content suite, real combat simulation, actual scene/button callback flow, both native-host transports, the live Godot loopback bridge and the optional authenticated profile coordinator. Each run uses isolated XDG data and a separate bridge port. The scene flow test covers recruitment, layout commands, cooldowns, saves, all act transitions and the character codex using the headless display; it does not claim mouse, GPU or visual review. The coordinator tests use actual HTTP requests and Godot clients. The runner preserves process exit codes and requires a nonzero test/check count. Logs and counts are recorded in `build/checks/results.json`; missing, failing or zero-test outcomes fail the runner.

For a real graphical run on the cloud machine:

```sh
PATH="$PWD/.tools/bin:$PATH" xvfb-run -a -s '-screen 0 1440x900x24 -nolisten tcp' \
  python tools/gui_capture.py --output build/review/title.png
```

The helper launches Godot with an actual OpenGL window on Xvfb, can send real mouse/keyboard events through XTest, captures the display, and requires a clean process exit and a nonblank image. This verifies graphical startup, not the whole campaign. Add ordered `--action 'click:x,y'`, `--action 'key:Return'` and short `--action 'wait:0.5'` arguments to inspect a particular interface path; use `--frames` for a longer capture session. It does not modify artwork.

## Build desktop packages

```sh
source tools/runtime_env.sh
python tools/build_game.py --platform all
python tests/test_delivery.py
python tools/verify_macos.py
python tools/smoke_linux.py --ui-flow
```

Individual targets are `windows`, `linux`, `macos-arm64` and `macos-x86_64`. Use `--skip-import` only when the existing import is valid and project assets have not changed. Use `--export-only` for engine export diagnosis without assembling a distributable package.

Outputs are:

| Package | Platform | Startup |
| --- | --- | --- |
| `dist/Belde-Windows-x86_64.zip` | Windows x86-64 | Extract all, run `Belde.exe`; keep `Belde.pck` beside it. |
| `dist/Belde-Linux-x86_64.zip` | Linux x86-64 | Extract all, run `./Belde.x86_64`; keep `Belde.pck` beside it. |
| `dist/Belde-macOS-arm64.zip` | Apple Silicon Mac | Extract all, open the `.app` bundle. |
| `dist/Belde-macOS-x86_64.zip` | Intel Mac | Extract all, open the `.app` bundle. |

Each package contains the playable engine export, extension source, native host/source and platform registration scripts, startup instructions, and Godot's license/third-party notices. Windows includes a compiled x86-64 PE native host; Linux includes a native ELF host. macOS uses the portable Python host, so **Python 3 is required only for its optional connected editor**, not to run the game.

The exporter records SHA-256 checksums and byte sizes in `dist/build-manifest.json`, checks ZIP CRCs, and rejects a package at 95 MiB or larger so a single artifact stays below GitHub's 100 MiB file limit. The delivery tests also check archive paths, required files, native executable architecture, macOS thin architecture and Unix execute permissions. `smoke_linux.py` launches the actual packaged Linux executable and adjacent PCK in isolated headless title and battle-preview sessions. The release template omits the external `--script` option, so `--ui-flow` uses the matching editor engine with `--main-pack` to run the callback harness against exported PCK resources. It records each scope separately and updates the manifest's Linux execution status. These checks do not claim graphical testing or native execution of Windows/macOS builds on the Linux host.

The macOS builds are ad-hoc signed and are **not notarized by Apple**. `verify_macos.py` checks their thin CPU architecture, every embedded CodeDirectory page hash and the bundle's sealed resource hashes, including the PCK. That is structural/hash validation on Linux, not Apple's `codesign` or Gatekeeper validation. The builds may need explicit approval in macOS Privacy & Security when downloaded. A signing certificate, notarization credentials or an account service is not invented or bundled. Native execution on Windows/macOS must be distinguished from Linux export and package validation.

## Connect the browser editor

The game works on its own. To add the editor:

1. Extract the desktop package into a permanent folder.
2. In Chrome Extensions, enable Developer mode and load the bundled `extension/` folder unpacked.
3. Review and run the matching script under `native/` to register the host for that extension ID. The installer uses the current user's profile; do not register wildcard extension origins.
4. Start Belde and enter the pairing code displayed by the game into the extension. Use **Open Full Editor** for the large map editor.

The game is authoritative. The extension shows accepted, pending, conflicting and disconnected edits, and uses the same layout revision and unit roster. Native Messaging connects through the loopback bridge; no external server credential is required for that local workflow. A single local PC game owns the bridge port and one editor session receives an expiring lease. Cross-device account enforcement requires the optional shared authenticated coordinator described in `native/session-README.md`; it is implemented and tested but has not been deployed. Local port/lease checks alone must not be described as global device enforcement.

## Delivery and publication

Builds and caches are ignored to avoid accidentally committing large generated files. A reviewer can inspect source and checks before any selected `dist/*.zip` is explicitly added for delivery. Use the existing Belde GitHub repository for the approved download workflow; uploading source does not automatically host `index.html` as a website or create a release page.

Run `python tools/package_source.py` after the final edits to create `dist/Belde-Source.zip` and its SHA-256 manifest. It includes the editable runtime project, tools, tests, docs and the original JSON inputs used by the data compiler. It excludes downloaded dependencies, compiled native hosts, generated imports and earlier concept-board images. The original artbook remains available separately in the repository. This archive receives the same 95 MiB size limit and ZIP CRC verification as the desktop packages.

The earlier `preproduction/` artbook remains a visual reference. Production game code and runtime assets are in `game/`; build artifacts must be judged from the latest source and actual test results, not from the concept boards alone.
