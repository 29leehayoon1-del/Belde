# Belde native messaging host

This small C executable connects the Chrome editor to the running PC game. It forwards length-framed UTF-8 JSON over a loopback-only HTTP connection. It does not run a game, store pairing tokens, listen on a network port, or connect to an external service.

## Windows

1. In Chrome, open `chrome://extensions`, enable Developer mode, and load the package's `extension/` folder with **Load unpacked**.
2. The bundled extension has the stable ID `ngolglhaedkpheljgabbfafifbimmlle`; the installer already authorizes that ID.
3. In PowerShell, from the package's `native/` directory, run:

   ```powershell
   .\install-windows.ps1
   ```

4. Start Belde, open the extension, and enter the pairing code shown in the game.

The installer copies `bin/belde_host.exe` into the current user's Local AppData folder and registers `com.belde.editor` under that user's Chrome/Chromium registry keys. Administrator access is not needed. Only the bundled extension ID is authorized. Developers using a different manifest key can pass `-ExtensionId YOUR_EXTENSION_ID`. `uninstall-windows.ps1` reverses this registration without deleting game saves.

## Linux or macOS

The installer uses the compiled host when it matches the current operating system. On macOS, or when no matching binary is bundled, it installs the Python 3 standard-library fallback with a launcher pinned to the interpreter’s absolute path. Python 3 is then required while the editor runs. To build a native host instead, compile it on the target operating system and run the user-only installer:

```sh
mkdir -p bin
cc -std=c11 -O2 -Wall -Wextra -Werror belde_host.c -o bin/belde_host
./install-unix.sh
```

Developers using a different extension manifest key can pass its ID as the first shell argument. The one-time installer uses Python 3 to write correctly escaped absolute paths. A native macOS executable must be compiled on macOS; the bundled Linux executable cannot run there. The fallback provides the same framed protocol without requiring a macOS C compiler. `./uninstall-unix.sh` removes only this host and its two browser manifests. It does not delete game saves.

## Windows cross-build from Linux

```sh
x86_64-w64-mingw32-gcc -std=c11 -O2 -Wall -Wextra -Werror -static belde_host.c -o bin/belde_host.exe -lws2_32
```

The game build pipeline supplies the cross-compiler and bundles this executable. No Python installation is required on Windows to run the host.

## Protocol and limits

- Browser to host: a four-byte little-endian length followed by a JSON object. Each request is at most 65,536 bytes; the host rejects zero, oversized, or truncated frames.
- Host to game: `POST /native`, `Content-Type: application/json`, with an exact `Content-Length`. Destination is always `127.0.0.1`, never an environment-supplied hostname.
- Port defaults to `43127`. For a deliberately configured alternate port, set `BELDE_BRIDGE_PORT` for both game and the browser's native-host environment. A port must be an integer in 1024–65535.
- HTTP connection has a two-second connect deadline and five-second transfer deadline. Responses require an unambiguous Content-Length, at most 1 MiB, and a JSON-object shape. HTTP error JSON is passed through unchanged; redirects and chunked responses are not followed.
- Authentication, pairing, editor lease, game-instance ownership, and safe edit validation belong to the running game. The native host cannot bypass them. Tokens are never logged or persisted by this executable.
- Standard output contains native messaging frames only. The host returns a structured disconnected response when the game is absent; it does not launch a second gameplay instance.

Both the C host and Python fallback use bounded reads, a cumulative transfer deadline and the same request/response size limits.

Run the native framing/HTTP tests from the repository root:

```sh
python -m unittest discover -s tests -p 'bridge_native*.py' -v
```
