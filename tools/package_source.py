#!/usr/bin/env python3
"""Package editable game source without downloaded tools or generated caches."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_PARTS = {".godot", "__pycache__", ".pytest_cache", "bin"}


def sources():
    for directory in ("game", "extension", "native", "docs", "tools", "tests"):
        for path in sorted((ROOT / directory).rglob("*")):
            relative = path.relative_to(ROOT)
            if path.is_file() and not EXCLUDED_PARTS.intersection(relative.parts) and path.suffix != ".pyc":
                yield path
    # The data compiler reads these authored inputs. Prior concept-board images
    # are available separately in the original repository and are not needed to
    # import or play the runtime project.
    yield from sorted((ROOT / "preproduction/data").glob("*.json"))
    yield ROOT / "preproduction/art/manifest.json"
    yield ROOT / ".gitignore"
    yield ROOT / "README.md"


def main() -> None:
    destination = ROOT / "dist/Belde-Source.zip"
    destination.parent.mkdir(exist_ok=True)
    instructions = """BELDE — EDITABLE GAME SOURCE

Open game/project.godot with the official Godot 4.6.3 standard editor.
For checks and desktop builds, read docs/BUILD.md. Gameplay instructions are in
docs/GAMEPLAY.md. The Chrome editor and native bridge are under extension/ and
native/. The game works without the optional editor.

This source archive contains runtime artwork and authored data inputs. Earlier
concept-board images and the standalone preproduction artbook remain in the
Belde GitHub repository. Downloaded export templates, compilers, import caches,
and generated desktop builds are deliberately excluded from this source ZIP.
"""
    count = 0
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sources():
            archive.write(path, Path("Belde-Source") / path.relative_to(ROOT))
            count += 1
        archive.writestr("Belde-Source/SOURCE-README.txt", instructions)
    with zipfile.ZipFile(destination) as archive:
        bad = archive.testzip()
        if bad:
            raise RuntimeError("Source archive CRC failure: " + bad)
        names = set(archive.namelist())
        for required in ("game/project.godot", "docs/BUILD.md", "preproduction/data/first-recruits.json"):
            if "Belde-Source/" + required not in names:
                raise RuntimeError("Source archive is missing " + required)
    size = destination.stat().st_size
    if size >= 95 * 1024 * 1024:
        raise RuntimeError("Source archive exceeds the 95 MiB delivery limit")
    with destination.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    report = {"file": str(destination.relative_to(ROOT)), "bytes": size,
              "mib": round(size / 1024 / 1024, 2), "sha256": digest,
              "source_files": count, "validation": "Required source inputs and ZIP CRC verified"}
    (ROOT / "dist/source-manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
