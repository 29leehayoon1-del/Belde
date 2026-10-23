#!/usr/bin/env python3
"""Check exported Mach-O architectures, ad-hoc code pages and sealed resources.

This is archive/hash validation on Linux, not Apple's codesign/Gatekeeper check
or a claim that the application was executed on a Mac.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import plistlib
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def code_directories(executable: bytes):
    if executable[:4] != b"\xcf\xfa\xed\xfe":
        raise RuntimeError("Expected a thin 64-bit Mach-O executable")
    commands = struct.unpack_from("<I", executable, 16)[0]
    cursor = 32
    signature = None
    for _ in range(commands):
        kind, size = struct.unpack_from("<II", executable, cursor)
        if size < 8 or cursor + size > len(executable):
            raise RuntimeError("Invalid Mach-O command bounds")
        if kind == 0x1D:
            offset, length = struct.unpack_from("<II", executable, cursor + 8)
            signature = executable[offset:offset + length]
        cursor += size
    if signature is None:
        raise RuntimeError("Mach-O has no LC_CODE_SIGNATURE")
    magic, length, slots = struct.unpack_from(">III", signature)
    if magic != 0xFADE0CC0 or length > len(signature):
        raise RuntimeError("Invalid embedded signature SuperBlob")
    for index in range(slots):
        _, offset = struct.unpack_from(">II", signature, 12 + index * 8)
        kind, size = struct.unpack_from(">II", signature, offset)
        if offset + size > length:
            raise RuntimeError("Signature slot exceeds SuperBlob bounds")
        if kind == 0xFADE0C02:
            yield signature[offset:offset + size]


def verify_pages(executable: bytes, directory: bytes, special_blobs: dict[int, bytes]) -> dict:
    flags, hash_offset, _, special_count, count, limit = struct.unpack_from(">IIIIII", directory, 12)
    hash_size, algorithm, _, page_shift = struct.unpack_from("4B", directory, 36)
    if not flags & 2:
        raise RuntimeError("CodeDirectory does not carry the ad-hoc flag")
    algorithms = {1: "sha1", 2: "sha256"}
    if algorithm not in algorithms or page_shift > 20:
        raise RuntimeError("Unsupported CodeDirectory hash or page size")
    page_size = 1 << page_shift
    if limit > len(executable) or count != (limit + page_size - 1) // page_size:
        raise RuntimeError("CodeDirectory code-page extent does not match the executable")
    for index in range(count):
        start = index * page_size
        expected = directory[hash_offset + index * hash_size:hash_offset + (index + 1) * hash_size]
        actual = hashlib.new(algorithms[algorithm], executable[start:min(start + page_size, limit)]).digest()[:hash_size]
        if len(expected) != hash_size or actual != expected:
            raise RuntimeError("CodeDirectory page hash mismatch at page " + str(index))
    for slot, data in special_blobs.items():
        if slot > special_count:
            raise RuntimeError("CodeDirectory has no seal for required bundle metadata")
        offset = hash_offset - slot * hash_size
        expected = directory[offset:offset + hash_size]
        actual = hashlib.new(algorithms[algorithm], data).digest()[:hash_size]
        if len(expected) != hash_size or actual != expected:
            raise RuntimeError("CodeDirectory special-slot hash mismatch: " + str(slot))
    return {"algorithm": algorithms[algorithm], "pages_verified": count,
            "special_slots_verified": sorted(special_blobs), "ad_hoc": True}


def main() -> None:
    results = []
    for target, cpu in (("arm64", 0x100000C), ("x86_64", 0x1000007)):
        path = ROOT / ("dist/Belde-macOS-" + target + ".zip")
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            executables = [name for name in names if ".app/Contents/MacOS/" in name and not name.endswith("/")]
            if len(executables) != 1:
                raise RuntimeError("Expected one main Mach-O executable")
            executable = archive.read(executables[0])
            if struct.unpack_from("<I", executable, 4)[0] != cpu:
                raise RuntimeError("Mach-O CPU differs from package target")
            resource_path = next(name for name in names if name.endswith("/_CodeSignature/CodeResources"))
            contents = resource_path.rsplit("/_CodeSignature/", 1)[0]
            resource_data = archive.read(resource_path)
            special_blobs = {1: archive.read(contents + "/Info.plist"), 3: resource_data}
            directories = [verify_pages(executable, directory, special_blobs) for directory in code_directories(executable)]
            if not directories:
                raise RuntimeError("No signed code directory was found")
            resource_manifest = plistlib.loads(resource_data)
            resources = resource_manifest.get("files2", {})
            if not resources:
                raise RuntimeError("Bundle has no sealed resources")
            for relative, seal in resources.items():
                if not isinstance(seal, dict) or "hash2" not in seal:
                    raise RuntimeError("Resource seal has no SHA-256 hash")
                data = archive.read(contents + "/" + relative)
                if hashlib.sha256(data).digest() != seal["hash2"]:
                    raise RuntimeError("Sealed resource hash mismatch: " + relative)
            result = {"platform": "macos-" + target, "passed": True,
                      "code_directories": directories, "sealed_resources_verified": len(resources),
                      "scope": "Thin architecture, embedded ad-hoc code-page hashes and bundle resource hashes; not native macOS execution or Apple notarization"}
            results.append(result)
            print(json.dumps(result), flush=True)
    output = ROOT / "build/checks/macos-signature-results.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({"packages": results}, indent=2) + "\n")


if __name__ == "__main__":
    main()
