# Jumping Kana H5 update — 2026-11-10

The owner chose **跳跳五十音 / Jumping Kana** as a separate TapTap-only game.
The new game combines Kana practice with a rabbit journey and original
picture-book artwork inspired by the mood of Pyon. Native Kana and Pyon are
separate products; their releases and names are unchanged.

## Game

- Four choices and five seconds per question, using the existing 46-kana table.
- Correct answers advance immediately and move the rabbit one step.
- Every eight correct answers starts a new meadow. Four themes cycle.
- Wrong answers and timeouts reveal the answer without removing journey progress.
- Statistics and the current streak remain in one row. Existing records survive.
- The notebook, pause controls, Q/W/A/S, arrows, Enter, and Space remain available.
- Rabbit animation pauses with the game and respects reduced-motion settings.
- No live ad unit is configured. The package remains ad-free.

## Package

- Source version: `1.1.0`.
- File: `build/jumping-kana-1.1.0.zip`.
- Size: `6,884,557` bytes.
- SHA-256: `bbe6fc00339fd380f38ef05cd666ce7fbae1f0be23bd8bef32f13675b3815055`.
- Uploaded as `jumping-kana-1.1.0-final.zip`, H5 version `459669`, package `170848`.
- Portrait orientation, minimum base library `2.4.0`.
- One top-level `h5` folder, with `index.html` directly inside it.
- No mock host, test data, or store materials in the ZIP.

## Validation

All 24 local tests pass, including four new journey tests. Browser checks cover
eight-step progression, correction after rapid answers, timeout, menu and chart
pauses, reload, and retained statistics. Actual keyboard events cover all four
direct answer keys, four arrow directions, Enter, and Space.

Layouts pass at 320 × 568, 390 × 667, 390 × 844, 844 × 390, and 1280 × 900.
TapTap safe-area simulation also passes at 384 × 824 and 320 × 568. All four
answer cells remain visible. The WCAG A/AA automated audit reports no violations;
contrast over the illustrated background still requires visual judgment.

A local banner mock confirms that the new scene, correction text, and answers
remain clear of the banner. Menu entry and the next question remove it. Small
viewports that lack enough room suppress the banner. This does not verify real
advertising fill or platform activation.

### S22 browser validation

The final local build passed on the physical Galaxy S22 Ultra, Android 16,
in Chrome at 384 × 692 CSS pixels. Actual ADB touch input covered all four
answer positions, eight correct answers and a meadow change, correction,
timeout, both notebook tabs, menu/manual pauses, and resume. Reload retained
nine answers, a best streak of eight, and eight journey steps. All answer
cells fit the screen and the AI artwork note was visible in the menu.

This is a device browser check, not a successful TapTap-hosted check. The
TapTap developer QR for `459669` repeatedly opened the old published UI,
including when recognized by TapTap's own image scanner. The self-test list
was empty; the owner's current account was added and read back, but a cold
retry still opened the old UI. The old TapTap record remained at 62 answers
and best streak 12. Do not report the new hosted version as verified.

Temporary camera and media permissions were revoked after scanning. Test QR
files were removed from the phone. Evidence is in
`build/jumping-kana-20261110/` and is not committed.

## Platform status

TapTap app `1031166` has a saved draft with the new title, listing copy, icon,
two promotion images, three screenshots, and a 30-second gameplay video.
Draft `V-20261106-1` is bound to final H5 version `459669`.

The updated AI content declaration is under review. It now declares the
AI-assisted artwork and includes a screenshot of the disclosure in the game
menu. The game has no live AI service. The qualification page shows 3/4 complete.

The previously published package remains H5 version `440518`, package `160144`.
The new game has not been submitted or published yet. The final submission
preview confirmed the title, materials, H5 `459669`, portrait orientation,
and immediate publication after approval. It permits submission while the
AI declaration is pending but warns that review may reject it. Keep the
saved draft until the declaration and hosted device check are complete.

## Advertising and distribution

The owner intends the new game for exclusive TapTap distribution. The separate
Creative Workshop Content Operations Agreement remains unsigned. Before
accepting it, resolve the boundary for pre-existing shared code, kana data,
fonts, and the separate native Kana and Pyon products. A product rename does
not establish that exclusion. The earlier incentive agreement is separate.

After that contract is approved and ads are activated, create the live banner
unit, complete the privacy declaration, build with the unit identifier, and
verify real ads on S22 before publishing an ad-enabled package.

See the [earlier advertising record](2026-11-06-taptap-information-page.md#advertising-readiness--2026-11-10-jst)
and [store materials](../../store/taptap/README.md).
