#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${HUZUR_PROJECT_DIR:-$HOME/ilahi_tefekkur}"
PAYLOAD="$BUNDLE_DIR/payload"

cd "$PROJECT_DIR"
mkdir -p ios/Runner ios/HuzurWidget .github/workflows
if [[ -f ios/Runner/AppDelegate.swift && ! -f ios/Runner/AppDelegate.swift.v41.bak ]]; then
  cp -p ios/Runner/AppDelegate.swift ios/Runner/AppDelegate.swift.v41.bak
fi

# AppDelegate.swift, WidgetKit Swift, Ruby ve GitHub Actions YAML dosyaları
# mobil terminalde bozulabilen heredoc/YAML girintileri kullanılmadan Python ile yazılır.
python3 -c 'import base64,pathlib; p=pathlib.Path("ios/Runner/AppDelegate.swift"); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(base64.b64decode("'"$(base64 -w0 "$PAYLOAD/ios/Runner/AppDelegate.swift")"'"))'
python3 -c 'import base64,pathlib; p=pathlib.Path("ios/HuzurWidget/HuzurWidget.swift"); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(base64.b64decode("'"$(base64 -w0 "$PAYLOAD/ios/HuzurWidget/HuzurWidget.swift")"'"))'
python3 -c 'import base64,pathlib; p=pathlib.Path("ios/fix_and_add_widget.rb"); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(base64.b64decode("'"$(base64 -w0 "$PAYLOAD/ios/fix_and_add_widget.rb")"'"))'
python3 -c 'import base64,pathlib; p=pathlib.Path(".github/workflows/build_ios_ipa.yml"); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(base64.b64decode("'"$(base64 -w0 "$PAYLOAD/.github/workflows/build_ios_ipa.yml")"'"))'

# Runner Info.plist izinlerini plistlib ile güvenli şekilde birleştir.
python3 -c 'import pathlib,plistlib; p=pathlib.Path("ios/Runner/Info.plist"); d=plistlib.loads(p.read_bytes()) if p.exists() else {}; d["NSPhotoLibraryAddUsageDescription"]="Huzur, oluşturduğun ayet hikâye kartlarını Fotoğraflar arşivine kaydetmek için izin ister."; d["NSPhotoLibraryUsageDescription"]="Huzur, ayet kartlarını Fotoğraflar arşivine kaydetmek için fotoğraf kitaplığı erişimi ister."; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(plistlib.dumps(d,fmt=plistlib.FMT_XML,sort_keys=False))'

# WidgetKit extension Info.plist dosyası plistlib ile oluşturulur.
python3 -c 'import pathlib,plistlib; p=pathlib.Path("ios/HuzurWidget/Info.plist"); d={"CFBundleDisplayName":"Huzur Widget","CFBundleIdentifier":"$(PRODUCT_BUNDLE_IDENTIFIER)","CFBundleName":"$(PRODUCT_NAME)","CFBundlePackageType":"XPC!","CFBundleShortVersionString":"$(MARKETING_VERSION)","CFBundleVersion":"$(CURRENT_PROJECT_VERSION)","MinimumOSVersion":"16.0","NSExtension":{"NSExtensionPointIdentifier":"com.apple.widgetkit-extension"}}; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(plistlib.dumps(d,fmt=plistlib.FMT_XML,sort_keys=False))'

# App Group entitlement iki hedef için de oluşturulur/korunur.
python3 -c 'import pathlib,plistlib; group="group.com.ilahi.tefekkur"; key="com.apple.security.application-groups"; paths=[pathlib.Path("ios/Runner/Runner.entitlements"),pathlib.Path("ios/HuzurWidget/HuzurWidget.entitlements")]; [(p.parent.mkdir(parents=True,exist_ok=True), (lambda d: (d.__setitem__(key,list(dict.fromkeys(d.get(key,[])+[group]))), p.write_bytes(plistlib.dumps(d,fmt=plistlib.FMT_XML,sort_keys=False))))(plistlib.loads(p.read_bytes()) if p.exists() else {})) for p in paths]'

ruby -c ios/fix_and_add_widget.rb
if ! ruby -e 'require "xcodeproj"' >/dev/null 2>&1; then
  gem install --user-install xcodeproj --no-document
fi
ruby ios/fix_and_add_widget.rb

python3 -c 'import pathlib,plistlib; paths=[pathlib.Path("ios/Runner/Info.plist"),pathlib.Path("ios/HuzurWidget/Info.plist"),pathlib.Path("ios/Runner/Runner.entitlements"),pathlib.Path("ios/HuzurWidget/HuzurWidget.entitlements")]; [(plistlib.loads(p.read_bytes())) for p in paths]; print("Info.plist ve entitlements kontrolleri tamam.")'

export PATH="$PATH:$HOME/flutter/bin"
flutter pub get

echo
echo "ADIM 3/3 dosyaları hazırlandı. Widget hedefi Xcode projesine eklendi."
echo "GitHub Actions build dosyası: .github/workflows/build_ios_ipa.yml"
echo "App Group: group.com.ilahi.tefekkur"
echo "Önemli: App Group kimliğini Apple Developer hesabında etkinleştirip App ID ve provisioning profiline tanımlamalısın."

if [[ -d .git ]]; then
  echo
  read -r -p "Değişiklikleri commit edip mevcut GitHub origin adresine push edeyim mi? [y/N] " PUSH_ANSWER
  if [[ "$PUSH_ANSWER" =~ ^[Yy]$ ]]; then
    if ! git config user.name >/dev/null; then git config user.name "Huzur V4.2 Builder"; fi
    if ! git config user.email >/dev/null; then git config user.email "huzur-v42@users.noreply.github.com"; fi
    CURRENT_ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$CURRENT_ORIGIN" == *"ghp_"* || "$CURRENT_ORIGIN" == *"github_pat_"* ]]; then
      git remote set-url origin "https://github.com/egoshie/ilahi-tefekkur.git"
      echo "Gömülü erişim anahtarı içeren origin adresi temizlendi. GitHub kimlik doğrulaması ayarlı olmalı."
    fi
    git add -A
    if ! git diff --cached --quiet; then
      git commit -m "Huzur V4.2: story gallery save, scripture search, bookmarks and WidgetKit"
    else
      echo "Commit edilecek yeni değişiklik bulunamadı."
    fi
    git push -u origin HEAD
  else
    echo "Push atlandı. İnceledikten sonra: git add -A && git commit -m 'Huzur V4.2' && git push -u origin HEAD"
  fi
else
  echo "Git deposu bulunamadı; GitHub push adımı atlandı."
fi
