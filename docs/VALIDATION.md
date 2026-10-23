# Build validation — 23 October 2026

The tested workflow uses Godot 4.6.3 on Debian 13 x86-64. The game is a playable prototype; these results do not establish final balance or finished animation quality.

`python3 tools/run_checks.py` completed successfully with these nonzero counts:

| Suite | Checks or test cases | Scope |
| --- | ---: | --- |
| Campaign/content | 587 | All roster counts, 116 abilities, story choices, recruitment/recovery rules, endings and campaign saves |
| Combat smoke | 20 | Live waves, commands and deterministic save continuation |
| Combat regression | 567 | Ability execution, enemy abilities, defensive effects, targeting, placement/history, real first battle, gate capacity and health rewards |
| Actual scene flow | 300 | Main scene and button callbacks, recruitment, placement, cooldowns, queued edits, corrupt saves, all acts, both general choices, all 58 introductions and epilogue |
| Native transport | 9 | C/Python framing and actual loopback forwarding |
| Godot bridge | 11 | Pairing, token/lease behavior, origin/host validation, limits and fragmented HTTP |
| Profile coordinator | 9 | Authenticated contention, takeover, renewal, release, expiry and service-outage behavior with real Godot clients |

The runner checks both exit codes and Godot error output, isolates save directories/bridge ports, and writes exact counts/logs under ignored `build/checks/`. The data compiler was rerun after correcting inherited preproduction scope metadata; its resulting catalog again passed all 587 campaign/content checks.

The scene-flow harness injects battle outcomes to exercise navigation; it is not a combat playthrough. Separate combat scenarios demonstrate a two-ally Kingdom opening with survivor carryover through MAP02, independent late-map victories and an actual phase-three boss kill. Exact conditions and remaining balance limits are in [COMBAT-AUDIT.md](COMBAT-AUDIT.md).

Additional editor checks passed using the actual JavaScript modules and a deliberately adapted Chrome Port transport: background worker → C native host → actual game callbacks, plus headless popup/editor UI checks. The real-game integration covers roost assignment, unit placement on enemy lanes, patrol orders, connected tracks, the 64-point limit, history, conflicting revisions, and preservation of queued edits after a duplicate wave-start request. Details are in [bridge-validation.json](../tests/bridge-validation.json).

Full installed-extension testing is **skipped (exit 77)** because this cloud browser's managed Chromium policy blocks extensions. The policy was left intact. Transport/UI tests are not described as an installed-extension pass.

The four desktop exports are checked for ZIP integrity, required files, executable architectures and permissions. Mac code-page hashes and sealed resources are checked on Linux; those checks do not establish Gatekeeper approval or native macOS execution. The packaged Linux executable and adjacent PCK are launched in isolated headless title and battle-preview checks. Godot's release template omits the script-runner option, so the exported-PCK scene-flow harness uses the same-version editor engine with `--main-pack`; it does not claim that the release executable ran that harness. Final archive sizes, checksums and execution scope are recorded in [build-manifest.json](../dist/build-manifest.json).

The title screenshot in [README](../README.md) is an actual game title capture. An earlier splash-only capture was rejected; a later graphical test was canceled, so the final battle interface has not received a completed GPU/mouse visual review in this build pass. No further graphical launch was made after that cancellation.

Windows/macOS native execution, normal-desktop Chrome installation, full human campaign playtesting and a final art consistency/animation pass remain outstanding. The optional coordinator is implemented and tested locally; no hosted account service or physical cross-device deployment is claimed.
