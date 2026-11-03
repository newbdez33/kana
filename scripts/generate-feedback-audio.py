#!/usr/bin/env python3
"""Render the mini-tool tone recipe as shared native PCM assets."""
import math
import pathlib
import struct
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "source/shared/feedback/raw"
RATE = 24000


def render(name, tones):
    length = max(start + duration for _, start, duration, _, _, _ in tones) + 0.02
    samples = [0.0] * math.ceil(length * RATE)
    for frequency, start, duration, amplitude, triangle, end in tones:
        phase = 0.0
        for index in range(math.ceil(duration * RATE)):
            t = index / RATE
            hz = frequency * (end / frequency) ** (t / duration) if end else frequency
            phase += hz / RATE
            signal = (2 / math.pi * math.asin(math.sin(2 * math.pi * phase))
                      if triangle else math.sin(2 * math.pi * phase))
            gain = (0.0001 * (amplitude / 0.0001) ** (t / 0.007) if t < 0.007
                    else amplitude * (0.0001 / amplitude) ** ((t - 0.007) / (duration - 0.007)))
            samples[round(start * RATE) + index] += signal * gain
    assert max(abs(sample) for sample in samples) < 1, name
    with wave.open(str(OUTPUT / (name + ".wav")), "wb") as file:
        file.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        file.writeframes(b"".join(struct.pack("<h", round(sample * 32767)) for sample in samples))


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for stage, base in enumerate([660, 740, 830, 880, 990]):
        for kind in ["hit", "milestone", "record"]:
            tones = [(170, 0, 0.045, 0.11, True, 55), (base, 0.018, 0.11, 0.065, False, None)]
            if kind != "hit":
                tones += [(base * ratio, 0.055 + index * 0.055, 0.22, 0.045, False, None)
                          for index, ratio in enumerate([1, 1.25, 1.5])]
            if kind == "record":
                tones.append((base * 2, 0.22, 0.28, 0.035, False, None))
            render(f"feedback_{kind}_{stage}", tones)
    render("feedback_broken", [(240, 0, 0.17, 0.075, False, 100)])
    render("feedback_correction", [(540, 0, 0.08, 0.045, False, None)])
    render("feedback_beat", [(145, 0, 0.11, 0.035, False, 70)])
    print("Rendered 18 native feedback sounds.")


if __name__ == "__main__":
    main()
