#!/usr/bin/env python3
"""Run the real content, combat, native-host and live Godot bridge checks."""
import json
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile
import time

from build_game import ROOT, GAME, environment, ERROR_MARKERS


def main() -> None:
    cases = [
        ("campaign", ["godot", "--headless", "--path", str(GAME), "--script", "res://tests/campaign_smoke.gd"], r"CAMPAIGN_SMOKE_PASS\s+(\d+)\s+checks"),
        ("combat", ["godot", "--headless", "--path", str(GAME), "--script", "res://tests/simulation_smoke.gd"], r"SIMULATION SMOKE:\s+(\d+) passed, 0 failed"),
        ("combat_regression", ["godot", "--headless", "--path", str(GAME), "--script", "res://tests/simulation_regression.gd"], r"SIMULATION REGRESSION:\s+(\d+) passed, 0 failed"),
        ("ui_flow", ["godot", "--headless", "--path", str(GAME), "--script", "res://tests/ui_flow.gd"], r"UI_FLOW:\s+(\d+) checks, 0 failures"),
        ("native_transport", [sys.executable, str(ROOT / "tests/bridge_native_test.py"), "-v"], r"Ran (\d+) tests?"),
        ("godot_bridge", [sys.executable, str(ROOT / "tests/bridge_godot_test.py")], r"Ran (\d+) tests?"),
        ("profile_coordinator", [sys.executable, str(ROOT / "tests/bridge_coordinator_test.py")], r"Ran (\d+) tests?"),
    ]
    directory = ROOT / "build/checks"
    directory.mkdir(parents=True, exist_ok=True)
    results = []
    for name, command, outcome in cases:
        start = time.monotonic()
        print("Running " + name, flush=True)
        with tempfile.TemporaryDirectory(prefix=name + "-", dir=directory) as temporary:
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
            run = subprocess.run(command, cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240)
        (directory / (name + ".log")).write_text(run.stdout)
        match = re.search(outcome, run.stdout)
        count = int(match.group(1)) if match else 0
        ok = run.returncode == 0 and count > 0
        if name in ("campaign", "combat", "combat_regression", "ui_flow") and any(marker in run.stdout for marker in ERROR_MARKERS):
            ok = False
        result = {"name": name, "passed": ok, "checks_or_tests": count, "exit_code": run.returncode,
                  "elapsed_seconds": round(time.monotonic() - start, 2), "log": "build/checks/" + name + ".log"}
        results.append(result)
        print(json.dumps(result), flush=True)
        if not ok:
            print(run.stdout[-12000:], file=sys.stderr)
    (directory / "results.json").write_text(json.dumps({"runs": results}, indent=2) + "\n")
    if not all(result["passed"] for result in results):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
