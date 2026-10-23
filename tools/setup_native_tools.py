#!/usr/bin/env python3
"""Download verified Debian host packages and extract a local MinGW/Xvfb toolchain.

Never installs packages system-wide or changes the user's HOME. This fallback is
for the Debian13 x86_64 build host; other hosts may use their own MinGW and Xvfb.
"""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools"


def main() -> None:
    if os.uname().machine not in ("x86_64", "amd64"):
        raise RuntimeError("Pinned toolchain is for Debian13 x86_64 hosts")
    packages = json.loads((ROOT / "tools/toolchain-packages.json").read_text())["packages"]
    downloads, sysroot, binaries = TOOLS / "packages", TOOLS / "sysroot", TOOLS / "bin"
    for directory in (downloads, sysroot, binaries):
        directory.mkdir(parents=True, exist_ok=True)
    for package in packages:
        path = downloads / package["filename"]
        if not path.exists():
            for cached in downloads.glob(package["name"] + "_*.deb"):
                with cached.open("rb") as source:
                    cached_digest = hashlib.file_digest(source, "sha256").hexdigest()
                if cached_digest == package["sha256"]:
                    path = cached
                    break
        if not path.exists():
            temporary = path.with_suffix(".partial")
            with urllib.request.urlopen(package["source"], timeout=90) as response, temporary.open("wb") as output:
                while data := response.read(1024 * 1024):
                    output.write(data)
            temporary.replace(path)
        with path.open("rb") as source:
            digest = hashlib.file_digest(source, "sha256").hexdigest()
        if digest != package["sha256"]:
            raise RuntimeError("Package SHA256 mismatch; not extracting " + package["name"])
        subprocess.run(["dpkg-deb", "-x", str(path), str(sysroot)], check=True)
    compiler = binaries / "x86_64-w64-mingw32-gcc"
    compiler.write_text('#!/bin/sh\nset -eu\nBELDE_TOOLS_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)\nexec "$BELDE_TOOLS_ROOT/sysroot/usr/bin/x86_64-w64-mingw32-gcc-posix" "$@"\n')
    compiler.chmod(0o755)
    for name in ("Xvfb", "xvfb-run"):
        link = binaries / name
        if link.is_symlink():
            link.unlink()
        elif link.exists():
            raise RuntimeError("Refusing to overwrite an unexpected local tool: " + str(link))
        link.symlink_to("../sysroot/usr/bin/" + name)
    subprocess.run([str(compiler), "--version"], check=True, stdout=subprocess.DEVNULL)
    print("Verified local MinGW and Xvfb tools ready: " + str(binaries))


if __name__ == "__main__":
    main()
