# Huzur Dünya — Firebase Veri Mimarisi

## Altyapı
- Firebase project: huzur-ai-20261108-76dccd
- Firestore database: (default)
- Edition: Standard
- Region: europe-west3
- Firebase Authentication: Apple Sign-In
- App Check: Apple DeviceCheck

## Güvenlik ilkeleri
- İstemciler Premium yetkisi belirleyemez.
- Premium doğrulaması güvenilir sunucu tarafında yapılır.
- Firestore sayaçları istemciden doğrudan artırılamaz.
- Her dua için kullanıcı başına tekil Âmin kaydı tutulur.
- Dua görünürlüğü createdAt + 24 saat ile sınırlandırılır.
- Süre dolumu için TTL tek başına kullanılmaz.
- Kesin GPS koordinatı saklanmaz.
- Bütün sunucu yazmaları kimlik doğrulama ve App Check kontrolünden geçer.
- İstekler idempotent tasarlanır.

## Koleksiyonlar

### duaPosts/{postId}
- authorUid
- body
- countryCode
- createdAt
- expiresAt
- status
- aminCount

### duaPosts/{postId}/amens/{uid}
- uid
- createdAt

### countryDhikrDaily/{date_countryCode}
- dateKey
- countryCode
- totalCount
- updatedAt

### dhikrBatches/{uid_requestId}
- uid
- requestId
- countryCode
- count
- createdAt

### userPrivateStats/{uid}
- uid
- countryCode
- totalDhikr
- updatedAt

## Güvenilir sunucu işlemleri
- createDua: Premium doğrulaması ve dua oluşturma.
- addAmin: Tekil Âmin kaydı ve atomik sayaç güncellemesi.
- syncDhikrBatch: Tekrarsız zikir senkronizasyonu.
- cleanupExpiredDuas: Süresi geçmiş içeriklerin temizlenmesi.

## Dağıtım ilkesi
- VDS yalnızca kod geliştirme ve dağıtım aracı olarak kullanılır.
- Uygulamanın çalışma altyapısı Firebase üzerinde kalır.
- Cloud Functions dağıtımı öncesinde Blaze gereksinimi ve maliyetler değerlendirilir.
- Bu aşamada Functions dağıtılmaz ve faturalandırma planı değiştirilmez.
