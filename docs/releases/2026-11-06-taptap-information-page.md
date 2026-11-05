# TapTap H5 information page

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
The developer center showed the submitted version as published. Its new draft
inherits the coming-soon settings; no further review submission was made.

The local game passed nine unit tests and browser checks for keyboard controls,
retained records, and four phone or landscape viewports. These checks do not
verify the TapTap-hosted runtime on a physical device.

## Playable release preparation

Draft `V-20261106` now provides play on both Android and iOS through the same H5
package. Its copy describes direct play, and all required store materials are
complete. The published information page remains unchanged until approval of
this next version. The final game-review submission has not been sent.

Three qualifications were submitted on November 6 and are under review:

- AI declaration: no generative AI service or generated game content.
- Content classification: ages 8 and above.
- Platform-managed privacy: the current game does not collect personal
  information. Practice statistics stay in local browser storage.

Added a 29.17-second H.264 gameplay video at 780 by 1688 pixels, plus a 1440 by
1440 cover that matches the existing banner. Video `6061298` and cover asset
`764542` are assigned to the draft. The recording shows ten correct answers,
correction feedback, pause/resume, and both kana charts. It records the actual
browser game at a phone viewport; it is not a physical-device capture. One cut
removes the gap between the gameplay and chart recordings.

The final submission preview confirms H5 version `438689`, both client play
states, and immediate publication after approval. The platform allows a game
submission while qualifications are under review, but warns that it can be
rejected. The remaining pre-submission check is the hosted version on a phone
through the TapTap test QR code. Track this and the qualification results in
[issue #10](https://github.com/newbdez33/kana/issues/10).

## Advertising follow-up

Add TapTap H5 advertising after the first playable release. The current package
has no advertising integration. The follow-up needs platform activation, ad
code, testing, and an updated privacy declaration before publication. Use the
[H5 advertising guide](https://developer.taptap.cn/minigameapidoc/quick-start/mcp-guide/ad-integration-guide/).
