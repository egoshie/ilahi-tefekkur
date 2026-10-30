#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${HUZUR_PROJECT_DIR:-$HOME/ilahi_tefekkur}"
PAYLOAD="$BUNDLE_DIR/payload"

if [[ ! -d "$PROJECT_DIR/lib" ]]; then
  echo "Hata: Flutter lib klasörü bulunamadı: $PROJECT_DIR"
  exit 1
fi

mkdir -p "$PROJECT_DIR/lib/core/theme" "$PROJECT_DIR/lib/features/dashboard" "$PROJECT_DIR/lib/features/paywall" "$PROJECT_DIR/lib/features/sacred_texts" "$PROJECT_DIR/lib/features/qibla_and_extras" "$PROJECT_DIR/lib/features/esma" "$PROJECT_DIR/lib/features/tasbih"

cp "$PAYLOAD/lib/core/theme/story_share_sheet.dart" "$PROJECT_DIR/lib/core/theme/story_share_sheet.dart"
cp "$PAYLOAD/lib/features/sacred_texts/sacred_texts_screen.dart" "$PROJECT_DIR/lib/features/sacred_texts/sacred_texts_screen.dart"
cp "$PAYLOAD/lib/features/dashboard/main_dashboard_screen.dart" "$PROJECT_DIR/lib/features/dashboard/main_dashboard_screen.dart"
cp "$PAYLOAD/lib/features/qibla_and_extras/qibla_and_tools_screen.dart" "$PROJECT_DIR/lib/features/qibla_and_extras/qibla_and_tools_screen.dart"
cp "$PAYLOAD/lib/features/paywall/liquid_glass_paywall.dart" "$PROJECT_DIR/lib/features/paywall/liquid_glass_paywall.dart"
cp "$PAYLOAD/lib/features/esma/esmaul_husna_sheet.dart" "$PROJECT_DIR/lib/features/esma/esmaul_husna_sheet.dart"
cp "$PAYLOAD/lib/features/tasbih/fluid_tasbih_screen.dart" "$PROJECT_DIR/lib/features/tasbih/fluid_tasbih_screen.dart"
cp "$PAYLOAD/lib/main.dart" "$PROJECT_DIR/lib/main.dart"

export PATH="$PATH:$HOME/flutter/bin"
cd "$PROJECT_DIR"
flutter pub get

echo
echo "ADIM 2/3 tamamlandı. Story Share, canlı arama, ayet vurgulama, favoriler, kaldığın yer, Esma, Zikirmatik ve hatim/kaza takip ekranları yazıldı."
echo "Not: Tamamlanmış sure ve kitap metinleri V4.1 projesindeki mevcut SQLite veritabanından okunmaya devam eder."
