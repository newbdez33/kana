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
retained records, and four phone or landscape viewports. These checks do not
verify the TapTap-hosted runtime on a physical device.

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
states, and immediate publication after approval. The hosted version has not
yet been verified on a physical phone through the TapTap test QR code. QR
scanning is a self-test entry point; the console accepted this submission without
a recorded phone test. Track the review result and this remaining validation in
[issue #10](https://github.com/newbdez33/kana/issues/10).

## Advertising follow-up

Add TapTap H5 advertising after the first playable release. The current package
has no advertising integration. The follow-up needs platform activation, ad
code, testing, and an updated privacy declaration before publication. Use the
[H5 advertising guide](https://developer.taptap.cn/minigameapidoc/quick-start/mcp-guide/ad-integration-guide/).
