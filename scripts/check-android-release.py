#!/usr/bin/env python3
"""Check Kana release startup on a dedicated Android emulator."""

import argparse
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    sdk = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk"))
    adb = [str(sdk / "platform-tools/adb"), "-s", args.serial]
    package = "jp.jacky.kana"

    def run(*command):
        return subprocess.run(
            [*adb, *command], check=True, capture_output=True, text=True, timeout=30
        ).stdout

    if run("shell", "getprop", "ro.kernel.qemu").strip() != "1":
        raise SystemExit("Use a dedicated emulator; this check installs and stops Kana.")
    args.output.mkdir(parents=True, exist_ok=True)
    print(run("install", "-r", str(args.apk)).strip(), flush=True)
    run("logcat", "-c", "-b", "crash")
    for name in ("cold-start", "reopen"):
        run("shell", "am", "force-stop", package)
        try:
            launch = run("shell", "am", "start", "-W", "-n", f"{package}/.MainActivity")
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
            (args.output / "crashes.txt").write_text(run("logcat", "-d", "-b", "crash"))
            raise SystemExit(f"FAIL: {name} did not start; inspect {args.output}") from error
        (args.output / f"{name}.txt").write_text(launch)
        time.sleep(10)
        crashes = run("logcat", "-d", "-b", "crash")
        (args.output / "crashes.txt").write_text(crashes)
        process = subprocess.run(
            [*adb, "shell", "pidof", package], capture_output=True, text=True, timeout=30
        )
        activity = run("shell", "dumpsys", "activity", "activities")
        (args.output / f"{name}-activity.txt").write_text(activity)
        resumed = any(
            "ResumedActivity" in line and package in line
            for line in activity.splitlines()
        )
        if "Status: ok" not in launch or process.returncode or package in crashes or not resumed:
            raise SystemExit(f"FAIL: {name}; inspect {args.output}")
        with (args.output / f"{name}.png").open("wb") as image:
            subprocess.run([*adb, "exec-out", "screencap", "-p"], stdout=image, check=True, timeout=30)
        print(f"PASS: {name}; app remained in the foreground for 10 seconds", flush=True)


if __name__ == "__main__":
    main()
