#!/usr/bin/env python3
"""Run the production layout tests on macOS without an iOS runtime."""

from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory(prefix="kana-layout-tests-") as directory:
    package = Path(directory)
    (package / "Sources/kana").mkdir(parents=True)
    (package / "Tests/kanaTests").mkdir(parents=True)
    (package / "Package.swift").write_text(
        '// swift-tools-version: 6.0\n'
        'import PackageDescription\n'
        'let package = Package(name: "PracticeLayoutTests", targets: [\n'
        '    .target(name: "kana"),\n'
        '    .testTarget(name: "kanaTests", dependencies: ["kana"])\n'
        '])\n'
    )
    shutil.copy2(ROOT / "source/kana/kana/views/layouts/PracticeLayout.swift", package / "Sources/kana")
    shutil.copy2(ROOT / "source/kana/kanaTests/PracticeLayoutTests.swift", package / "Tests/kanaTests")
    subprocess.run(["swift", "test", "--package-path", str(package)], check=True)
