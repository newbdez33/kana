# TapTap H5 release

The [Kana H5 game](https://www.taptap.cn/app/1031166) is published. The developer
center records approval and publication of `V-20261106` at **2026-11-06 16:30**,
as displayed in its version history. The final review submission is recorded
at 14:12 on the same date: **2 hours and 18 minutes** before approval.

## Published scope

- App ID: `1031166`; developer: `Jacky工作室`.
- Both Android and iOS client listings offer **Open the app to play**. The
  public title is **Kana五十音 测试**, with a release date of November 6, 2026.
- The description and three screenshots show the Simplified Chinese H5 game.
  The native App Store association and native screenshot overrides are removed.
- Bound H5 version: `440518`; package: `160144`; portrait orientation;
  minimum base library: `2.4.0`.

## Verification and remaining work

On November 6, both public client tabs showed the play action in a signed-in
browser. The published version details confirmed H5 version `440518`. After
the required player verification, the public QR link opened the game in TapTap
on the S22. Public gameplay and retained-record checks passed. The startup age
label differs from the approved declaration, as recorded below.

The local game passed nine unit tests and browser checks for keyboard controls,
retained records, and four phone or landscape viewports. Physical TapTap checks
on a Galaxy S22 Ultra also passed, as recorded below.

## Initial information page

The developer center records approval and publication of `V-20261105` at
**2026-11-06 04:15**. Submission was at 00:47 on the same date: **3 hours and
28 minutes** before approval. Both client listings were Coming soon and
offered Follow. The public page was checked while logged out. That version
bound H5 `438689`, package `159109`, with no public play action.

## Initial playable submission

Version `V-20261106` was submitted on **2026-11-06 at 12:32**, as displayed in the
version history. At that time, the release page and version history showed **Under review**.
It provides play on Android and iOS through the same H5 package and is set to
publish automatically after approval. All required store materials are complete.

The three qualifications submitted earlier on November 6 were all approved
before this game-review submission:

- AI declaration: no generative AI service or generated game content.
- Content classification: ages 8 and above.
- Platform-managed privacy: the current game does not collect personal
  information. Practice statistics stay in local browser storage.

Added a 29.17-second H.264 gameplay video at 780 by 1688 pixels, plus a 1440 by
1440 cover that matches the existing banner. Video `6061298` and cover asset
`764542` are included in the submitted version. The recording shows ten correct answers,
correction feedback, pause/resume, and both kana charts. It records the actual
browser game at a phone viewport; it is not a physical-device capture. One cut
removes the gap between the gameplay and chart recordings.

The final submission preview confirmed H5 version `438689`, both client play
states, and immediate publication after approval. QR scanning is a self-test
entry point; the console accepted this submission before the physical test.
Track the corrected package and public-play check in
[issue #10](https://github.com/newbdez33/kana/issues/10).

## Physical validation and safe-area fix

Tested on November 6 using a Samsung Galaxy S22 Ultra (`SM-S9080`), Android 16,
connected to `jx`. TapTap `2.96.15-rel#100300` was installed from the official
download page. Its in-app component update and restart were required before
the H5 runtime could start. The embedded runtime reported Chromium 121 with
TBS `048919`, a 384 by 824 CSS-pixel viewport, and pixel ratio 2.8125.

The developer-test QR payload was decoded locally and opened through TapTap's
native deep link. Tests ran inside TapTap on the physical phone. Camera or
gallery QR recognition was not validated; media-library access was not granted.
Touch input used the device's actual screen coordinates. DOM checks used the
hosted game's debugging endpoint.

The original package passed correct-answer, correction, timeout, chart,
background, and statistics checks. It exposed one layout defect: the native
menu overlapped the pause and chart buttons. The runtime now reads TapTap's
safe area and menu bounds. The header and chart dialog stay below that area;
ordinary browsers retain their existing spacing.

The corrected package is uploaded for self-test:

- H5 version: `440368`; package: `160052`; portrait; base library `2.4.0`.
- File: `kana-h5-1.0.0-safe-area.zip`; 3,406,198 bytes.
- SHA-256: `7ddde299c6fbbd348203d41447c1cb7da9c14a41ee91805a539f306e711df9dc`.

Physical checks passed:

- All four answer positions accept touch input and remain within the viewport.
- Twelve consecutive correct answers in the corrected package produced a best
  streak of 12 and a cumulative answer count of 23.
- Wrong answers reset the current streak, preserve the best, and highlight the
  correct answer. A five-second timeout does not increase the answer count.
- Manual pause, both 46-kana charts, nested pause reasons, and resume work.
  Chart scrolling reaches the final kana. The chart close button stays clear
  of the native menu.
- Background and recent-apps navigation retain the active question and time.
- A cold app restart into the corrected package retained the prior 11 answers,
  best streak of 10, and average times. The current streak reset as intended.
- The native menu ends at CSS y=67; the corrected header buttons start at y=82.
  The original controls overlapped that menu.

Nine local unit tests passed after the fix. Device screenshots and check results
are under `build/taptap-s22-20261106/` and are not committed. The phone is left
with the corrected test game paused.

The initial review used `438689`. Version `440368` was uploaded for self-test,
but was superseded by the iOS layout update below before review resubmission.

## iOS phone layout alignment

The initial review was withdrawn on November 6 at **13:48**, with the owner's approval. The
phone UI now follows the native iOS practice screen: a light gray question area
above a white four-cell answer grid, with a 60/40 vertical split. A single
row retains all five statistics, including the current streak. The menu opens
above the statistics and pauses the timer. The native TapTap menu remains clear
of game controls.

Phone layouts start after the kana font loads and hide keyboard hints. Correct
answers advance immediately. Wrong answers and timeouts highlight the correct
answer in pink, as in iOS. Desktop browsers retain the start action, Q/W/A/S,
arrow focus, and Enter/Space confirmation. The same UI and game engine serve
both layouts; TapTap distribution remains Android and iOS.

Local validation passed nine unit tests, syntax checks, phone and desktop
viewport checks, menu/chart pause checks, keyboard controls, and stored-record
recovery. A rapid correct-then-wrong sequence exposed a stale success-message
timer. Clearing that timer before each result keeps the correction message
visible; the browser regression check passed after 800 milliseconds.

The layout package `440458` (`160110`) passed physical S22 checks for all four
answer positions, immediate progression, menu and nested chart pauses, correction,
and timeout. It retained the previous 23 answers and best streak of 12 on its
first cold launch. The full device run ended with 49 answers and best streak 12.
The final package adds the correction-message timer fix without a layout change:

- H5 version `440518`; package `160144`; portrait; base library `2.4.0`.
- File `kana-h5-1.0.0-mobile-fix.zip`; 3,406,067 bytes.
- SHA-256: `095dd6807340318c9a836c22bebc3ad99f85d9db456da2a023c23fa03cbe9780`.

The final package passed a cold-launch check with all 49 earlier answers intact.
A correct-then-wrong touch sequence completed in 468 ms; the correction text
remained visible after another 900 ms. Four further correct answers advanced
immediately. The final record is 55 answers with a best streak of 12. The menu
button starts at CSS y=87, below the native menu's y=67 bottom. The hosted
`app.mjs` matches the local source byte for byte. The phone is left paused.

Replaced the listing screenshots with three 1170 by 2532 captures of the actual
phone web UI (assets `767805`, `767806`, `767807`). Replaced the gameplay video
with `6062300`: 26.03 seconds, 780 by 1688 pixels, H.264. The uncut browser recording
shows ten correct answers, correction, pause/resume, and both kana charts. It is
not a physical-device recording. The existing banners and cover remain in use.

Version `V-20261106` was resubmitted on **2026-11-06 at 14:12**, as displayed
in the version history. At resubmission, the release page and version history
both showed **Under review**. The final preview confirmed H5 `440518`, Android and iOS play
availability, portrait orientation, all required materials, and immediate
publication after approval.

Artifacts and device check results are in `build/taptap-mobile-20261106/` and
are not committed.

## Public launch check

The developer center shows `V-20261106` as **Live**, with approval and
publication at **16:30** on November 6. The published version details confirm
H5 `440518` and `kana-h5-1.0.0-mobile-fix.zip`. Both public client tabs show
**Open the app to play**.

The public page's QR payload was decoded locally. Its native TapTap link uses
miniapp ID `tapmcsmheyaq3i9ijt` and app ID `1031166`, without a developer-test
type or pinned version. The first launch reached the platform's player
real-name verification form. After this step was completed with the owner's
authorization, the same public entry opened the game. No identity data is
included in these release records.

Public S22 checks used actual screen captures and device touch input:

- The initial public launch retained 55 answers and a best streak of 12.
- Six consecutive correct answers covered all four answer positions and
  advanced immediately. The total reached 61, with a current streak of 6.
- One wrong answer raised the total to 62, reset the current streak, and
  highlighted the correct answer in pink. The correction remained visible.
- Waiting 5.5 seconds on the next question showed timeout feedback without
  increasing the answer count.
- Opening the menu paused the timer. Both kana charts opened, the katakana
  chart scrolled to the final kana, and closing it preserved the manual pause.
  Resume worked, and controls remained clear of the native TapTap menu.
- A cold app restart through the public entry retained 62 answers, best
  streak 12, average time 0.36 seconds, and recent-ten time 0.35 seconds.

The phone is left in the public game, paused. Public test screenshots and
results are under `build/taptap-live-s22-20261106/` and are not committed.

Publication screenshots and the public-entry check are under
`build/taptap-live-20261106/` and are not committed.

## Startup age label follow-up

The public TapTap loading screen shows **16+**. The developer center still
shows **8+** selected in the approved age-classification declaration. This
display mismatch needs a platform follow-up; its cause is not yet confirmed.
No declaration was changed during the check. Evidence is in
`cold-relaunch.png` and `approved-age.png` under the public device-test folder.
Track this with advertising in [issue #10](https://github.com/newbdez33/kana/issues/10).

## Advertising follow-up

Add TapTap H5 advertising after the first playable release. The current package
has no advertising integration. The follow-up needs platform activation, ad
code, testing, and an updated privacy declaration before publication. Use the
[H5 advertising guide](https://developer.taptap.cn/minigameapidoc/quick-start/mcp-guide/ad-integration-guide/).
