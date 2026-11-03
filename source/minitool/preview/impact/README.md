# Impact preview

An isolated prototype for hit feedback and five streak stages. It reuses the
Kana question data and practice engine. It does not read or write saved records
and does not change the production build or package version.

The production release now shares `app/audio.js`, `app/haptics.js`, and the
stage configuration in `app/feedback.js` with this prototype. The original
preview artifacts and screenshots below remain separate from release 1.0.3.

## Run

From `source/minitool`:

```sh
node scripts/build-impact.mjs
node --test tests/impact.test.cjs
python3 scripts/serve-impact.py --bind 127.0.0.1 --port 8805
```

Open `http://127.0.0.1:8805/`. For phone access on your Tailnet, pass your
Tailscale IP with `--bind`. The server exposes only `build/impact-preview`.

Pass an optional output directory to build a separate validation copy:

```sh
node scripts/build-impact.mjs build/qa/impact-refactor
```

The build produces:

- `build/impact-preview/preview.html`: a standalone file with embedded scripts,
  styles, and the existing Kana font.
- `build/impact-preview/kana-impact-preview.zip`: the native container package.
  It uses separate classic scripts and local assets. The browser vibration
  adapter is excluded.

The default build command still builds the production app.

## Try

1. Use the light, medium, and heavy buttons to compare touch feedback. Each
   button pauses practice, sound, and visual pulses before it sends a request.
2. Select a streak stage and use Hit, Milestone, Record, Break, or Countdown.
   These controls are demonstrations and do not create real scores.
3. Select the five-second practice mode. Only a correct first answer adds to
   the streak. A correction advances the question without adding a streak.
   Pausing preserves the remaining time. A new record is celebrated once per
   run, after exceeding a previous run of at least five correct answers.

| Streak | Stage | Backing beat | Normal hit | Stage milestone |
| --- | --- | --- | --- | --- |
| 0–4 | Start | Off | Light | — |
| 5–9 | Rhythm | Off | Light | Medium |
| 10–19 | Warm | 80 BPM | Medium | Medium |
| 20–29 | Sprint | 100 BPM | Medium | Heavy |
| 30+ | Peak | 120 BPM | Medium | Heavy |

The deadline stays at five seconds in all stages. After ten correct answers,
the final two seconds add a visual warning. The question and answers stay
stable while the border, orbit, combo count, and milestone stamp animate.
Reduced motion retains text and color feedback. Hiding the page stops the
beat and pauses the question; practice requires an explicit resume.

## Haptic limits

Xiaohongshu 9.50+ uses `xhs.miniTool.vibrateShort({type})`. Only a user action
can request a pulse. Calls within 180 ms and concurrent calls are coalesced.
A call that stalls for 1.5 seconds releases the pending state without an
automatic retry. A successful call means the API accepted the request; it
does not prove that the device vibrated.

Ordinary browsers use `navigator.vibrate` when available. The three durations
are 12, 24, and 40 ms, not native amplitude levels. On supported iPhone Safari
versions, a visible system switch offers one native switch click. It cannot
compare the three Xiaohongshu strengths. Device settings can affect feedback.

Sound starts after a user action. Audio Session playback is selected before
the AudioContext is created when available. Short gain ramps avoid abrupt
tone starts and stops. The prototype makes no network requests.

## Validation

Checked on November 4, 2026:

- All 50 project tests passed, including 14 impact tests for timing, correction
  scoring, stage bounds, records, native version checks, failed or stalled
  haptics, coalescing, and audio lifecycle.
- Official `minitool-zip-builder` 1.8.0 directory and ZIP audits passed with
  zero warnings. Acorn 8.18.0 parsed all seven native scripts as ES2017.
- The native ZIP contains ten files, 146,965 uncompressed bytes, and 107,409
  compressed bytes. SHA-256:
  `0adcf5421031d1d33ba2387f93c579bde375d5c99c350d8308468c486a9666fa`.
- Chrome checks covered all five stages, hit and record feedback, break and
  countdown reset, first-answer scoring, correction, pause, pure haptic
  controls, and reduced motion. Layout was inspected at desktop size,
  393 × 852, and 320 × 568. No horizontal overflow or application console
  errors were observed. These checks do not prove physical sound or vibration.
- The Creator platform accepted the ZIP and displayed deployment success.
  A mobile QR preview was generated. The form was left unsubmitted, with the
  release agreement unchecked. No version was published. The production
  version remains 1.0.2.
- The platform's remote simulator still timed out after 30 seconds. Native
  startup, safe areas, sound, and actual haptic strengths require phone checks
  through the QR preview. Android and iPhone hardware checks are not complete.

Screenshots and the verified QR code are in `build/impact-preview/evidence`.
`mobile-preview.png` is the platform screenshot. `mobile-preview-qr.png` is a
larger QR code with the same decoded payload, verified after generation.

References: [Xiaohongshu API](https://miniapp-sandbox.xiaohongshu.com/minitool/doc),
[Vibration API](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/vibrate),
[Safari 18 switch](https://webkit.org/blog/15865/webkit-features-in-safari-18-0/).
