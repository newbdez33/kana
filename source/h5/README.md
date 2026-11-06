# Kana H5

A browser game for TapTap H5 distribution. It uses the existing four-choice,
five-second game rules. The build reads the 46 basic kana directly from the
native `AppConfig.swift` table and copies the existing kana font.

The first version has a Simplified Chinese interface, a kana chart, pause and
resume, and local practice statistics. It has no external runtime dependencies.
It does not include the native apps' billing or advertising integrations.

The phone layout keeps the question and all four answers within one viewport.
A single row above the question shows the current streak, best streak, answer
count, average answer time, and the average for the last ten answers. Short
landscape viewports place answers beside the question.

## Keyboard controls

The answer grid follows the keyboard layout: Q and W on the top row, A and S
on the bottom row. These keys submit an answer directly. Arrow keys move focus
within the grid without wrapping. Enter or Space submits the focused answer.
After a wrong answer or timeout, the correct answer receives focus if an answer
was focused, so Enter or Space can start the next question. Escape pauses or
resumes practice. Game shortcuts are inactive while the chart is open or the
game is paused. Holding a key does not submit answers to subsequent questions.

## Build and test

From this directory:

```sh
npm test
```

The build writes a static package to `../../build/h5`. It needs an HTTP server
because the browser loads ES modules.

```sh
python3 -m http.server 8798 --directory ../../build/h5
```

Tests cover answer equivalence, the timer deadline, concurrent pause reasons,
duplicate input, statistics, and stored data validation. Browser checks must
also cover portrait and landscape layouts, chart navigation, keyboard input,
visibility changes, and storage restrictions.

## TapTap release

Use the H5 game workflow. The developer center requires a ZIP with one top-level
folder and `index.html` directly inside that folder. From this directory:

```sh
npm run build
(cd ../../build && zip -r kana-h5.zip h5)
```

The native Android and iOS packages are separate products of this repository.
Use captures of this web game for its listing.

The [TapTap information page](https://www.taptap.cn/app/1031166) was approved and
published on November 6, 2026. The playable update `V-20261106` is under review,
with automatic publication after approval. Its required qualifications are
approved. TapTap-hosted physical-device checks remain unverified. See the
[release record](../../docs/releases/2026-11-06-taptap-information-page.md).
