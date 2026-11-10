# Kana H5

A browser game for TapTap H5 distribution. It uses the existing four-choice,
five-second game rules. The build reads the 46 basic kana directly from the
native `AppConfig.swift` table and copies the existing kana font.

The first version has a Simplified Chinese interface, a kana chart, pause and
resume, and local practice statistics. It has no external runtime dependencies.
It uses the TapTap host for optional banner ads. Native billing and ad-removal
purchases are not shared with this H5 version.

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
duplicate input, statistics, stored data validation, and the banner lifecycle.
Banner tests cover the initial delay, display-time limit, background entry,
layout changes, load failures, and late callbacks after a question change.
Browser checks must
also cover automatic phone start, immediate correct-answer progression, menu and
chart navigation, portrait and landscape layouts, keyboard input, visibility
changes, and storage restrictions. Repeat touch and safe-area checks in TapTap
when the phone layout changes.

## TapTap banner ads

The display flow follows iOS: a wrong answer or timeout can show a banner at
the bottom of the question area. The next question removes it immediately.
Correct answers never show an ad. The four answer cells and all statistics
remain visible. Closing the ad, opening the menu or chart, pausing, or leaving
the foreground removes the native banner. A failed request leaves no empty slot
and does not interrupt practice.

The TapTap rules add these limits to the iOS flow:

- No ads during the first 60 seconds in the foreground.
- Total display time cannot exceed 20 percent of foreground session time.
- Banner height cannot exceed 10 percent of the viewport. A banner that does
  not fit beside the game controls is removed. No automatic refresh is used.
- The banner has an ad label, a close button, and space between it and controls.

See the [ad review rules](https://developer.taptap.cn/minigameapidoc/tap-operation/operation-standards/minigame-ad-policy/)
and [behavior rules](https://developer.taptap.cn/minigameapidoc/tap-operation/operation-standards/behavior-standards/).
The integration uses the host's
[`tap.createBannerAd`](https://developer.taptap.cn/minigameapidoc/dev/api/ad/tap.createBannerAd/)
API, with no external advertising script.

Ads are disabled by default. After platform activation, set the banner unit
from the developer center at build time:

```sh
TAPTAP_BANNER_AD_UNIT_ID='<banner-unit-id>' npm run build
```

The build writes this public identifier to `ad-config.mjs`. An empty identifier
or a browser without the TapTap ad API keeps the game ad-free. Local mocks can
verify the display flow, but a configured package must pass a physical TapTap
test before publication. Verify ad loading, its actual dimensions, the close
button, next-question cleanup, background return, and unchanged records.

As checked on November 10, 2026 (JST), all four activation prerequisites are
complete, including mini-game filing approval. Advertising remains inactive.
Activation requires a separate content operations agreement whose exclusive
rights to game levels need clarification for Kana's distribution across
platforms. No live banner unit is configured. After scope clarification and
owner approval, enable ads, create the banner unit, complete the required
privacy declaration, and test the configured package in TapTap before
publication. The published package `440518` has no ads. See the
[release record](../../docs/releases/2026-11-06-taptap-information-page.md)
for the agreement distinction.

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
