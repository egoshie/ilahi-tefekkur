#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${HUZUR_PROJECT_DIR:-$HOME/ilahi_tefekkur}"
PAYLOAD="$BUNDLE_DIR/payload"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Hata: Flutter proje klasörü bulunamadı: $PROJECT_DIR"
  echo "Proje yolunu HUZUR_PROJECT_DIR=/proje/yolu şeklinde belirleyebilirsin."
  exit 1
fi

if [[ -f "$PROJECT_DIR/pubspec.yaml" && ! -f "$PROJECT_DIR/pubspec.yaml.v41.bak" ]]; then
  cp -p "$PROJECT_DIR/pubspec.yaml" "$PROJECT_DIR/pubspec.yaml.v41.bak"
fi

mkdir -p "$PROJECT_DIR/lib/core/models" "$PROJECT_DIR/lib/core/services" "$PROJECT_DIR/lib/core/theme" "$PROJECT_DIR/assets/audio" "$PROJECT_DIR/assets/data"

cp "$PAYLOAD/pubspec.yaml" "$PROJECT_DIR/pubspec.yaml"
cp "$PAYLOAD/lib/core/models/v42_models.dart" "$PROJECT_DIR/lib/core/models/v42_models.dart"
cp "$PAYLOAD/lib/core/services/offline_sacred_repository.dart" "$PROJECT_DIR/lib/core/services/offline_sacred_repository.dart"
cp "$PAYLOAD/lib/core/services/notification_service.dart" "$PROJECT_DIR/lib/core/services/notification_service.dart"
cp "$PAYLOAD/lib/core/services/ambiance_mixer_service.dart" "$PROJECT_DIR/lib/core/services/ambiance_mixer_service.dart"
cp "$PAYLOAD/lib/core/services/tasbih_session_service.dart" "$PROJECT_DIR/lib/core/services/tasbih_session_service.dart"
cp "$PAYLOAD/lib/core/services/user_progress_service.dart" "$PROJECT_DIR/lib/core/services/user_progress_service.dart"
cp "$PAYLOAD/lib/core/services/prayer_service.dart" "$PROJECT_DIR/lib/core/services/prayer_service.dart"
cp "$PAYLOAD/lib/core/theme/liquid_glass_theme.dart" "$PROJECT_DIR/lib/core/theme/liquid_glass_theme.dart"
cp "$PAYLOAD/lib/core/theme/glass_container.dart" "$PROJECT_DIR/lib/core/theme/glass_container.dart"
cp -R "$PAYLOAD/assets/audio/." "$PROJECT_DIR/assets/audio/"
cp -R "$PAYLOAD/assets/data/." "$PROJECT_DIR/assets/data/"

export PATH="$PATH:$HOME/flutter/bin"
cd "$PROJECT_DIR"
flutter pub get

echo
echo "ADIM 1/3 tamamlandı. Temel modeller, tema, vakit, bildirim/widget, ambiyans, çevrimdışı katalog ve kalıcı kullanıcı servisleri yazıldı."
