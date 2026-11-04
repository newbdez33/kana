# Native practice feedback

iOS and Android use the same feedback rules as the Xiaohongshu mini-tool.
The question deadline stays at five seconds in every stage.

| Correct streak | Stage | Rhythm | Regular haptic |
| --- | --- | --- | --- |
| 0–4 | Warm up | Off | Light |
| 5–9 | In rhythm | Off | Light |
| 10–19 | Focused | 80 BPM | Medium |
| 20–29 | On fire | 100 BPM | Medium |
| 30+ | Full flow | 120 BPM | Medium |

Milestones at 5 and 10 use medium haptics. Milestones at 20, 30, and each
subsequent multiple of ten use heavy haptics. A new record also uses heavy
haptics, once per run, when the previous best was at least five.
Pulses within 180 ms of the last accepted pulse are dropped, not queued.

Wrong answers and timeouts reset the streak. A correction has a soft tone and
does not add a record or trigger a haptic. An answer at or after the deadline
cannot extend the streak, even if the timer callback has not run yet.

The ring, streak count, and short milestone message carry the motion. The kana
and answer targets stay fixed. Sound, rhythm, haptics, and reduced motion can
be changed in the practice menu for the current session. System motion settings
and Android touch-feedback settings are also respected. Menus, sheets, consent
forms, audio interruptions on iOS, and background activity pause the applicable
practice timer and stop feedback. No missed rhythm beats are replayed.
On iOS, returning to the foreground or tapping a visible answer clears a stale
audio interruption. Delayed suspension notices do not block answers. The audio
session is released in the background; menu and consent pauses remain in force.

## Audio assets

Both apps package the PCM files in `source/shared/feedback/raw`. Regenerate them
from the mini-tool tone recipe with:

```sh
python3 scripts/generate-feedback-audio.py
```

The generator has no external dependencies and checks peak amplitude. It uses
short gain ramps at both ends of each tone. iOS retains the playback audio
category with mixing enabled. Android uses SoundPool without taking audio focus.

## Verification

Model tests cover stage boundaries, the rhythm cap, record suppression and reset,
haptic strength, and pulse throttling. Practice tests cover corrections, the
deadline race, pause overlap, and rhythm cancellation. Android UI tests advance
through all stages and check the settings menu. iOS tests cover forty successive
answers, four stable choices, layout changes, and the shared audio bundle.
Audio interruption tests cover delayed suspension notices, missing end notices,
and pause overlap. A UI test returns from Home twice and checks that answers
still update the saved count. Pixel tests on both platforms check that the
visible kana and romaji glyphs are centered.

Simulator tests verify events and layout. On 2026-11-04, the Galaxy S22 Ultra
executed light, medium, and heavy native vibration patterns. System vibration
history confirms successful effects. Disabling haptics stopped new app vibration
events. This verifies device execution, not subjective strength or audible volume.
Final release checks are recorded in `docs/releases/2026-11-04-android-s22.md`.
