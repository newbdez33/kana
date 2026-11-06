# TapTap H5 release

The [Kana information page](https://www.taptap.cn/app/1031166) is public.
The developer center records approval and publication of `V-20261105` at
**2026-11-06 04:15**, as displayed in its version history. The review submission
is recorded at 00:47 on the same date: **3 hours and 28 minutes** before approval.

## Published scope

- App ID: `1031166`; developer: `Jacky工作室`.
- Both Android and iOS client listings remain **Coming soon**. The public page
  offers Follow; it does not provide a play or download action.
- The description and three screenshots show the Simplified Chinese H5 game.
  The native App Store association and native screenshot overrides are removed.
- Bound H5 version: `438689`; package: `159109`; portrait orientation;
  minimum base library: `2.4.0`.

## Verification and remaining work

On November 6, the public page loaded while logged out on both client tabs.
The developer center showed the information-page version as published.

The local game passed nine unit tests and browser checks for keyboard controls,
retained records, and four phone or landscape viewports. Physical TapTap checks
on a Galaxy S22 Ultra also passed, as recorded below.

## Playable version under review

Version `V-20261106` was submitted on **2026-11-06 at 12:32**, as displayed in the
version history. Both the release page and version history show **Under review**.
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

The active review still uses `438689`. The corrected package is **not** part of
that submission. Replacing it requires withdrawing the current review, selecting
`440368`, and resubmitting. This would restart the review queue.

## Advertising follow-up

Add TapTap H5 advertising after the first playable release. The current package
has no advertising integration. The follow-up needs platform activation, ad
code, testing, and an updated privacy declaration before publication. Use the
[H5 advertising guide](https://developer.taptap.cn/minigameapidoc/quick-start/mcp-guide/ad-integration-guide/).
