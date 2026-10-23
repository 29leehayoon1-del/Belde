#!/usr/bin/env python3
"""Run an actual Godot window under Xvfb, send optional real input, capture it.

Example: PATH="$PWD/.tools/bin:$PATH" xvfb-run -a -s '-screen 0 1440x900x24 -nolisten tcp' \
  python tools/gui_capture.py --output build/review/title.png
This is a UI/runtime check, not a substitute for campaign/combat tests.
"""
from __future__ import annotations

import argparse
import ctypes
import ctypes.util
import json
import os
from pathlib import Path
import subprocess
import time

from PIL import Image
from build_game import ROOT, GAME, environment, ERROR_MARKERS

MINIMUM_GAME_COLORS = 1000  # The built-in Godot splash has only about 500.


def input_device():
    x11 = ctypes.CDLL(ctypes.util.find_library("X11"))
    xtst = ctypes.CDLL(ctypes.util.find_library("Xtst"))
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XFlush.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
    x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
    x11.XStringToKeysym.restype = ctypes.c_ulong
    x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
    x11.XKeysymToKeycode.restype = ctypes.c_ubyte
    xtst.XTestFakeMotionEvent.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ulong]
    xtst.XTestFakeButtonEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
    xtst.XTestFakeKeyEvent.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_int, ctypes.c_ulong]
    display = x11.XOpenDisplay(None)
    if not display:
        raise RuntimeError("Cannot connect to Xvfb; launch with .tools/bin/xvfb-run")
    return x11, xtst, display


def capture(output: Path) -> int:
    subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-f", "x11grab", "-video_size", "1440x900", "-i", os.environ["DISPLAY"], "-frames:v", "1", "-update", "1", str(output)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=15)
    with Image.open(output) as image:
        image.load()
        if image.size != (1440, 900):
            raise RuntimeError("Unexpected display dimensions: " + str(image.size))
        sample = image.convert("RGB").getcolors(maxcolors=1440 * 900)
        return len(sample) if sample else 1440 * 900


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, help="Exported Linux binary; defaults to Godot editor runtime")
    parser.add_argument("--output", type=Path, default=ROOT / "build/review/game.png")
    parser.add_argument("--frames", type=int, default=360)
    parser.add_argument("--startup-timeout", type=float, default=45, help="Maximum time for slow software OpenGL to paint a real frame")
    parser.add_argument("--action", action="append", default=[], help="Ordered wait:seconds, click:x,y, or key:Return/space/Escape")
    parser.add_argument("--game-arg", action="append", default=[])
    args = parser.parse_args()
    if not os.environ.get("DISPLAY"):
        raise RuntimeError("Run this script inside xvfb-run or an existing X display")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    log = args.output.with_suffix(".log")
    command = [str(args.binary)] if args.binary else [os.environ.get("BELDE_GODOT", "godot"), "--path", str(GAME)]
    command += ["--audio-driver", "Dummy", "--rendering-method", "gl_compatibility", "--resolution", "1440x900", "--position", "0,0", "--max-fps", "60", "--quit-after", str(args.frames)]
    if args.game_arg:
        command += ["--", *args.game_arg]
    x11, xtst, display = input_device()
    started = time.monotonic()
    with log.open("w") as stream:
        process = subprocess.Popen(command, cwd=args.binary.parent if args.binary else ROOT, env=environment(), stdout=stream, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + args.startup_timeout
            while True:
                if process.poll() is not None:
                    raise RuntimeError("Game exited before its first rendered frame; inspect " + str(log))
                time.sleep(0.5)
                if capture(args.output) >= MINIMUM_GAME_COLORS:
                    break
                if time.monotonic() >= deadline:
                    raise RuntimeError("Game never painted a nonblank frame; inspect " + str(log))
            startup_seconds = round(time.monotonic() - started, 2)
            time.sleep(0.4)
            for action in args.action:
                kind, value = action.split(":", 1)
                if kind == "wait":
                    delay = float(value)
                    if not 0 <= delay <= 15:
                        raise ValueError("Each wait must be between 0 and 15 seconds")
                    time.sleep(delay)
                elif kind == "click":
                    x, y = map(int, value.split(","))
                    xtst.XTestFakeMotionEvent(display, -1, x, y, 0)
                    xtst.XTestFakeButtonEvent(display, 1, 1, 0)
                    xtst.XTestFakeButtonEvent(display, 1, 0, 0)
                    x11.XFlush(display)
                    time.sleep(0.18)
                elif kind == "key":
                    code = x11.XKeysymToKeycode(display, x11.XStringToKeysym(value.encode()))
                    if not code:
                        raise ValueError("Unknown X keysym: " + value)
                    xtst.XTestFakeKeyEvent(display, code, 1, 0)
                    xtst.XTestFakeKeyEvent(display, code, 0, 0)
                    x11.XFlush(display)
                    time.sleep(0.18)
                else:
                    raise ValueError("Unknown action: " + kind)
            if process.poll() is not None:
                raise RuntimeError("Game exited before screenshot; inspect " + str(log))
            colors = capture(args.output)
            result = process.wait(timeout=max(30, args.frames / 60 + 10))
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
            x11.XCloseDisplay(display)
    text = log.read_text()
    if result != 0 or any(marker in text for marker in ERROR_MARKERS):
        raise RuntimeError("Godot UI run failed; inspect " + str(log))
    if colors < MINIMUM_GAME_COLORS:
        raise RuntimeError("Captured display is blank or nearly empty")
    report = {"result": "passed", "command": command, "godot_exit_code": result, "screenshot": str(args.output), "log": str(log), "unique_colors": colors, "startup_seconds": startup_seconds, "elapsed_seconds": round(time.monotonic() - started, 2), "actions": args.action, "scope": "Real graphical runtime, input delivery and nonblank screenshot; gameplay coverage is tested separately"}
    args.output.with_suffix(".json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
