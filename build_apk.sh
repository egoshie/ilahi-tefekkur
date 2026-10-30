#!/usr/bin/env bash
set -e

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/android-sdk
export PATH="$PATH:$HOME/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

cd $HOME/ilahi_tefekkur

echo "=========================================================="
echo "[1/3] Paketler dogrulaniyor..."
echo "=========================================================="
flutter pub get

echo "=========================================================="
echo "[2/3] V2.0 ARM64 Release APK derleniyor (Önbellek Korunarak)..."
echo "=========================================================="
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

APK_PATH="$HOME/ilahi_tefekkur/build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
  echo "HATA: APK dosyasi olusturulamadi!"
  exit 1
fi

echo "=========================================================="
echo "[3/3] APK Gofile.io sunucusuna yukleniyor..."
echo "=========================================================="

UPLOAD_RESPONSE=$(curl -s -F "file=@$APK_PATH" https://upload.gofile.io/uploadfile)

DOWNLOAD_URL=$(python3 -c "
import sys, json
try:
    data = json.loads('''$UPLOAD_RESPONSE''')
    if data.get('status') == 'ok':
        print(data['data']['downloadPage'])
    else:
        print('FALLBACK')
except Exception:
    print('FALLBACK')
")

if [ "$DOWNLOAD_URL" = "FALLBACK" ] || [ -z "$DOWNLOAD_URL" ]; then
  SERVER=$(curl -s https://api.gofile.io/servers | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['servers'][0]['name'])" 2>/dev/null || echo "store1")
  UPLOAD_RESPONSE=$(curl -s -F "file=@$APK_PATH" "https://${SERVER}.gofile.io/contents/uploadfile")
  DOWNLOAD_URL=$(python3 -c "import sys, json; print(json.loads('''$UPLOAD_RESPONSE''')['data']['downloadPage'])" 2>/dev/null || echo "Yanit: $UPLOAD_RESPONSE")
fi

echo ""
echo "=========================================================="
echo "DERLEME VE GOFILE YUKLEMESI TAMAMLANDI!"
echo "Yerel APK Yolu : $APK_PATH"
echo "GOFILE INDIRME LINKI : $DOWNLOAD_URL"
echo "=========================================================="
