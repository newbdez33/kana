# Kana H5

A browser game for TapTap H5 distribution. It uses the existing four-choice,
five-second game rules. The build reads the 46 basic kana directly from the
native `AppConfig.swift` table and copies the existing kana font.

The first version has a Simplified Chinese interface, a kana chart, pause and
resume, and local practice statistics. It has no external runtime dependencies.
It does not include the native apps' billing or advertising integrations.

The phone layout follows the native iOS practice screen. The light gray question
area uses 60 percent of the available height; four white answer cells fill the
remaining 40 percent. The menu and statistics sit above the question. A single
row shows the answer count, average time, last-ten average, best streak, and
current streak. Landscape viewports place the answers left of the question.
Inside TapTap, the layout uses the host's safe area and menu bounds to keep
the menu button and kana chart clear of the platform menu.

Phones start practice when the font is ready. Correct answers advance immediately,
as in iOS. Wrong answers and timeouts highlight the correct answer for review.
The menu pauses the timer and provides the chart and pause controls. Opening the
chart during a manual pause does not resume practice when the chart closes.
Desktop browsers keep the start action and keyboard hints. Phone layouts hide
keyboard hints without disabling keyboard input.

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
also cover automatic phone start, immediate correct-answer progression, menu and
chart navigation, portrait and landscape layouts, keyboard input, visibility
changes, and storage restrictions. Repeat touch and safe-area checks in TapTap
when the phone layout changes.

## TapTap release

Use the H5 game workflow. The developer center requires a ZIP with one top-level
folder and `index.html` directly inside that folder. From this directory:

```sh
npm run build
(cd ../../build && zip -r kana-h5.zip h5)
```

The native Android and iOS packages are separate products of this repository.
Use captures of this web game for its listing.

The [TapTap H5 game](https://www.taptap.cn/app/1031166) was approved and published
on November 6, 2026, at 16:30. Both Android and iOS listings offer play through
the TapTap app. The published update `V-20261106` uses H5 version `440518`,
package `160144`, resubmitted at 14:12 with updated screenshots and gameplay
video. Its required qualifications are approved. The iOS phone layout,
TapTap safe area, and rapid-answer correction message passed Galaxy S22 Ultra
developer-test checks. Public S22 checks also passed for all four answer
positions, corrections, timeout, menu and chart pauses, and stored records
after a cold restart. See the
[release record](../../docs/releases/2026-11-06-taptap-information-page.md).
