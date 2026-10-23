#!/usr/bin/env python3
"""Import, export and package Belde desktop builds using pinned Godot 4.6.3."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
TARGETS = {
    "windows": ("Windows", "Belde.exe", "Belde-Windows-x86_64.zip"),
    "linux": ("Linux", "Belde.x86_64", "Belde-Linux-x86_64.zip"),
    "macos-arm64": ("macOS-arm64", "Belde.zip", "Belde-macOS-arm64.zip"),
    "macos-x86_64": ("macOS-x86_64", "Belde.zip", "Belde-macOS-x86_64.zip"),
}
ERROR_MARKERS = ("SCRIPT ERROR:", "Parse Error:", "ERROR:")


def environment() -> dict[str, str]:
    env = os.environ.copy()
    for key, path in (("XDG_DATA_HOME", ".runtime-data"), ("XDG_CACHE_HOME", ".runtime-cache"), ("XDG_CONFIG_HOME", ".runtime-config")):
        env[key] = str(ROOT / path)
        (ROOT / path).mkdir(exist_ok=True)
    env["PATH"] = str(ROOT / ".tools/bin") + os.pathsep + env.get("PATH", "")
    return env


def command(args: list[str], log_name: str, timeout: int = 600) -> str:
    print("Running " + " ".join(args), flush=True)
    completed = subprocess.run(args, cwd=ROOT, env=environment(), text=True,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    logs = ROOT / "build/logs"
    logs.mkdir(parents=True, exist_ok=True)
    (logs / log_name).write_text(completed.stdout)
    lines = completed.stdout.splitlines()
    if completed.returncode or any(marker in completed.stdout for marker in ERROR_MARKERS):
        print("\n".join(lines[-65:]), file=sys.stderr)
        raise RuntimeError(f"Command failed; inspect build/logs/{log_name}")
    print("\n".join(lines[-7:]), flush=True)
    return completed.stdout


def native_host(target: str, destination: Path) -> None:
    destination = destination / "bin"
    destination.mkdir(parents=True, exist_ok=True)
    source = ROOT / "native/belde_host.c"
    if not source.is_file():
        raise RuntimeError("Native host source is required before packaging: native/belde_host.c")
    if target == "windows":
        compiler = shutil.which("x86_64-w64-mingw32-gcc", path=environment()["PATH"])
        if not compiler:
            raise RuntimeError("MinGW is missing. Run python tools/setup_native_tools.py on the Debian build host.")
        command([compiler, "-std=c11", "-O2", "-static", "-s", "-o", str(destination / "belde_host.exe"), str(source), "-lws2_32"], "native-windows.log")
    elif target == "linux":
        compiler = shutil.which("cc") or shutil.which("gcc")
        if not compiler:
            raise RuntimeError("A C compiler is required for the Linux native host")
        command([compiler, "-std=c11", "-D_POSIX_C_SOURCE=200809L", "-O2", "-s", "-o", str(destination / "belde_host"), str(source)], "native-linux.log")
        (destination / "belde_host").chmod(0o755)
    # macOS uses the executable Python host supplied with the installer, rather
    # than shipping a Linux ELF under a misleading macOS filename.


def copy_tree(source: Path, destination: Path) -> None:
    if source.is_dir():
        shutil.copytree(source, destination, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns("__pycache__", ".pytest_cache", "*.pyc", "*.exe", "belde_host"))


def package(target: str, output: Path, archive_name: str) -> dict:
    package_root = output / "package/Belde"
    # This is a generated staging directory. Rebuilding must not retain files
    # removed from the source or an older native host for a different target.
    if package_root.exists():
        shutil.rmtree(package_root)
    package_root.mkdir(parents=True, exist_ok=True)
    if target.startswith("macos"):
        with zipfile.ZipFile(output / "Belde.zip") as exported:
            exported.extractall(package_root)
        # ZipFile extraction does not preserve Unix execute bits.
        for executable in package_root.glob("*.app/Contents/MacOS/*"):
            if executable.is_file():
                executable.chmod(0o755)
    else:
        executable = "Belde.exe" if target == "windows" else "Belde.x86_64"
        for name in (executable, "Belde.pck", "Belde.console.exe", "Belde.console.sh", "icudt_godot.dat"):
            source = output / name
            if source.exists():
                shutil.copy2(source, package_root / name)
        if target == "linux":
            (package_root / executable).chmod(0o755)
    copy_tree(ROOT / "extension", package_root / "extension")
    copy_tree(ROOT / "native", package_root / "native")
    native_host(target, package_root / "native")
    copy_tree(ROOT / "tools/licenses", package_root / "licenses")
    instructions = f'''BELDE — THE WRONG COMMANDER

Desktop package: {target}; version 0.1.0.

START THE GAME
'''
    if target == "windows":
        instructions += "Extract this entire ZIP, then run Belde.exe. Keep Belde.pck beside it.\n"
    elif target == "linux":
        instructions += "Extract this entire ZIP, then run ./Belde.x86_64. Keep Belde.pck beside it.\n"
    else:
        applications = list(package_root.glob("*.app"))
        if len(applications) != 1:
            raise RuntimeError("Expected exactly one exported macOS application bundle")
        instructions += f"Extract the ZIP and open {applications[0].name}. This independent build is ad-hoc signed and not notarized; macOS may require explicit approval in Privacy & Security. Native macOS execution has not been verified on the Linux build machine.\n"
    instructions += '''
CONNECTED CHROME EDITOR
The game runs without the optional extension. To connect the editor, follow the
native/ installation instructions for your platform, load extension/ as an
unpacked Chrome extension, start the game, and enter its pairing code.
The PC game is authoritative. Guard, Patrol, and Advance are gameplay modes;
the extension edits the same map and does not run a separate game.

SOURCE & LICENSES
Original game content is in the Belde repository. Godot's MIT license and
third-party notices are included under licenses/. The optional editor and native
host are bundled as source so their platform registration is inspectable.
'''
    (package_root / "READ-ME-FIRST.txt").write_text(instructions)
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    destination = dist / archive_name
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(package_root.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(package_root.parent))
    with zipfile.ZipFile(destination) as archive:
        bad = archive.testzip()
        if bad:
            raise RuntimeError("Package ZIP CRC failure: " + bad)
        names = archive.namelist()
        assert "Belde/extension/manifest.json" in names
        assert any(name.endswith(".pck") for name in names)
    size = destination.stat().st_size
    if size >= 95 * 1024 * 1024:
        raise RuntimeError(f"{archive_name} is {size / 1024 / 1024:.1f}MiB; split or reduce duplicated assets before GitHub delivery")
    with destination.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    return {"platform": target, "file": str(destination.relative_to(ROOT)), "sha256": digest,
            "bytes": size, "mib": round(size / 1024 / 1024, 2),
            "validation": "Export succeeded; ZIP CRC and required files verified",
            "native_execution": "pending Linux smoke test" if target == "linux" else "Not tested on this OS"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", choices=[*TARGETS, "all"], default="all")
    parser.add_argument("--skip-import", action="store_true", help="Reuse a successfully imported unchanged project")
    parser.add_argument("--export-only", action="store_true", help="Export without assembling native editor packages")
    args = parser.parse_args()
    godot = os.environ.get("BELDE_GODOT") or shutil.which("godot") or shutil.which("godot4")
    if not godot:
        raise RuntimeError("Install the official Godot 4.6.3 editor before building")
    version = subprocess.check_output([godot, "--version"], env=environment(), text=True).strip()
    if not version.startswith("4.6.3."):
        raise RuntimeError("This project pins Godot 4.6.3; found " + version)
    if not (GAME / "project.godot").is_file():
        raise RuntimeError("Game project is not yet present")
    if not (ROOT / ".tools/godot/templates/version.txt").exists():
        raise RuntimeError("Run python tools/setup_godot.py before exporting")
    if not args.skip_import:
        command([godot, "--headless", "--editor", "--path", str(GAME), "--quit"], "import.log")
    targets = list(TARGETS) if args.platform == "all" else [args.platform]
    results = []
    for target in targets:
        preset, executable, archive_name = TARGETS[target]
        output = ROOT / "build" / target
        output.mkdir(parents=True, exist_ok=True)
        command([godot, "--headless", "--path", str(GAME), "--export-release", preset, str(output / executable)], "export-" + target + ".log")
        if not (output / executable).is_file():
            raise RuntimeError("Export did not produce " + str(output / executable))
        if not args.export_only:
            results.append(package(target, output, archive_name))
    if results:
        (ROOT / "dist/build-manifest.json").write_text(json.dumps({"godot": version, "packages": results}, indent=2) + "\n")
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
