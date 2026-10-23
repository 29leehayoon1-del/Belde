#!/usr/bin/env python3
"""Launch the assembled Linux game and its PCK in isolated headless sessions."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time

from build_game import ROOT, environment, ERROR_MARKERS


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=ROOT / "build/linux/package/Belde/Belde.x86_64")
    parser.add_argument("--ui-flow", action="store_true", help="Also use the matching editor engine to run the external UI harness against the exported PCK")
    args = parser.parse_args()
    binary = args.binary.resolve()
    if not binary.is_file() or not binary.with_name("Belde.pck").is_file():
        raise RuntimeError("The assembled Linux executable and adjacent PCK are required")
    directory = ROOT / "build/checks"
    directory.mkdir(parents=True, exist_ok=True)
    results = []
    sessions = [("title", []), ("battle_preview", ["--battle-preview"])]
    if args.ui_flow:
        sessions.append(("ui_flow", []))
    for label, user_args in sessions:
        with tempfile.TemporaryDirectory(prefix="linux-smoke-", dir=directory) as temporary:
            env = environment()
            for key, folder in (("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config")):
                env[key] = str(Path(temporary) / folder)
            for key in ("BELDE_SESSION_URL", "BELDE_PROFILE_ID", "BELDE_PROFILE_TOKEN"):
                env.pop(key, None)
            with socket.socket() as listener:
                listener.bind(("127.0.0.1", 0))
                port = str(listener.getsockname()[1])
            env["BELDE_BRIDGE_PORT"] = port
            env["BELDE_PORT"] = port
            command = [str(binary), "--headless", "--audio-driver", "Dummy"]
            if label == "ui_flow":
                # Godot's release template does not expose --script. Test the
                # exported resources with the same-version editor engine, while
                # the two startup cases above execute the actual release ELF.
                editor = shutil.which("godot", path=env["PATH"]) or shutil.which("godot4", path=env["PATH"])
                if not editor:
                    raise RuntimeError("The matching Godot editor is required for external UI-flow scripts")
                command = [editor, "--headless", "--audio-driver", "Dummy", "--main-pack", str(binary.with_name("Belde.pck")), "--script", str(ROOT / "game/tests/ui_flow.gd")]
            else:
                command += ["--quit-after", "120"]
            if user_args:
                command += ["--", *user_args]
            started = time.monotonic()
            completed = subprocess.run(command, cwd=binary.parent, env=env, text=True,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
            log = directory / ("linux_export_" + label + ".log")
            log.write_text(completed.stdout)
            ok = completed.returncode == 0 and "Godot Engine v4.6.3" in completed.stdout and not any(marker in completed.stdout for marker in ERROR_MARKERS)
            count = 0
            if label == "ui_flow":
                match = re.search(r"UI_FLOW:\s+(\d+) checks, 0 failures", completed.stdout)
                count = int(match.group(1)) if match else 0
                ok = ok and count > 0
            report = {"scene": label, "passed": ok, "exit_code": completed.returncode,
                      "command": command, "log": str(log.relative_to(ROOT)),
                      "elapsed_seconds": round(time.monotonic() - started, 2),
                      "scope": "Exported PCK resources in the matching editor engine; external headless callback harness (release ELF has no --script option)" if label == "ui_flow" else "Actual packaged Linux executable and PCK; headless startup only"}
            if label == "ui_flow":
                report["checks"] = count
            results.append(report)
            print(json.dumps(report), flush=True)
            if not ok:
                print(completed.stdout)
    (directory / "linux-export-results.json").write_text(json.dumps({"runs": results}, indent=2) + "\n")
    if not all(result["passed"] for result in results):
        raise SystemExit(1)
    manifest = ROOT / "dist/build-manifest.json"
    if manifest.is_file():
        data = json.loads(manifest.read_text())
        for package in data.get("packages", []):
            if package.get("platform") == "linux":
                package["native_execution"] = "Packaged Linux executable and PCK passed isolated headless title and battle-preview startups on Debian 13 x86_64." + (" External headless UI callback flow also passed against the exported PCK using the matching editor engine; the release ELF does not expose --script." if args.ui_flow else "") + " Graphical execution was not tested in this build pass."
        manifest.write_text(json.dumps(data, indent=2) + "\n")


if __name__ == "__main__":
    main()
