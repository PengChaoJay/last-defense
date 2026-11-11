"""Generate small placeholder sound effects without external dependencies."""

from __future__ import annotations

import math
import random
import wave
from pathlib import Path


RATE = 44_100
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def render(name: str, duration: float, synth) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    frames = bytearray()
    count = int(RATE * duration)
    for i in range(count):
        t = i / RATE
        value = max(-1.0, min(1.0, synth(t, duration)))
        sample = int(value * 32767)
        frames.extend(sample.to_bytes(2, "little", signed=True))
    with wave.open(str(OUT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(frames)


def decay(t: float, duration: float, power: float = 2.0) -> float:
    return max(0.0, 1.0 - t / duration) ** power


random.seed(7)
render("shoot.wav", 0.09, lambda t, d: math.sin(2 * math.pi * (820 - 390 * t / d) * t) * decay(t, d) * 0.22)
render("hit.wav", 0.11, lambda t, d: (math.sin(2 * math.pi * 135 * t) * 0.5 + random.uniform(-0.35, 0.35)) * decay(t, d) * 0.32)
render("pickup.wav", 0.16, lambda t, d: math.sin(2 * math.pi * (540 + 900 * t / d) * t) * decay(t, d, 1.2) * 0.25)
render("upgrade.wav", 0.52, lambda t, d: math.sin(2 * math.pi * (330 + 220 * int(t * 8) / 4) * t) * decay(t, d, 0.7) * 0.22)
render("boss.wav", 0.85, lambda t, d: (math.sin(2 * math.pi * (88 - 25 * t / d) * t) + 0.35 * math.sin(2 * math.pi * 44 * t)) * decay(t, d, 0.5) * 0.28)
render("damage.wav", 0.20, lambda t, d: (math.sin(2 * math.pi * 76 * t) + random.uniform(-0.18, 0.18)) * decay(t, d) * 0.30)
render("victory.wav", 0.95, lambda t, d: math.sin(2 * math.pi * [392, 494, 587, 784][min(3, int(t / d * 4))] * t) * decay(t % (d / 4), d / 4, 0.8) * 0.22)
