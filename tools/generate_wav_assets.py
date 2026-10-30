#!/usr/bin/env python3
"""
Huzur V4.2 - Sentetik Meditatif Ambiyans WAV Üreticisi.
Not: Bu dosyalar matematiksel harmonik ve filtrelenmiş gürültü sentezidir;
çevrimdışı döngüsel (loop) odaklanma ses katmanı olarak kullanılır.
"""
import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
DURATION_SEC = 6
NUM_SAMPLES = SAMPLE_RATE * DURATION_SEC
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")


def write_wav(filename: str, samples: list[int]) -> None:
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    filepath = os.path.join(OUTPUT_DIR, filename)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        packed = struct.pack("<" + ("h" * len(samples)), *samples)
        wav_file.writeframes(packed)
    print(f"Olusturuldu: {filepath} ({os.path.getsize(filepath)} byte)")


def envelope(t: float) -> float:
    fade = 0.35
    if t < fade:
        return t / fade
    if t > DURATION_SEC - fade:
        return (DURATION_SEC - t) / fade
    return 1.0


def generate_all() -> None:
    rng = random.Random(42)

    # 1. Sentetik Ney / Harmonik Huzur Frekansı (216Hz / 432Hz)
    ney_samples = []
    for i in range(NUM_SAMPLES):
        t = i / SAMPLE_RATE
        env = envelope(t)
        breath = 0.78 + 0.22 * math.sin(2.0 * math.pi * (t / DURATION_SEC))
        vibrato = math.sin(2.0 * math.pi * 4.0 * t) * 0.9
        f = 216.0 + vibrato
        sig = (
            math.sin(2.0 * math.pi * f * t) * 0.40
            + math.sin(2.0 * math.pi * (f * 2.0) * t) * 0.16
            + math.sin(2.0 * math.pi * (f * 1.5) * t) * 0.10
        )
        val = int(max(-32760, min(32760, sig * breath * env * 16000)))
        ney_samples.append(val)
    write_wav("ney.wav", ney_samples)

    # 2. Sentetik Yağmur Dokusu
    rain_samples = []
    lp = 0.0
    for i in range(NUM_SAMPLES):
        t = i / SAMPLE_RATE
        env = envelope(t)
        white = rng.uniform(-1.0, 1.0)
        lp = lp * 0.88 + white * 0.12
        drop = math.sin(2.0 * math.pi * 980.0 * t) * 0.20 if rng.random() > 0.997 else 0.0
        sig = lp * 0.65 + drop
        val = int(max(-32760, min(32760, sig * env * 14000)))
        rain_samples.append(val)
    write_wav("rain.wav", rain_samples)

    # 3. Sentetik Su Akışı Dokusu
    water_samples = []
    brown = 0.0
    for i in range(NUM_SAMPLES):
        t = i / SAMPLE_RATE
        env = envelope(t)
        white = rng.uniform(-1.0, 1.0)
        brown = (brown + 0.03 * white) / 1.03
        mod = 0.65 + 0.35 * math.sin(2.0 * math.pi * 0.5 * t)
        sig = brown * mod + math.sin(2.0 * math.pi * 128.0 * t) * 0.12
        val = int(max(-32760, min(32760, sig * env * 15000)))
        water_samples.append(val)
    write_wav("water.wav", water_samples)

    # 4. Sentetik Gece Rüzgarı Dokusu
    wind_samples = []
    band = 0.0
    for i in range(NUM_SAMPLES):
        t = i / SAMPLE_RATE
        env = envelope(t)
        white = rng.uniform(-1.0, 1.0)
        band = band * 0.95 + white * 0.05
        sweep = 0.55 + 0.45 * math.sin(2.0 * math.pi * (t / DURATION_SEC))
        sig = band * sweep + math.sin(2.0 * math.pi * 108.0 * t) * 0.15
        val = int(max(-32760, min(32760, sig * env * 15000)))
        wind_samples.append(val)
    write_wav("wind.wav", wind_samples)


if __name__ == "__main__":
    generate_all()
