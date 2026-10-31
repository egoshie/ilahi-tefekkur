import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';

class LiquidGlassPaywallSheet extends ConsumerStatefulWidget {
  const LiquidGlassPaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LiquidGlassPaywallSheet(),
    );
  }

  @override
  ConsumerState<LiquidGlassPaywallSheet> createState() => _LiquidGlassPaywallSheetState();
}

class _LiquidGlassPaywallSheetState extends ConsumerState<LiquidGlassPaywallSheet> {
  static const MethodChannel _nativeChannel = MethodChannel('com.ilahi.tefekkur/native_bridge');
  static const String _privacyUrl = 'https://egoshie.github.io/ilahi-tefekkur/privacy.html';
  static const String _eulaUrl = 'https://egoshie.github.io/ilahi-tefekkur/eula.html';
  String _selectedTier = 'annual';
  int _founderTapCount = 0;

  Future<void> _openOfficialUrl(String url) async {
    HapticFeedback.selectionClick();
    try {
      await _nativeChannel.invokeMethod('openExternalUrl', {'url': url});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumServiceProvider);
    final notifier = ref.read(premiumServiceProvider.notifier);
    final offer = premium.regionalOffer;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 34,
          enableBlur: true,
          blurSigma: 26,
          goldAccentBorder: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ListView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _founderTapCount++;
                      if (_founderTapCount >= 5) {
                        _founderTapCount = 0;
                        HapticFeedback.heavyImpact();
                        notifier.unlockFounderByUdidTap();
                      }
                    },
                    child: const BespokeVectorIcon(type: BespokeIconType.crownGem, color: Color(0xFFFFE082), size: 26),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Huzur Özel",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE082),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Sıfır Reklam • Tüm İlahi Kitaplar • Karşılaştırmalı Tefekkür",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _buildFeatureRow("Tevrat (39 Kitap) ve İncil (27 Kitap) Canlı Türkçe Külliyat"),
              _buildFeatureRow("15 Büyük Kıssada 3'lü Karşılaştırmalı İnceleme"),
              _buildFeatureRow("Arka Plan Kur'ân Tilaveti & Dynamic Island Medya"),
              _buildFeatureRow("Kilit Ekranı Saatlik Ayet Widget'ı & Hikâye Stüdyosu"),
              _buildFeatureRow("Sınırsız Zikirmatik & 99 Esmaül Hüsna Rehberi"),
              const SizedBox(height: 18),
              _buildPlanCard(id: 'monthly', title: "Aylık Plan", price: offer.monthlyPrice, subtitle: "Esnek aylık abonelik", badge: null),
              const SizedBox(height: 12),
              _buildPlanCard(id: 'annual', title: "Yıllık Huzur Planı", price: offer.annualPrice, subtitle: "${offer.annualMonthlyEquivalent} • Yıllık Abonelik", badge: "EN ÇOK TERCİH EDİLEN"),
              const SizedBox(height: 12),
              _buildPlanCard(id: 'lifetime', title: "Ömür Boyu Tam Erişim", price: offer.lifetimePrice, subtitle: "Tek seferlik ödeme • Süresiz kullanım", badge: "SINIRSIZ ERİŞİM"),
              const SizedBox(height: 16),
              if (premium.statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    premium.statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64FFDA)),
                  ),
                ),
              GlassContainer(
                goldAccentBorder: true,
                emeraldGlow: true,
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(vertical: 15),
                onTap: () async { await notifier.activatePlan(_selectedTier); },
                child: Center(
                  child: premium.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFE082)))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BespokeVectorIcon(type: BespokeIconType.checkBadge, color: Color(0xFF64FFDA), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              premium.isPremium ? "Huzur Özel Etkin" : "App Store ile Güvenle Abone Ol",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFE082)),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 11),
                onTap: () => notifier.restorePurchases(),
                child: const Center(
                  child: Text(
                    "Satın Alımları Geri Yükle (Restore Purchases)",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      emeraldGlow: true,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      onTap: () => _showLegalModal(context, isPrivacy: true),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(type: BespokeIconType.lockShield, color: Color(0xFF64FFDA), size: 16),
                          SizedBox(width: 7),
                          Flexible(child: Text("Gizlilik Politikası", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64FFDA)))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      onTap: () => _showLegalModal(context, isPrivacy: false),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(type: BespokeIconType.sacredScroll, color: Color(0xFFFFE082), size: 16),
                          SizedBox(width: 7),
                          Flexible(child: Text("Kullanım Koşulları (EULA)", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFFFE082)))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "114 Sure Kur'ân-ı Kerîm, sesli tilavet, ezan vakitleri ve kıble pusulası herkes için sonsuza dek ücretsizdir.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const BespokeVectorIcon(type: BespokeIconType.checkBadge, color: Color(0xFF64FFDA), size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildPlanCard({required String id, required String title, required String price, required String subtitle, required String? badge}) {
    final isSelected = _selectedTier == id;
    return GlassContainer(
      goldAccentBorder: isSelected,
      emeraldGlow: isSelected,
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      onTap: () => setState(() => _selectedTier = id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE082).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
              ),
              child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFE082))),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Text(price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF64FFDA))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  void _showLegalModal(BuildContext context, {required bool isPrivacy}) {
    final url = isPrivacy ? _privacyUrl : _eulaUrl;
    final title = isPrivacy ? "Gizlilik Politikası (Privacy Policy)" : "Kullanım Koşulları ve Lisans (EULA)";
    final body = isPrivacy
        ? "1. CİHAZ İÇİ ÖNCELİKLİ MİMARİ VE VERİ KORUMA\\nHuzur uygulaması kullanıcılarından hesap oluşturmasını talep etmez. Hiçbir reklam ağı ve takip kodu (Zero Tracking) barındırmaz.\\n\\n2. KONUM VE GALERİ İZİNLERİ\\n• Konum İzni: Yalnızca bulunduğunuz şehrin astronomik ezan vakitlerini ve Kıble açısını cihaz içinde hesaplamak için kullanılır.\\n• Fotoğraflar İzni: Yalnızca Paylaşım Stüdyosunda oluşturduğunuz ayet kartlarını galeriye kaydetmek için kullanılır.\\n\\nGeliştirici: Ege Deniz • berkwisy@gmail.com"
        : "1. LİSANS KAPSAMI VE ABONELİK KURALLARI\\n114 Sure Kur'ân-ı Kerîm, sesli tilavet, ezan vakitleri ve kıble pusulası ücretsizdir. Huzur Özel (Aylık ve Yıllık) abonelikleri, dönem bitiminden en az 24 saat önce iptal edilmediği sürece Apple ID hesabınız üzerinden otomatik yenilenir. Ayarlar &gt; Apple Kimliği &gt; Abonelikler menüsünden dilediğiniz an iptal edebilirsiniz.\\n\\nGeliştirici: Ege Deniz • berkwisy@gmail.com";
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 30,
        enableBlur: true,
        goldAccentBorder: !isPrivacy,
        emeraldGlow: isPrivacy,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BespokeVectorIcon(type: isPrivacy ? BespokeIconType.lockShield : BespokeIconType.sacredScroll, color: isPrivacy ? const Color(0xFF64FFDA) : const Color(0xFFFFE082), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFFFFE082)))),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white)),
            const SizedBox(height: 16),
            GlassContainer(
              borderRadius: 14,
              emeraldGlow: true,
              padding: const EdgeInsets.symmetric(vertical: 11),
              onTap: () => _openOfficialUrl(url),
              child: const Center(child: Text("Resmi Web Belgesini Safari'de Aç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF64FFDA)))),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(vertical: 10),
              onTap: () => Navigator.pop(ctx),
              child: const Center(child: Text("Kapat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
            ),
          ],
        ),
      ),
    );
  }
}
