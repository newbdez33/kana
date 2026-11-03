# Kana for Xiaohongshu

A web port of the iOS practice screen for the Xiaohongshu mini-tool container.
The app uses HTML, CSS, and classic JavaScript. It has no runtime dependencies
or external requests.

Version 1.0.3 adds five streak stages, hit feedback, and native haptics. The
separate [impact preview](preview/impact/README.md) provides stage controls and
pure haptic tests. It shares the production audio and haptic modules but does
not read or write saved records.

## Run

Use Node.js 20 or later and Python 3. No package install is required.

```sh
cd source/minitool
npm run build
npm test
npm run check
npm run preview
```

Open `http://127.0.0.1:8797/?lang=zh-Hans`. The language follows the browser by
default. The optional `lang` parameter supports the eight iOS languages.
The preview serves only `build/web` on the local loopback address.

## iOS behavior

- The 46 basic kana, four choices, and five-second time limit are retained.
- Prompts use hiragana, katakana, or romaji. The correct answer uses a different
  form. Distractors use distinct kana to avoid duplicate answer buttons.
- A correct answer advances immediately. A wrong answer or timeout highlights
  the correct answer. The question stays visible until that answer is tapped.
- The menu pauses the question. The chart and share sheet keep it paused.
  Page visibility changes also pause the timer.
- Timed taps contribute to the answer count and both averages, including
  incorrect taps. Timeouts do not add a time sample. Correction taps retain the
  original timing rules. Since 1.0.3, only correct first answers add to the
  streak; correcting a revealed answer starts the next question at zero.
- The chart has all 46 kana, with hiragana and katakana switches and the original
  alternating row colors. The menu supports the button and a vertical swipe.

`scripts/ios-data.mjs` reads the kana table and existing translations from
`source/kana/kana`. It writes them to `build/web/data.js` during the build.
The source files remain in the iOS app. The web font is a subset of its existing
Hosohuwafont font. Regenerate it after a font change:

```sh
uv run scripts/prepare-font.py
```

The native AdMob and StoreKit screens are omitted. The results action beside
the statistics creates a 1080 × 1440 score card and a note from the same snapshot.
It shows the best streak, answer count, average time, and recent average.
An empty record shows a practice prompt. The note editor lets the user edit,
cancel, or confirm publication. There is no separate
challenge mode, AI service, or leaderboard. Short feedback tones use Web Audio
after a user gesture. When the Audio Session API is available, the app selects
the playback category to match native iOS behavior in silent mode. The package
does not include the original WAV files or media data URLs, which the container
does not support.

## Container integration

- Client 9.46+ uses `getStorage` and `setStorage`. Older clients and browser
  previews use guarded browser storage. A successful upgrade migrates the
  existing browser record before removing its old copy.
- Writes are serialized. Read failures and unknown record versions prevent
  overwriting existing records. Failed native writes do not fall back to a
  second storage backend. If a native read fails or returns an empty value,
  `getStorageInfo` must confirm that the key is absent before initialization.
- `getWindowInfo` supplies safe areas and native button bounds on client 9.49+.
  Injected safe-area CSS variables and browser insets remain the fallback.
- `postNote` opens the platform's note flow. `saveImageToPhotosAlbum` saves the
  generated image on client 9.42+. Both require a user action and handle failure.
- The note uses only documented image, title, content, and page-type fields.
  The API has no public field for attaching a mini-tool. Automatic attachment
  has not been verified. A resolved call does not prove review approval.
- On client 9.51+, the menu's More button contains Follow creator.
  `getFollowStatus` and `followAuthor` target only this tool's creator.
  The app handles cancellation, rate limits, a resolved failure status, and
  the creator's own account. Older clients hide the entry. Pending actions
  disable repeated taps, and older status queries cannot replace a newer action.
- JavaScript uses the ES2017 baseline. Flexbox styles avoid modern layout
  dependencies. The container owns the CSP; the package does not set one.
  The local preview server uses an HTTP CSP header to restrict network access.

## Version 1.0.3

Submitted on November 4, 2026. The Creator platform shows `审核中 V1.0.3`
(under review), after the owner confirmed the release-page agreement.
Submission screenshots are in `build/submission/v1.0.3`.

- Streak stages start at 0, 5, 10, 20, and 30 correct answers. Backing beats
  start at ten, with 80, 100, and 120 BPM. The deadline stays at five seconds.
  A hit changes the ring and combo count without blocking the next question.
  The final two seconds add a visual warning after ten correct answers.
- Xiaohongshu 9.50+ uses light or medium native pulses for normal hits and
  medium or heavy pulses for milestones. Records use a heavy pulse. Wrong
  answers, timeouts, and corrections do not vibrate. Pending calls and calls
  within 180 ms are coalesced. Stalled calls fail after 1.5 seconds without an
  automatic retry. Unsupported clients retain sound and visual feedback.
- A new record is celebrated once per run after exceeding a previous best of
  at least five. The version 1 storage format and existing records are retained.
  Corrections no longer add to the streak. Timing samples and answer counts
  retain their previous rules. Score sharing uses the same saved statistics.
- The menu provides sound, beat, haptic, and reduced-motion settings for the
  current session. Reduced motion follows the system setting on load. Opening
  the menu or a sheet, or hiding the page, pauses the question and stops the
  backing beat and visual animation. Landscape uses a side menu and places
  the question beside the answer grid.
- All 54 Node tests passed. New coverage checks restored records, stage and
  pulse selection, correction rules, and one record celebration per run.
  Existing storage, sharing, native API, and audio lifecycle tests also passed.
- Build and package checks passed. Acorn 8.18.0 parsed all nine shipped scripts
  as ES2017. The fresh upload command still provides the official 1.8.0 Skill;
  its directory and ZIP audits passed with zero warnings. References were
  checked against the October 30 online API documentation.
- The ZIP has 12 files, 178,270 uncompressed bytes, and 116,516 compressed
  bytes. Artifact: `build/kana-1.0.3.zip`. SHA-256:
  `4bf355fe2ffdfbe44cedae99de82b0106b71b3e0714a5b83b0c01f64f71120c3`.
- Browser checks used the normal preview and a separate native API stub in
  `build/qa/v1.0.3`. They covered restoring a streak of 29, the heavy request
  at 30, matching score cards, cancelled notes, reload recovery, wrong answers,
  corrections, haptic disabling, and reduced motion. Layout checks included
  393 × 852, 320 × 568, and 844 × 390, with Chinese and French text. The stub
  is excluded from the ZIP. These checks do not establish native compatibility.
- The portal deployed this ZIP and accepted the release submission. Its remote
  simulator still timed out after 30 seconds, including before upload. Complete
  Android and iPhone checks of this final package remain pending. Chrome 61 CSS
  and device performance have not been measured.

## Version 1.0.2

Validation on November 3, 2026:

- All 36 Node tests passed. New cases cover real score snapshots, empty records,
  all eight note translations and length limits, public API fields, follow
  version checks, failure states, cancellation, and rate limits. Existing audio,
  storage, and practice tests also passed.
- Build and package checks passed. Acorn 8.18.0 parsed all seven shipped scripts
  as ES2017. The fresh upload-page command still provides the official
  `minitool-zip-builder` Skill 1.8.0. Both its directory and ZIP audits passed
  with no warnings. Reference checklists were reviewed against the October 30
  online API contract.
- The package has ten files and 153,569 uncompressed bytes. The ZIP is 109,202
  bytes, with `index.html` at its root. Artifact: `build/kana-1.0.2.zip`.
  SHA-256: `9e2d4f88609f09d9e9c6849e4ba044ea2c6b26876b805f493ac6d43f1734a1fa`.
- Local browser checks at 393 × 852 and 320 × 568 used a separate test-only
  native API stub. They covered image and note consistency, duplicate taps,
  cancelled notes, saved images, follow outcomes, old clients, empty records,
  and long French text and statistics. The stub is not in the ZIP. These checks
  verify UI behavior only, not the native bridge or container compatibility.
- The Creator platform accepted and deployed the ZIP and generated a mobile
  QR preview. Version 1.0.2 was submitted after the owner confirmed the
  release-page agreement. The platform shows `审核中 V1.0.2` (under review).
  Evidence is in `build/submission/v1.0.2`.
  The Creator platform later confirmed `已发布 V1.0.2` when the impact preview
  was prepared.
- The platform simulator still reports `remote simulator timed out after
  30000ms`, including before this ZIP was uploaded. The new note and follow
  flows have not been tested in the Android or iOS container. Chrome 61 CSS
  compatibility and device performance have not been measured.

## Previous releases

Local validation on November 3, 2026:

- All 28 Node tests passed, including timing, correction, storage failure,
  migration failure, write ordering, playback session selection, and native
  record restoration after initialization of a missing key.
- The build and local package checks passed. Acorn 8.15.0 parsed every shipped
  script with the ES2017 grammar.
- Earlier browser checks passed at 393 × 852, 320 × 568, 844 × 390, and 768 × 1024.
  Answering, timeout correction, menu pause, reload recovery, both chart forms,
  and the share preview were checked. These checks preceded the final container
  changes and do not establish container compatibility.
- The official `minitool-zip-builder` Skill 1.8.0 audit passed for both
  `build/web` and `build/kana-1.0.1.zip`, with no errors or warnings. Its reference
  checklists were reviewed against the current online documentation.
- The package contains nine files, 143,092 bytes before compression. The ZIP is
  105,762 bytes and has `index.html` at its root.
- Version 1.0.0 passed review and is published.
  AppID: `6ae99639339bd30014ae192b`.
- The owner reported that version 1.0.0 has audio only when iPhone silent mode
  is off. The owner also observed a record-read error and loss of session data
  after reopening. The exact native storage error has not been captured.
- The owner confirmed in the iPhone QR preview that version 1.0.1 plays audio
  in silent mode and restores practice records after closing and reopening.
  It selects playback audio and handles a failed initial storage read only
  after confirming that no key exists.
- Version 1.0.1 passed review and is published. The Creator platform showed
  `已发布 V1.0.1` on November 3, 2026.
- The portal simulator timed out before it displayed the app. The same
  `remote simulator timed out after 30000ms` error occurred on the version
  update form before a new package was uploaded. This is an initialization
  failure; its underlying cause is not yet confirmed. Full Android and iOS
  container checks have not been completed.

For each release, use the current complete command from step one of the upload
page to obtain its official Skill. Run its audit and review its references
against the [online documentation](https://miniapp-sandbox.xiaohongshu.com/minitool/doc).
The local check script does not replace the official workflow.

Validate this same ZIP in the creator portal simulator and the Xiaohongshu app
on both Android and iOS: startup, background and resume, native storage,
safe-area layout, sound after a user gesture, photo permission denial, and the
note editor. Ordinary browser checks do not replace these checks. The local
scripts do not make account changes, uploads, or publication requests.
