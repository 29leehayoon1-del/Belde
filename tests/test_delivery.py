"""Verify assembled release archives, including native executable platform and permissions.

Run after tools/build_game.py --platform all. Missing packages fail; no build is
silently skipped or replaced with source-only validation.
"""
import hashlib
import json
from pathlib import Path
import struct
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class DesktopDeliveryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "dist/build-manifest.json").read_text())
        cls.packages = {p["platform"]: p for p in cls.manifest["packages"]}

    def test_all_desktop_targets_were_exported(self):
        self.assertEqual(set(self.packages), {"windows", "linux", "macos-arm64", "macos-x86_64"})
        self.assertTrue(self.manifest["godot"].startswith("4.6.3."))

    def test_checksums_and_zip_integrity(self):
        for target, package in self.packages.items():
            with self.subTest(platform=target):
                path = ROOT / package["file"]
                self.assertGreater(path.stat().st_size, 1000000)
                self.assertLess(path.stat().st_size, 95 * 1024 * 1024)
                with path.open("rb") as source:
                    self.assertEqual(hashlib.file_digest(source, "sha256").hexdigest(), package["sha256"])
                with zipfile.ZipFile(path) as archive:
                    self.assertIsNone(archive.testzip())
                    for name in archive.namelist():
                        self.assertTrue(name.startswith("Belde/"), name)
                        self.assertNotIn("..", Path(name).parts)

    def test_each_package_has_game_editor_installers_and_licenses(self):
        for target, package in self.packages.items():
            with self.subTest(platform=target), zipfile.ZipFile(ROOT / package["file"]) as archive:
                names = archive.namelist()
                for name in ["Belde/READ-ME-FIRST.txt", "Belde/extension/manifest.json", "Belde/native/belde_host.py", "Belde/native/README.md", "Belde/licenses/GODOT-LICENSE.txt", "Belde/licenses/GODOT-COPYRIGHT.txt"]:
                    self.assertIn(name, names)
                self.assertTrue(any(name.endswith(".pck") for name in names))
                manifest = json.loads(archive.read("Belde/extension/manifest.json"))
                self.assertEqual(manifest["manifest_version"], 3)
                self.assertIn("nativeMessaging", manifest["permissions"])

    def test_windows_game_and_host_are_real_x86_64_pe(self):
        package = self.packages["windows"]
        with zipfile.ZipFile(ROOT / package["file"]) as archive:
            for name in ["Belde/Belde.exe", "Belde/native/bin/belde_host.exe"]:
                with archive.open(name) as source:
                    header = source.read(4096)
                self.assertEqual(header[:2], b"MZ")
                offset = struct.unpack_from("<I", header, 0x3C)[0]
                self.assertEqual(header[offset:offset + 4], b"PE\x00\x00")
                self.assertEqual(struct.unpack_from("<H", header, offset + 4)[0], 0x8664)

    def test_linux_game_and_host_are_real_executable_elf(self):
        package = self.packages["linux"]
        with zipfile.ZipFile(ROOT / package["file"]) as archive:
            for name in ["Belde/Belde.x86_64", "Belde/native/bin/belde_host"]:
                with archive.open(name) as source:
                    self.assertEqual(source.read(4), b"\x7fELF")
                self.assertTrue((archive.getinfo(name).external_attr >> 16) & 0o111)

    def test_macos_exports_are_thin_correct_architecture_and_executable(self):
        for target, expected in [("macos-arm64", 0x100000C), ("macos-x86_64", 0x1000007)]:
            with self.subTest(platform=target), zipfile.ZipFile(ROOT / self.packages[target]["file"]) as archive:
                names = [n for n in archive.namelist() if ".app/Contents/MacOS/" in n and not n.endswith("/")]
                self.assertGreaterEqual(len(names), 1)
                for name in names:
                    with archive.open(name) as source:
                        header = source.read(32)
                    self.assertEqual(header[:4], b"\xcf\xfa\xed\xfe")
                    self.assertEqual(struct.unpack_from("<I", header, 4)[0], expected)
                    self.assertTrue((archive.getinfo(name).external_attr >> 16) & 0o111)
                self.assertNotIn("Belde/native/bin/belde_host", archive.namelist())


if __name__ == "__main__":
    unittest.main(verbosity=2)
