#!/usr/bin/env python3
"""Capture the native practice and StoreKit screens on a booted simulator."""

import argparse
import os
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True, help='Simulator UDID')
    parser.add_argument('--language', default='en')
    parser.add_argument('--store-listing', action='store_true', help='Capture display states without purchase transactions')
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if (output / 'run.xcresult').exists():
        parser.error('Use a new output directory for each run.')
    root = Path(__file__).resolve().parent.parent
    environment = dict(os.environ, TEST_RUNNER_KANA_SHOT_DIR=str(output))
    if args.store_listing:
        environment['TEST_RUNNER_KANA_STORE_LISTING'] = '1'
    command = [
        'xcodebuild', 'test', '-project', str(root / 'source/kana/kana.xcodeproj'),
        '-scheme', 'kana', '-destination', f'platform=iOS Simulator,id={args.device}',
        '-parallel-testing-enabled', 'NO', '-only-testing:kanaTests/PurchaseScreenshotTests',
        '-testLanguage', args.language, '-testRegion', 'JP',
        '-resultBundlePath', str(output / 'run.xcresult'), '-quiet',
    ]
    subprocess.run([
        'xcrun', 'simctl', 'status_bar', args.device, 'override', '--time', '9:41',
        '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3',
        '--batteryState', 'discharging', '--batteryLevel', '100',
    ], check=True)
    try:
        with (output / 'run.log').open('w') as log:
            process = subprocess.Popen(command, env=environment, stdout=log, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 240
            try:
                while process.poll() is None:
                    for marker in sorted(output.glob('*.marker')):
                        screenshot = marker.with_suffix('.png')
                        subprocess.run([
                            'xcrun', 'simctl', 'io', args.device, 'screenshot', str(screenshot),
                        ], check=True, capture_output=True, timeout=15)
                        marker.unlink()
                        print(f'Captured {screenshot.name}', flush=True)
                    if time.monotonic() > deadline:
                        raise TimeoutError('The capture run exceeded four minutes.')
                    time.sleep(0.15)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
        if process.returncode:
            print((output / 'run.log').read_text()[-6000:])
        raise SystemExit(process.returncode)
    finally:
        subprocess.run(['xcrun', 'simctl', 'status_bar', args.device, 'clear'], check=True)


if __name__ == '__main__':
    main()
