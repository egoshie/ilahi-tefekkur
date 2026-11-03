#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets/data/hourly_verses.json"
DART = ROOT / "lib/core/data/hourly_verses.g.dart"
SWIFT = ROOT / "ios/HuzurWidget/HuzurWidget.swift"

TOTAL = 69
WIDGET_TOTAL = 27


def quote_dart(value):
    return (
        '"' + value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("$", "\\$")
        .replace("\n", "\\n") + '"'
    )


def quote_swift(value):
    return (
        '"' + value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n") + '"'
    )


def load_data():
    data = json.loads(DATA.read_text(encoding="utf-8"))

    if data.get("schemaVersion") != 1:
        raise ValueError("JSON şema sürümü hatalı.")

    verses = data.get("verses")

    if not isinstance(verses, list) or len(verses) != TOTAL:
        raise ValueError("69 ayet kaydı bekleniyor.")

    keys = set()

    for i, v in enumerate(verses):
        required = {
            "index", "ayahKey", "arabicShort",
            "turkishShort", "reference", "widgetEligible"
        }

        if not required.issubset(v):
            raise ValueError(f"Eksik alan: {i}")

        if v["index"] != i:
            raise ValueError(f"İndeks hatası: {i}")

        if v["ayahKey"] in keys:
            raise ValueError("Tekrarlanan ayet: " + v["ayahKey"])

        keys.add(v["ayahKey"])

        for field in ("ayahKey", "arabicShort", "turkishShort", "reference"):
            if not isinstance(v[field], str) or not v[field].strip():
                raise ValueError(f"Geçersiz alan: {field}, kayıt {i}")

        expected = (
            v["ayahKey"] != "25:63"
            and len(v["arabicShort"].strip().split()) <= 4
            and len(v["turkishShort"].strip().split()) <= 4
        )

        if not isinstance(v["widgetEligible"], bool):
            raise ValueError("widgetEligible boolean olmalı.")

        if v["widgetEligible"] != expected:
            raise ValueError("Widget seçim kuralı uyuşmuyor: " + v["ayahKey"])

    selected = [v for v in verses if v["widgetEligible"]]

    if len(selected) != WIDGET_TOTAL:
        raise ValueError("27 widget kaydı bekleniyor.")

    return verses, selected


def dart_record(v):
    return (
        "  HourlyShortVerse(\n"
        f"    index: {v['index']},\n"
        f"    ayahKey: {quote_dart(v['ayahKey'])},\n"
        f"    arabicShort: {quote_dart(v['arabicShort'])},\n"
        f"    turkishShort: {quote_dart(v['turkishShort'])},\n"
        f"    reference: {quote_dart(v['reference'])},\n"
        "  ),"
    )


def render_dart(verses, selected):
    lines = [
        "// GENERATED FILE — DO NOT EDIT MANUALLY.",
        "// Source: assets/data/hourly_verses.json",
        "// Run: python3 tools/generate_hourly_verse_catalog.py",
        "",
        "import '../models/v42_models.dart';",
        "",
        "const List<HourlyShortVerse> kHourlyShortVerseCatalog =",
        "    <HourlyShortVerse>[",
    ]

    lines.extend(dart_record(v) for v in verses)
    lines.extend([
        "];",
        "",
        "const List<HourlyShortVerse> kHourlyWidgetShortVerses =",
        "    <HourlyShortVerse>[",
    ])
    lines.extend(dart_record(v) for v in selected)
    lines.extend(["];", ""])

    return "\n".join(lines)


def render_swift(selected):
    return "\n".join(
        "        ("
        + quote_swift(v["arabicShort"]) + ", "
        + quote_swift(v["turkishShort"]) + ", "
        + quote_swift(v["reference"]) + "),"
        for v in selected
    )


def get_swift_region(text):
    pattern = re.compile(
        r"(?ms)^        // BEGIN GENERATED HOURLY VERSES\n"
        r"(.*?)"
        r"^        // END GENERATED HOURLY VERSES"
    )
    matches = list(pattern.finditer(text))

    if len(matches) != 1:
        raise ValueError("Swift üretim alanı eksik veya tekrarlı.")

    return matches[0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    verses, selected = load_data()
    dart_expected = render_dart(verses, selected)
    swift_expected = render_swift(selected)

    swift_text = SWIFT.read_text(encoding="utf-8")
    match = get_swift_region(swift_text)

    # Marker ile üretilmiş son kayıt arasında satır sonu korunur.
    swift_actual = match.group(1).rstrip("\n")

    if args.check:
        if not DART.is_file():
            raise ValueError("Dart üretim dosyası bulunamadı.")

        dart_actual = DART.read_text(encoding="utf-8")

        if dart_actual != dart_expected:
            raise ValueError(
                "Dart çıktısı JSON ile eşleşmiyor. "
                "Üretilen dosyayı elle formatlama."
            )

        if swift_actual != swift_expected:
            raise ValueError("Swift çıktısı JSON ile eşleşmiyor.")

        print("JSON kayıtları:", len(verses))
        print("Widget kayıtları:", len(selected))
        print("Dart üretimi: GÜNCEL")
        print("Swift üretimi: GÜNCEL")
        print("Tek kaynak kontrolü: BAŞARILI")
        return

    DART.parent.mkdir(parents=True, exist_ok=True)
    DART.write_text(dart_expected, encoding="utf-8")

    updated = (
        swift_text[:match.start(1)]
        + swift_expected
        + "\n"
        + swift_text[match.end(1):]
    )
    SWIFT.write_text(updated, encoding="utf-8")

    print("Dart üretildi:", len(verses))
    print("Swift üretildi:", len(selected))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("ÜRETİM HATASI:", exc, file=sys.stderr)
        sys.exit(1)
