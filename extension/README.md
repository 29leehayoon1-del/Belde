# Belde — Connected Commander

This Chrome Manifest V3 extension edits the running Belde PC game. It is not a second game. The popup and detached editor share one service-worker/native-host connection and one editor lease.

## Install

1. Extract the complete Belde download. Open `chrome://extensions`, enable **Developer mode**, choose **Load unpacked**, and select this `extension/` directory.
2. Run the matching per-user native-host installer in `native/`. See [native instructions](../native/README.md). The stable unpacked extension ID is `ngolglhaedkpheljgabbfafifbimmlle`; installers validate the exact authorized ID and do not allow wildcard origins.
3. Start Belde on the same computer. Enter its six-digit editor code in the extension, then choose **Pair**.
4. Choose **Open full editor** for the map canvas. Keep the extracted game/native files in place after installation; moving the registered executable requires rerunning the installer.

The manifest contains a public extension identity key. It is not a credential. No signing private key is shipped.

## Editing

- Drag or click to place towers, traps, or party members. Towers use marked stone pads and keep enemy lanes clear; allies can engage enemies on the lanes. Drag a placed unit to reposition it.
- Drag a ranged party member onto a Palisade Roost to occupy it. Cover reduces incoming projectile damage by 25%; basic ranged accuracy becomes 85% versus 100% on the ground.
- Choose Guard, Patrol or Advance. Units attack according to the PC simulation; the editor only displays periodic snapshots.
- Click connected patrol waypoints and apply the route (up to 64 nodes). Preview colors, hatching, range rings and route markers aid placement; the PC performs final collision, economy and route checks.
- Select a tower to upgrade, or a tower/trap to salvage. Undo/redo changes authored layout history. During combat, safe layout edits are queued by the game until planning resumes.
- A conflict never triggers an automatic overwrite. Refresh and review the current PC layout before resubmitting.

## Pairing and session scope

The bridge binds only to `127.0.0.1:43127`. It accepts the installed native host's JSON requests, rejects browser `Origin` requests, requires a cryptographically random pairing token after PIN authorization, and expires abandoned editor leases after 15 seconds. A second editor receives the exact multiple-instances warning. An explicit takeover requires the current PC pairing code.

By default, this prevents competing PC/editor sessions **on one computer**. It cannot identify the same player on an unrelated computer. The optional self-hosted profile coordinator and Godot client provide a cross-device lease when configured; see `native/session-README.md`. No remote service, account credentials or hosting is deployed automatically.

## Validation

- C and Python native framing/HTTP transport tests run against real sockets.
- Godot bridge tests cover pairing, authentication, leases, duplicate instances, HTTP validation and revision conflicts.
- The actual `background.js` logic is exercised through a Node Chrome-Port adapter, the C host and a real Godot bridge.
- Editor/popup DOM, grid placement, route preview, drag/drop, modes, tracks, history and reconnect are tested in Chromium with the Chrome Port transport mocked explicitly.
- Full native Chrome installation is a separate check. In the cloud test machine, managed Chromium policy blocks all unpacked extensions; `tests/bridge_extension_test.py` reports **SKIPPED (exit 77)** rather than claiming that integration passed. No managed browser policy was changed.

The Windows host is cross-compiled but cannot be executed on Linux. The macOS launcher uses a local Python 3 interpreter or a locally compiled C host; macOS-specific installation still needs testing on a Mac.
