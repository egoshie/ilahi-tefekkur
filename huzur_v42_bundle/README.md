# Huzur V4.2 — 3 adımlı kurulum paketi

Bu paket, mevcut Huzur V4.1 Flutter projesine sırayla uygulanacak üç betik ve bunların kullandığı kaynak dosyaları içerir.

## Kurulum

Önce ZIP arşivini sunucuna aktar ve aç. Ardından paketin açıldığı klasörde aşağıdaki komutları **sırayla** çalıştır:

```bash
bash scripts/ADIM_1_3.sh
bash scripts/ADIM_2_3.sh
bash scripts/ADIM_3_3.sh
```

Proje klasörün `~/ilahi_tefekkur` değilse her komutta yolu belirt:

```bash
HUZUR_PROJECT_DIR=/tam/proje/yolu bash scripts/ADIM_1_3.sh
HUZUR_PROJECT_DIR=/tam/proje/yolu bash scripts/ADIM_2_3.sh
HUZUR_PROJECT_DIR=/tam/proje/yolu bash scripts/ADIM_3_3.sh
```

ADIM 3/3, iOS dosyalarını Python `-c` ve `plistlib` ile üretir/günceller; YAML ve Ruby dosyalarını da heredoc kullanmadan yazar. Mevcut `AppDelegate.swift` dosyası değiştirilmeden önce `.v41.bak` uzantısıyla yedeklenir. `pubspec.yaml` da ADIM 1/3'te `.v41.bak` olarak saklanır.

GitHub push ADIM 3/3 sonunda sorulur. `y` demeden önce doğru depoda ve doğru branch'te olduğunu kontrol et. Force push kullanılmaz. Önceki sürümün içinde açık biçimde paylaşılmış bir GitHub erişim anahtarı bulunuyordu; o anahtarı iptal edip yenile. Bu pakette erişim anahtarı yoktur.

## Önemli proje gereksinimleri

- Kutsal metin ekranı, V4.1 projesinin mevcut `DatabaseService`, `app_models.dart`, `database_seeder.dart` ve SQLite veritabanını kullanmaya devam eder. Bu kaynaklar yüklenen V4.1 betiğinin içinde yer almıyordu; bu nedenle paket bunları uydurma metinlerle değiştirmez.
- Paket; 114 sure metaverisini, 39 Eski Ahit/Tevrat kitap kaydını, 27 Yeni Ahit/İncil kitap kaydını ve 99 Esma kaydını içerir. Tam ayet/bab çeviri dosyaları (`assets/data/quran_tr.json`, `torah_tr.json`, `gospel_tr.json`) kullanıcı tarafından lisanslı içerikle ayrıca sağlanmadı. Uygulamanın mevcut SQLite metinleri kullanılmaya devam eder. `OfflineSacredRepository` JSON dosyaları eklendiğinde okuyabilir.
- Esma kartındaki Ebced değeri Arapça karakterlerin klasik harf değerleri toplanarak hesaplanır. Bu sayı, belirli bir dinî tekrar sayısı veya dinî hüküm olarak sunulmaz.
- Widget ile uygulama arasındaki canlı veri paylaşımı için `group.com.ilahi.tefekkur` App Group'unu Apple Developer hesabında etkinleştirmen; App ID, widget extension ve imzalama profillerine tanımlaman gerekir.
- `sharePositionOrigin` kodda iOS paylaşım çağrısına verilir. share_plus dokümantasyonunda bunun özellikle iPad/macOS paylaşım penceresinin konumlandırılması için olduğu, iPhone'da etkisi olmadığı belirtilir.
- Paket Linux ortamında hazırlanmıştır. Shell sözdizimi, Ruby sözdizimi, YAML ve plist serileştirmesi kontrol edilmiştir; bu ortamda Flutter/Dart SDK ve Xcode bulunmadığı için `flutter analyze`, gerçek iOS derlemesi ve cihaz üzerinde galeri/widget testi yapılamamıştır. GitHub Actions derlemesi de henüz çalıştırılmamıştır.

## Paket içeriği

- `scripts/ADIM_1_3.sh` — bağımlılıklar, modeller, tema, prayer, bildirim/widget, ambiyans ve kullanıcı servisleri
- `scripts/ADIM_2_3.sh` — hikâye paylaşımı, canlı arama, favoriler, dashboard, Esma, Zikirmatik ve kaza/hatim ekranları
- `scripts/ADIM_3_3.sh` — Swift MethodChannel, WidgetKit, `plistlib` izinleri, Xcode extension target, GitHub Actions ve isteğe bağlı push
- `payload/` — adımların projeye kopyaladığı tüm kaynak kod ve ses varlıkları
