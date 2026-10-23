# Optional cross-device profile sessions

Belde works locally without an account service. The PC game and its Native Messaging editor then enforce one connected pair on that computer. They cannot see an unrelated computer.

This optional Python-standard-library coordinator and the Godot `BeldeGlobalSession` client add **one active PC lease per authenticated profile across devices**. Its editor remains part of that PC's pair and is limited by the PC's local bridge. No remote service, account, credentials, TLS certificate, domain or hosting is created automatically.

## Service configuration

Use Python 3.10 or newer. Store service data outside the repository and game installation.

1. Create a unique profile ID using letters, numbers, `_` or `-` (maximum 64 characters).
2. Generate a cryptographically random profile token, at least 32 characters long. Keep the actual token in a private file or password manager; the service configuration stores only its SHA-256 hash. Do not commit tokens to source control.
3. Supply a JSON profiles file such as the following structure. Replace the placeholder with the hexadecimal SHA-256 digest of the real profile token; it is not a usable example credential:

```json
{"profiles":{"player-one":"<64-character SHA-256 digest>"}}
```

For a same-machine test, run:

```sh
python native/session_coordinator.py --profiles /private/path/profiles.json --database /private/path/sessions.sqlite3 --bind 127.0.0.1 --port 43128
```

For multiple computers, configure a real hostname and a trusted TLS certificate. A non-loopback listener refuses to start without both certificate and key:

```sh
python native/session_coordinator.py --profiles /private/path/profiles.json --database /private/path/sessions.sqlite3 --bind 0.0.0.0 --port 43128 --cert /private/path/fullchain.pem --key /private/path/privkey.pem
```

The certificate must validate for the URL used by the clients. The game preserves HTTPS certificate verification and refuses remote plaintext HTTP. Do not disable certificate verification to work around a deployment problem.

The profiles file is a small self-hosted credential directory, not a full registration/password-reset/account-billing service. Revocation, backups, monitoring and certificate renewal remain deployment responsibilities.

## Game configuration

Launch Belde with these three environment variables set by your OS launcher:

| Variable | Purpose |
| --- | --- |
| `BELDE_SESSION_URL` | Base HTTPS URL of the coordinator, without the `/v1/lease` suffix. HTTP is accepted only for loopback tests. |
| `BELDE_PROFILE_ID` | The profile ID configured on the service. |
| `BELDE_PROFILE_TOKEN` | The real private profile token whose hash is configured on the service. |

No URL means local mode. A configured URL with incomplete or invalid credentials blocks the profile session; it never silently switches to local mode. The token remains in the game process and is not written to saves or editor snapshots. Redirects are disabled so the token is not forwarded to another host.

## Lease behavior

- Acquisition and renewal run in SQLite `BEGIN IMMEDIATE` transactions. Concurrent devices cannot both acquire the same active profile.
- Leases expire after 20 seconds. The game renews every five seconds and pauses gameplay if renewal or authentication fails.
- A second PC receives **Multiple Game Instances Detected** and can continue only after the current lease expires/releases or the player explicitly chooses **Disconnect other session to continue** with valid profile credentials.
- A browser editor lease is separate and shorter: it expires after 15 seconds of inactivity, while the authorized popup and detached editor share the same connection.
- Clean shutdown attempts to release a profile. A crash or an immediate process kill relies on expiry rather than a permanent lock.
- The game offers reconnect/takeover controls when configured. The service must be reachable from every participating computer.

## Validation and limits

`python tests/bridge_coordinator_test.py` exercises real HTTP requests, concurrent acquisition, authentication, takeover, renewal, release and expiry. It also launches actual Godot clients against the coordinator, verifies duplicate-PC rejection, and stops the server to verify that the client fails closed.

The shipped service was tested on Linux. It was not deployed to a public endpoint, connected to an identity provider or tested across physical computers. Local mode and the optional configured coordinator must not be described as an already hosted global account service.
