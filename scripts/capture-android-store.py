#!/usr/bin/env python3
"""Capture the Android store UI on a dedicated emulator after building test APKs."""

import argparse
import os
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--device", choices=("phone", "tablet"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    sdk = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk"))
    adb = [str(sdk / "platform-tools/adb"), "-s", args.serial]

    def run(*command):
        return subprocess.run([*adb, *command], check=True, capture_output=True,
                              text=True, timeout=120).stdout

    if run("shell", "getprop", "ro.kernel.qemu").strip() != "1":
        raise SystemExit("Use a dedicated emulator; this changes its display and app locale.")
    outputs = root / "source/android/app/build/outputs/apk"
    run("install", "-r", str(outputs / "debug/app-debug.apk"))
    run("install", "-r", str(outputs / "androidTest/debug/app-debug-androidTest.apk"))
    package = "jp.jacky.kana"
    try:
        run("shell", "cmd", "uimode", "night", "no")
        run("shell", "wm", "size", "1080x1920")
        for device, density in (("phone", "420"), ("tablet", "240")):
            if args.device and args.device != device:
                continue
            run("shell", "wm", "density", density)
            for locale in ("en", "ja", "zh-Hans", "zh-Hant", "ko"):
                run("shell", "cmd", "locale", "set-app-locales", package,
                    "--user", "0", "--locales", locale)
                output = args.output / locale / device
                output.mkdir(parents=True, exist_ok=True)
                result = run("shell", "am", "instrument", "-w", "-r",
                             "-e", "class", "jp.jacky.kana.StoreScreenshotTest",
                             "-e", "storeScreenshots", "true",
                             f"{package}.test/jp.jacky.kana.KanaTestRunner")
                (output / "instrumentation.txt").write_text(result)
                if "OK (1 test)" not in result:
                    raise SystemExit(f"Capture failed: {output}")
                for name in ("02-practice", "03-menu", "05-chart", "04-coffee"):
                    run("pull", f"/sdcard/Android/data/{package}/files/store/{name}.png",
                        str(output / f"{name}.png"))
                print(f"Captured {device} {locale}", flush=True)
    finally:
        run("shell", "wm", "size", "reset")
        run("shell", "wm", "density", "reset")
        run("shell", "cmd", "locale", "set-app-locales", package,
            "--user", "0", "--locales", "en")


if __name__ == "__main__":
    main()
