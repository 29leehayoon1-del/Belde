#!/usr/bin/env python3
"""Prepare Godot's pinned editor and checksum-verified export templates locally."""
from pathlib import Path
import hashlib
import json
import os
import copy
import platform
import shutil
import struct
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.6.3-stable"
NAME = f"Godot_v{VERSION}_export_templates.tpz"
EXPECTED_SHA512 = "da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68"
EDITOR_NAME = f"Godot_v{VERSION}_linux.x86_64"
EDITOR_SHA512 = "a035258da32b77f966a5376f9fa29c30a6adde826a85ba918e1605bd1fc9823eba7d85f1dd5e748956bd2ba72827c0025ffa11bb82aec91128c407a2e723c99c"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}"
WANTED = [
    "version.txt", "linux_debug.x86_64", "linux_release.x86_64",
    "windows_debug_x86_64.exe", "windows_release_x86_64.exe",
    "windows_debug_x86_64_console.exe", "windows_release_x86_64_console.exe",
    "macos.zip", "icudt_godot.dat", "web_nothreads_debug.zip", "web_nothreads_release.zip",
]


def download(url: str, path: Path) -> None:
    partial = path.with_suffix(path.suffix + ".partial")
    with urllib.request.urlopen(url, timeout=120) as response, partial.open("wb") as output:
        while chunk := response.read(1024 * 1024):
            output.write(chunk)
    partial.replace(path)


def official_digest(lines: list[str], filename: str) -> str:
    for line in lines:
        fields = line.split(maxsplit=1)
        if len(fields) == 2 and fields[1].lstrip("*") == filename:
            return fields[0]
    raise RuntimeError("Official checksum metadata has no entry for " + filename)


def ensure_editor(directory: Path, checksum_lines: list[str]) -> None:
    archive_name = EDITOR_NAME + ".zip"
    if official_digest(checksum_lines, archive_name) != EDITOR_SHA512:
        raise RuntimeError("Official editor checksum differs from the pinned release")
    for candidate in (shutil.which("godot"), shutil.which("godot4")):
        if not candidate:
            continue
        try:
            version = subprocess.check_output([candidate, "--version"], text=True, stderr=subprocess.PIPE, timeout=20).strip()
        except (OSError, subprocess.SubprocessError):
            continue
        if version.startswith("4.6.3.stable.official."):
            print("Using existing official Godot 4.6.3 editor: " + candidate, flush=True)
            (directory / "editor-verification.json").write_text(json.dumps({"source": "Existing installed official-version editor", "path": candidate, "version": version, "download_required": False}, indent=2) + "\n")
            return
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        raise RuntimeError("Automatic editor setup supports Linux x86_64; install the official Godot 4.6.3 editor for this development OS")
    archive = directory / archive_name
    if not archive.is_file():
        print("Downloading official Godot 4.6.3 Linux x86_64 editor.", flush=True)
        download(BASE + "/" + archive_name, archive)
    with archive.open("rb") as source:
        actual = hashlib.file_digest(source, "sha512").hexdigest()
    if actual != EDITOR_SHA512:
        raise RuntimeError("Editor SHA-512 mismatch; archive was not extracted or used")
    with zipfile.ZipFile(archive) as bundle:
        bundle.extract(EDITOR_NAME, directory / "editor")
    executable = directory / "editor" / EDITOR_NAME
    executable.chmod(0o755)
    binary = ROOT / ".tools/bin/godot"
    binary.parent.mkdir(parents=True, exist_ok=True)
    if binary.exists() and not binary.is_symlink():
        raise RuntimeError("Refusing to replace an unexpected regular file at .tools/bin/godot")
    if binary.is_symlink():
        binary.unlink()
    binary.symlink_to(os.path.relpath(executable, binary.parent))
    version = subprocess.check_output([str(binary), "--version"], text=True, stderr=subprocess.PIPE, timeout=20).strip()
    if not version.startswith("4.6.3.stable.official."):
        raise RuntimeError("Extracted editor reports an unexpected version: " + version)
    (directory / "editor-verification.json").write_text(json.dumps({"release": VERSION, "url": BASE + "/" + archive_name, "sha512": actual, "checksum_source": BASE + "/SHA512-SUMS.txt", "path": str(binary.relative_to(ROOT)), "version": version, "download_required": True}, indent=2) + "\n")
    print("Verified local editor ready: " + str(binary), flush=True)


def thin_macho(data: bytes, cpu_type: int) -> bytes:
    """Preserve one exact architecture slice, equivalent to lipo -thin."""
    magic, count = struct.unpack_from(">II", data)
    if magic not in (0xCAFEBABE, 0xCAFEBABF) or not 1 <= count <= 8:
        raise RuntimeError("Unexpected universal Mach-O template header")
    for index in range(count):
        offset = 8 + index * (32 if magic == 0xCAFEBABF else 20)
        if magic == 0xCAFEBABF:
            cpu, _subtype, start, size, _align, _reserved = struct.unpack_from(">IIQQII", data, offset)
        else:
            cpu, _subtype, start, size, _align = struct.unpack_from(">IIIII", data, offset)
        if cpu == cpu_type:
            if not 0 < start < len(data) or not 0 < size <= len(data) - start:
                raise RuntimeError("Invalid Mach-O architecture bounds")
            result = data[start:start + size]
            if result[:4] != b"\xcf\xfa\xed\xfe" or struct.unpack_from("<I", result, 4)[0] != cpu_type:
                raise RuntimeError("Mach-O slice architecture mismatch")
            return result
    raise RuntimeError("Requested architecture is missing from the official universal template")


def derive_macos_templates(directory: Path) -> None:
    source = directory / "templates/macos.zip"
    records = []
    for architecture, cpu in [("arm64", 0x100000C), ("x86_64", 0x1000007)]:
        target = directory / ("templates/macos-" + architecture + ".zip")
        slices = []
        with zipfile.ZipFile(source) as original, zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as output:
            for info in original.infolist():
                data = original.read(info)
                metadata = copy.copy(info)
                if "/Contents/MacOS/godot_macos_" in info.filename and info.filename.endswith(".universal"):
                    data = thin_macho(data, cpu)
                    metadata.filename = info.filename.removesuffix(".universal") + "." + architecture
                    slices.append({"file": metadata.filename, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)})
                output.writestr(metadata, data)
        if len(slices) != 2:
            raise RuntimeError("Expected both debug and release Mach-O slices")
        with target.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        records.append({"architecture": architecture, "file": target.name, "sha256": digest, "slices": slices})
    (directory / "macos-thin-provenance.json").write_text(json.dumps({"source": "Official macos.zip from SHA512-verified Godot4.6.3 export TPZ", "derivation": "Exact Mach-O fat-architecture byte extraction; no code changes; export is ad-hoc signed by Godot", "templates": records}, indent=2) + "\n")


def main() -> None:
    directory = ROOT / ".tools/godot"
    directory.mkdir(parents=True, exist_ok=True)
    checksum_path = directory / "SHA512-SUMS.txt"
    if not checksum_path.exists():
        download(BASE + "/SHA512-SUMS.txt", checksum_path)
    lines = checksum_path.read_text().splitlines()
    ensure_editor(directory, lines)
    official = official_digest(lines, NAME)
    if official != EXPECTED_SHA512:
        raise RuntimeError("Official checksum metadata does not match the pinned verified release")
    archive = directory / NAME
    if not archive.exists():
        print("Downloading Godot 4.6.3 desktop export templates (~1.26 GB), once.", flush=True)
        download(BASE + "/" + NAME, archive)
    with archive.open("rb") as source:
        actual = hashlib.file_digest(source, "sha512").hexdigest()
    if actual != EXPECTED_SHA512:
        raise RuntimeError("Godot template SHA512 mismatch; archive was not extracted or used")
    with zipfile.ZipFile(archive) as bundle:
        for name in WANTED:
            bundle.extract("templates/" + name, directory)
    for path in (directory / "templates").glob("linux_*"):
        path.chmod(0o755)
    standard = ROOT / ".runtime-data/godot/export_templates/4.6.3.stable"
    standard.parent.mkdir(parents=True, exist_ok=True)
    if standard.is_symlink():
        if standard.resolve() != (directory / "templates").resolve():
            raise RuntimeError("Unexpected standard export-template symlink")
    elif standard.exists():
        raise RuntimeError("Refusing to replace an existing standard export-template directory")
    else:
        standard.symlink_to(os.path.relpath(directory / "templates", standard.parent), target_is_directory=True)
    derive_macos_templates(directory)
    record = {"release": VERSION, "url": BASE + "/" + NAME, "sha512": actual,
              "checksum_source": BASE + "/SHA512-SUMS.txt", "extracted": WANTED}
    (directory / "verification.json").write_text(json.dumps(record, indent=2) + "\n")
    print("Verified export templates ready: " + str(directory / "templates"))


if __name__ == "__main__":
    main()
