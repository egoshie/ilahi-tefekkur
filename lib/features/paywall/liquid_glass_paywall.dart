import 'dart:async';
import 'dart:math';
import 'package:material_ui/material_ui.dart';
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
  ConsumerState<LiquidGlassPaywallSheet> createState() =>
      _LiquidGlassPaywallSheetState();
}

class _LiquidGlassPaywallSheetState
    extends ConsumerState<LiquidGlassPaywallSheet> {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.ilahi.tefekkur/native_bridge');

  static const String _privacyUrl =
      'https://egoshie.github.io/ilahi-tefekkur/privacy.html';

  static const String _eulaUrl =
      'https://egoshie.github.io/ilahi-tefekkur/eula.html';

  String _selectedTier = 'annual';

  Future<void> _openOfficialUrl(String url) async {
    HapticFeedback.selectionClick();
    try {
      await _nativeChannel.invokeMethod(
        'openExternalUrl',
        {'url': url},
      );
    } catch (_) {}
  }

  // HUZUR_17_3_PAYWALL
  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumServiceProvider);
    final notifier = ref.read(premiumServiceProvider.notifier);
    final offer = premium.regionalOffer;

    final selectedStoreId = _selectedTier == 'monthly'
        ? PremiumServiceNotifier.kMonthlyId
        : _selectedTier == 'annual'
            ? PremiumServiceNotifier.kAnnualId
            : PremiumServiceNotifier.kLifetimeId;

    final selectedPlanAlreadyActive = premium.isPremium &&
        (premium.activePlanId == selectedStoreId ||
            premium.activePlanId == PremiumServiceNotifier.kLifetimeId);

    final activePlanName =
        premium.activePlanId == PremiumServiceNotifier.kMonthlyId
            ? 'Aylık Huzur Planı'
            : premium.activePlanId == PremiumServiceNotifier.kAnnualId
                ? 'Yıllık Huzur Planı'
                : premium.activePlanId == PremiumServiceNotifier.kLifetimeId
                    ? 'Ömür Boyu Tam Erişim'
                    : 'Huzur Özel';

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.68,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 32,
          enableBlur: true,
          blurSigma: 24,
          goldAccentBorder: true,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 22),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF153B3B),
                        Color(0xFF0A1D2A),
                        Color(0xFF211A12),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFD98A).withValues(alpha: 0.38),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A58B).withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE082).withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFFFE082).withValues(alpha: 0.36),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFFFE082),
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HUZUR ÖZEL',
                                  style: TextStyle(
                                    color: Color(0xFFFFE082),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Huzur’un bütün imkânları',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Kapat',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'Daha derin keşfet. Daha özgür dinle. Huzur’un tüm özel araçlarını tek üyelikte kullan.',
                        style: TextStyle(
                          color: Color(0xDDEEEEEE),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHeroPill(Icons.block_rounded, 'Reklamsız deneyim'),
                          _buildHeroPill(Icons.all_inclusive_rounded, 'Sınırsız erişim'),
                          _buildHeroPill(Icons.lock_rounded, 'Apple üzerinden güvenli ödeme'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14283A).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD98A).withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFFFD77A), size: 25),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Huzur Dini Asistanı',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '3 ücretsiz soru. Huzur Özel ile sınırsız soru ve görsel inceleme.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle_rounded, color: Color(0xFF63D6B4), size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'HUZUR ÖZEL İLE AÇILANLAR',
                  style: TextStyle(
                    color: Color(0xFFFFD77A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBenefitCard(
                  Icons.menu_book_rounded,
                  'İlahi kitaplar ve karşılaştırmalı tefekkür',
                  'Tevrat’ın 39, İncil’in 27 kitabı ve 15 büyük kıssada üçlü karşılaştırmalı inceleme.',
                ),
                _buildBenefitCard(
                  Icons.headphones_rounded,
                  'Sınırsız Kur’an tilaveti',
                  'İlk 3 sure ücretsiz dinlenebilir; Huzur Özel ile diğer surelerde de sınırsız dinleme.',
                ),
                _buildBenefitCard(
                  Icons.graphic_eq_rounded,
                  'Arka plan sesi ve Dynamic Island',
                  'Tilaveti arka planda sürdür; kilit ekranı ve Dynamic Island medya kontrollerini kullan.',
                ),
                _buildBenefitCard(
                  Icons.repeat_rounded,
                  'Kişisel zikir sayaçları',
                  'Ücretsiz planda 3 özel sayaç; Huzur Özel ile sınırsız özel zikir sayacı.',
                ),
                const SizedBox(height: 18),
                const Text(
                  'HUZUR’DA HERKES İÇİN ÜCRETSİZ',
                  style: TextStyle(
                    color: Color(0xFF8EDFCB),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                _buildBenefitCard(
                  Icons.auto_stories_rounded,
                  'Huzur Story Stüdyosu',
                  'Ayet ve manevi içeriklerini 9:16 hikâye tasarımıyla hazırla, kaydet ve paylaş.',
                ),
                _buildBenefitCard(
                  Icons.widgets_rounded,
                  'Kilit ekranı ayet widget’ı',
                  'Saatlik ayeti veya seçtiğin ayeti kilit ekranında takip et.',
                ),
                _buildBenefitCard(
                  Icons.spa_rounded,
                  '99 Esmaül Hüsna rehberi',
                  'Esmaül Hüsna içeriklerini tek bir sakin ve düzenli deneyimde keşfet.',
                ),
                const SizedBox(height: 18),
                const Text(
                  'SANA UYGUN PLANI SEÇ',
                  style: TextStyle(
                    color: Color(0xFFFFD77A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPlanCard(
                  id: 'monthly',
                  title: 'Aylık Huzur Özel',
                  price: offer.monthlyPrice,
                  subtitle: 'Aylık yenilenir • Dilediğinde yönet',
                  badge: null,
                ),
                const SizedBox(height: 9),
                _buildPlanCard(
                  id: 'annual',
                  title: 'Yıllık Huzur Özel',
                  price: offer.annualPrice,
                  subtitle: '${offer.annualMonthlyEquivalent} • Yıllık abonelik',
                  badge: 'ÖNERİLEN PLAN',
                ),
                const SizedBox(height: 9),
                _buildPlanCard(
                  id: 'lifetime',
                  title: 'Ömür Boyu Tam Erişim',
                  price: offer.lifetimePrice,
                  subtitle: 'Tek seferlik ödeme • Süresiz erişim',
                  badge: 'TEK SEFERLİK',
                ),
                const SizedBox(height: 14),
                if (premium.statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      premium.statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFD77A),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (premium.isPremium)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Apple hesabında etkin plan: $activePlanName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF70DDB9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                GlassContainer(
                  goldAccentBorder: true,
                  emeraldGlow: true,
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onTap: premium.isLoading
                      ? null
                      : () async {
                          if (!selectedPlanAlreadyActive) {
                            await notifier.activatePlan(_selectedTier);
                          }
                        },
                  child: Center(
                    child: premium.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFE082),
                            ),
                          )
                        : Text(
                            premium.isPremium
                                ? (selectedPlanAlreadyActive
                                    ? 'Bu plan hesabında etkin'
                                    : 'Planı değiştir')
                                : 'Huzur Özel’e Geç',
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 9),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: premium.isLoading ? null : () => notifier.restorePurchases(),
                  child: const Center(
                    child: Text(
                      'Satın Alımları Geri Yükle',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        borderRadius: 14,
                        emeraldGlow: true,
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                        onTap: () => _showLegalModal(context, isPrivacy: true),
                        child: const Center(
                          child: Text(
                            'Gizlilik Politikası',
                            style: TextStyle(color: Color(0xFFFFD77A), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: GlassContainer(
                        borderRadius: 14,
                        goldAccentBorder: true,
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                        onTap: () => _showLegalModal(context, isPrivacy: false),
                        child: const Center(
                          child: Text(
                            'Kullanım Koşulları',
                            style: TextStyle(color: Color(0xFFFFE082), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '114 sure Kur’an okuma, ezan vakitleri ve kıble araçları ücretsizdir. Aylık ve yıllık planlar App Store üzerinden otomatik yenilenebilir; ömür boyu plan tek seferliktir. Fiyat, ödeme onayından önce App Store’da gösterilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 10.5, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFE082), size: 13),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A29).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD77A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFFD77A), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(color: Colors.white60, fontSize: 10.8, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF64D6B3), size: 17),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    required String? badge,
  }) {
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
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE082).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFE082),
                  width: 0.8,
                ),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFE082),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA21A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalModal(
    BuildContext context, {
    required bool isPrivacy,
  }) {
    final url = isPrivacy ? _privacyUrl : _eulaUrl;

    final title = isPrivacy
        ? "Gizlilik Politikası (Privacy Policy)"
        : "Kullanım Koşulları ve Lisans (EULA)";

    final body = isPrivacy
        ? "1. HESAP VE CİHAZ VERİLERİ\nHuzur'un temel özellikleri hesap açmadan kullanılabilir. Apple ile giriş, AI ve topluluk işlemleri için kullanılır. Favoriler ve bazı sayaçlar cihazda saklanır.\n\n2. DÜNYA VE DUA TOPLULUĞU\nDua metinleri ve ülke kodu Huzur sunucusunda işlenir; dualar en fazla 24 saat akışta gösterilir ve güvenlik incelemesi için ek süre tutulabilir. Giriş yapan kullanıcının zikir sayısı, gün ve ülke kodu dünya toplamlarını oluşturmak için sunucuyla eşitlenebilir. Kesin GPS koordinatları Huzur API'sine gönderilmez.\n\n3. AI VE SEÇİLEN GÖRSELLER\nAyrı açık izin verirsen soru metnin, seçtiğin görsel ve gerekli sohbet bağlamı Firebase AI Logic üzerinden yapılandırılmış Google AI sağlayıcısına iletilir. AI iznini Profilim bölümünden geri çekebilirsin.\n\n4. HESAP SİLME\nProfilim > Hesabımı sil işlemi geliştiricinin kontrolündeki hesaba bağlı kayıtların silinmesini başlatır. Apple satın alma doğrulama kayıtlarının sınırlı bir bölümü takma kimlikle saklanabilir; ülke bazlı toplulaştırılmış toplamlar korunabilir.\n\nİletişim: huzurapp@outlook.com"
        : "1. ÜCRETSİZ ÖZELLİKLER VE HUZUR ÖZEL\nÜcretsiz ve Premium özelliklerin kapsamı uygulama içindeki güncel ürün açıklamalarında gösterilir. Aylık ve yıllık planlar otomatik yenilenir; Ömür Boyu erişim tek seferlik satın alımdır.\n\n2. TOPLULUK GÜVENLİĞİ\nDua Bırak içerikleri diğer kullanıcılara gösterilebilir. Uygunsuz içerikleri şikâyet edebilir, kullanıcıları engelleyebilir ve kendi duanı silebilirsin.\n\nAboneliklerini Ayarlar > Apple Kimliği > Abonelikler bölümünden yönetebilirsin. Ayrıntılar için resmî Kullanım Koşullarını aç.\n\nİletişim: huzurapp@outlook.com";

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
                BespokeVectorIcon(
                  type: isPrivacy
                      ? BespokeIconType.lockShield
                      : BespokeIconType.sacredScroll,
                  color: isPrivacy
                      ? const Color(0xFFFFA21A)
                      : const Color(0xFFFFE082),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              borderRadius: 14,
              emeraldGlow: true,
              padding: const EdgeInsets.symmetric(vertical: 11),
              onTap: () => _openOfficialUrl(url),
              child: const Center(
                child: Text(
                  "Resmi Web Belgesini Safari'de Aç",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFFFFA21A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(vertical: 10),
              onTap: () => Navigator.pop(ctx),
              child: const Center(
                child: Text(
                  "Kapat",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ÖZEL SVG / VEKTÖR ÇİZİMLERİ ( PARLAYAN YILDIZ &  HİLAL AMBLEMİ)
// ============================================================

class HuzurGlowingStarSvg extends StatelessWidget {
  final double size;
  const HuzurGlowingStarSvg({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlowingStarSvgPainter(),
      ),
    );
  }
}

class _GlowingStarSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.48;
    final innerRadius = size.width * 0.19;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, outerRadius * 0.75, glowPaint);

    final path = Path();
    const int points = 5;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / points) - (pi / 2);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFCA28), Color(0xFFFFB300)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    final borderPaint = Paint()
      ..color = const Color(0xFFFFA21A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      Offset(center.dx - outerRadius * 0.15, center.dy - outerRadius * 0.15),
      size.width * 0.06,
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HuzurCrescentEmblemSvg extends StatelessWidget {
  final double size;
  const HuzurCrescentEmblemSvg({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrescentEmblemPainter(),
      ),
    );
  }
}

class _CrescentEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFA21A).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, r, glowPaint);

    final outerCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: r));
    final innerCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx + r * 0.34, center.dy - r * 0.12),
          radius: r * 0.82,
        ),
      );

    final crescentPath =
        Path.combine(PathOperation.difference, outerCircle, innerCircle);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFA21A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawPath(crescentPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HuzurDeveloperSvgBadge extends StatelessWidget {
  final double fontSize;
  const HuzurDeveloperSvgBadge({super.key, this.fontSize = 11.5});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HuzurCrescentEmblemSvg(size: 16),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Huzur Ekibi',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFFFE082),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const HuzurGlowingStarSvg(size: 15),
      ],
    );
  }
}

// ============================================================
// HUZUR UYGULAMA İÇİ CANLI DESTEK BUTONU

// HUZUR DEVELOPER STORY - TETİKLEYİCİ BUTON
// ============================================================

class HuzurDeveloperStoryButton extends StatelessWidget {
  const HuzurDeveloperStoryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      emeraldGlow: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      onTap: () => showHuzurDeveloperStoryModal(context),
      child: const Row(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            color: Color(0xFFFFA21A),
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Huzur’un Hikâyesi & Vizyonu',
                  style: TextStyle(
                    color: Color(0xFFFFA21A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Huzur’un ardındaki emeği ve fikri keşfet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFFFFA21A),
            size: 15,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HUZUR DEVELOPER STORY - LIQUID GLASS MODAL
// ============================================================

Future<void> showHuzurDeveloperStoryModal(
  BuildContext context,
) async {
  HapticFeedback.selectionClick();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.90,
        minChildSize: 0.58,
        maxChildSize: 0.96,
        builder: (sheetContext, scrollController) {
          return GlassContainer(
            borderRadius: 32,
            enableBlur: true,
            blurSigma: 26,
            goldAccentBorder: true,
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              18,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      HuzurCrescentEmblemSvg(size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Huzur’un Hikâyesi & Vizyonu',
                          style: TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      HuzurGlowingStarSvg(size: 18),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bir fikrin ardındaki emek, inanç ve yolculuk',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 5,
                        bottom: 14,
                      ),
                      children: [
                        Text.rich(
                          _huzurDeveloperStoryText(),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 22),
                        const SizedBox(height: 10),
                        GlassContainer(
                          borderRadius: 16,
                          emeraldGlow: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Center(
                            child: Text(
                              'Kapat',
                              style: TextStyle(
                                color: Color(0xFFFFA21A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================
// HUZUR DEVELOPER STORY - RENKLİ TEXTSPAN GÖVDESİ
// ============================================================

TextSpan _huzurDeveloperStoryText() {
  const base = TextStyle(
    color: Color(0xFFE8EAF0),
    fontSize: 13.2,
    height: 1.72,
    letterSpacing: 0.08,
  );

  const emerald = TextStyle(
    color: Color(0xFFFFA21A),
    fontWeight: FontWeight.w700,
  );

  const signature = TextStyle(
    color: Color(0xFFFFE082),
    fontSize: 14,
    height: 1.7,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.15,
  );

  return const TextSpan(
    style: base,
    children: [
      TextSpan(
        text:
            'Huzur, günün yoğunluğu içinde insanın kendisine zaman ayırabilmesi, sakinleşebilmesi ve tefekkür edebilmesi için tasarlanmış bir dijital yol arkadaşıdır. Amacımız, manevi içerikleri ve günlük kullanım araçlarını sade bir deneyimde bir araya getirmektir.',
      ),
      TextSpan(text: '\n\n'),
      TextSpan(
        text: 'Huzur deneyiminin merkezinde ',
      ),
      TextSpan(
        text: 'sadelik, mahremiyet ve huzurlu kullanım',
        style: emerald,
      ),
      TextSpan(
        text:
            ' bulunur. Reklamlarla bölünmeyen, gereksiz karmaşadan uzak ve kullanıcıya kontrol veren bir uygulama deneyimi sunmayı hedefliyoruz.',
      ),
      TextSpan(text: '\n\n'),
      TextSpan(
        text:
            'Kur’ân-ı Kerîm içerikleri, sesli tilavet, ezan vakitleri, kıble araçları, zikir deneyimi, manevi içerikler ve kişiselleştirilebilir ses ortamları aynı çatı altında buluşur. Kilit ekranı araçları ve paylaşım özellikleri de bu deneyimi günlük yaşama taşımak için geliştirilir.',
      ),
      TextSpan(text: '\n\n'),
      TextSpan(
        text:
            'Her ayrıntıda okunabilirliği, erişilebilirliği ve tutarlı bir tasarımı önemseriz. Huzur’u geliştirmeye devam ederken amacımız, teknolojinin dikkat dağıtan yönlerini azaltıp faydalı içeriklere daha sakin bir alan açmaktır.',
      ),
      TextSpan(text: '\n\n'),
      TextSpan(
        text:
            'Huzur’a gösterdiğiniz ilgi ve verdiğiniz destek için teşekkür ederiz. Bu yolculuğun bir parçası olduğunuz için mutluyuz.',
      ),
      TextSpan(text: '\n\n'),
      TextSpan(
        text: 'Huzur Ekibi',
        style: signature,
      ),
    ],
  );
}
