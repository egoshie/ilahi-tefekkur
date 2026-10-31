import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  int _founderTapCount = 0;

  Future<void> _openOfficialUrl(String url) async {
    HapticFeedback.selectionClick();
    try {
      await _nativeChannel.invokeMethod(
        'openExternalUrl',
        {'url': url},
      );
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
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          child: ListView(
            controller: scrollController,
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
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
                    child: const BespokeVectorIcon(
                      type: BespokeIconType.crownGem,
                      color: Color(0xFFFFE082),
                      size: 26,
                    ),
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 14),

              const HuzurDeveloperStoryButton(),

              const SizedBox(height: 10),

              const HuzurLiveSupportButton(),

              const SizedBox(height: 18),

              _buildFeatureRow(
                "Tevrat (39 Kitap) ve İncil (27 Kitap) Canlı Türkçe Külliyat",
              ),
              _buildFeatureRow(
                "15 Büyük Kıssada 3'lü Karşılaştırmalı İnceleme",
              ),
              _buildFeatureRow(
                "Arka Plan Kur'ân Tilaveti & Dynamic Island Medya",
              ),
              _buildFeatureRow(
                "Kilit Ekranı Saatlik Ayet Widget'ı & Hikâye Stüdyosu",
              ),
              _buildFeatureRow(
                "Sınırsız Zikirmatik & 99 Esmaül Hüsna Rehberi",
              ),

              const SizedBox(height: 18),

              _buildPlanCard(
                id: 'monthly',
                title: "Aylık Plan",
                price: offer.monthlyPrice,
                subtitle: "Esnek aylık abonelik",
                badge: null,
              ),

              const SizedBox(height: 12),

              _buildPlanCard(
                id: 'annual',
                title: "Yıllık Huzur Planı",
                price: offer.annualPrice,
                subtitle:
                    "${offer.annualMonthlyEquivalent} • Yıllık Abonelik",
                badge: "EN ÇOK TERCİH EDİLEN",
              ),

              const SizedBox(height: 12),

              _buildPlanCard(
                id: 'lifetime',
                title: "Ömür Boyu Tam Erişim",
                price: offer.lifetimePrice,
                subtitle: "Tek seferlik ödeme • Süresiz kullanım",
                badge: "SINIRSIZ ERİŞİM",
              ),

              const SizedBox(height: 16),

              if (premium.statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    premium.statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ),

              GlassContainer(
                goldAccentBorder: true,
                emeraldGlow: true,
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(vertical: 15),
                onTap: () async {
                  await notifier.activatePlan(_selectedTier);
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
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BespokeVectorIcon(
                              type: BespokeIconType.checkBadge,
                              color: Color(0xFF64FFDA),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              premium.isPremium
                                  ? "Huzur Özel Etkin"
                                  : "App Store ile Güvenle Abone Ol",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFE082),
                              ),
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
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      onTap: () => _showLegalModal(
                        context,
                        isPrivacy: true,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.lockShield,
                            color: Color(0xFF64FFDA),
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              "Gizlilik Politikası",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64FFDA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      onTap: () => _showLegalModal(
                        context,
                        isPrivacy: false,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.sacredScroll,
                            color: Color(0xFFFFE082),
                            size: 16,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              "Kullanım Koşulları (EULA)",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFE082),
                              ),
                            ),
                          ),
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
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
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
          const BespokeVectorIcon(
            type: BespokeIconType.checkBadge,
            color: Color(0xFF64FFDA),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
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
                  color: Color(0xFF64FFDA),
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
        ? "1. CİHAZ İÇİ ÖNCELİKLİ MİMARİ VE VERİ KORUMA\nHuzur uygulaması kullanıcılarından hesap oluşturmasını talep etmez. Hiçbir reklam ağı ve takip kodu (Zero Tracking) barındırmaz.\n\n2. KONUM VE GALERİ İZİNLERİ\n• Konum İzni: Yalnızca bulunduğunuz şehrin astronomik ezan vakitlerini ve Kıble açısını cihaz içinde hesaplamak için kullanılır.\n• Fotoğraflar İzni: Yalnızca Paylaşım Stüdyosunda oluşturduğunuz ayet kartlarını galeriye kaydetmek için kullanılır.\n\nGeliştirici: Ege Deniz • berkwisy@gmail.com"
        : "1. LİSANS KAPSAMI VE ABONELİK KURALLARI\n114 Sure Kur'ân-ı Kerîm, sesli tilavet, ezan vakitleri ve kıble pusulası ücretsizdir. Huzur Özel (Aylık ve Yıllık) abonelikleri, dönem bitiminden en az 24 saat önce iptal edilmediği sürece Apple ID hesabınız üzerinden otomatik yenilenir. Ayarlar > Apple Kimliği > Abonelikler menüsünden dilediğiniz an iptal edebilirsiniz.\n\nGeliştirici: Ege Deniz • berkwisy@gmail.com";

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
                      ? const Color(0xFF64FFDA)
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
                    color: Color(0xFF64FFDA),
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
// ÖZEL SVG / VEKTÖR ÇİZİMLERİ (🌟 PARLAYAN YILDIZ & 🌙 HİLAL AMBLEMİ)
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
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.85)
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
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.25)
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
        colors: [Color(0xFFFFE082), Color(0xFF64FFDA)],
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
            'Ege Deniz • Geliştirici',
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
// ============================================================

class HuzurLiveSupportButton extends StatelessWidget {
  const HuzurLiveSupportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      goldAccentBorder: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      onTap: () => showHuzurInAppLiveChatModal(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE082).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFE082).withValues(alpha: 0.65),
              ),
            ),
            child: const Center(
              child: HuzurCrescentEmblemSvg(size: 22),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HuzurDeveloperSvgBadge(fontSize: 13),
                SizedBox(height: 3),
                Text(
                  'Huzur Rehberi & Canlı Geliştirici Hattı',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFF64FFDA),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HUZUR %100 UYGULAMA İÇİ CANLI DESTEK, CANLI YAZIYOR İZLEME VE PUANLAMA
// ============================================================

class _HuzurChatMessage {
  final String id;
  final String text;
  final bool isFromDeveloper;
  final String timeLabel;
  final bool showConnectDeveloperButton;

  const _HuzurChatMessage({
    required this.id,
    required this.text,
    required this.isFromDeveloper,
    required this.timeLabel,
    this.showConnectDeveloperButton = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isFromDeveloper': isFromDeveloper,
        'timeLabel': timeLabel,
        'showConnectDeveloperButton': showConnectDeveloperButton,
      };

  factory _HuzurChatMessage.fromJson(Map<String, dynamic> map) {
    return _HuzurChatMessage(
      id: (map['id'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      isFromDeveloper: map['isFromDeveloper'] == true,
      timeLabel: (map['timeLabel'] ?? '').toString(),
      showConnectDeveloperButton: map['showConnectDeveloperButton'] == true,
    );
  }
}

Future<void> showHuzurInAppLiveChatModal(BuildContext context) async {
  HapticFeedback.selectionClick();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => const _HuzurInAppLiveChatSheet(),
  );
}

class _HuzurInAppLiveChatSheet extends StatefulWidget {
  const _HuzurInAppLiveChatSheet();

  @override
  State<_HuzurInAppLiveChatSheet> createState() =>
      _HuzurInAppLiveChatSheetState();
}

class _HuzurInAppLiveChatSheetState extends State<_HuzurInAppLiveChatSheet> {
  // Doğrudan Gömülü Telegram & MTProto Yapılandırması
  static const int _tgApiId = 26366323;
  static const String _tgApiHash = '6d6b7e4cb59b61604f817d843727ff83';
  static const String _botToken =
      '9294606406:AAEPkXrViV0uK3rcW8m6CQjS9C9YAN_WNcc';
  static const String _developerChatId = '8147114161';

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _sessionTag = 'HZR-0000';
  bool _isLiveDeveloperMode = false;
  bool _isRatingMode = false;
  int _selectedStars = 5;
  bool _isSending = false;

  int? _liveTypingTelegramMsgId;
  String _lastSentTypingDraft = '';
  Timer? _typingDebounce;
  Timer? _pollTimer;
  int _lastProcessedUpdateId = 0;

  final List<_HuzurChatMessage> _messages = [];

  File get _storageFile =>
      File('${Directory.systemTemp.path}/huzur_inapp_live_chat_v2.json');

  @override
  void initState() {
    super.initState();
    assert(_tgApiId > 0 && _tgApiHash.isNotEmpty);
    _loadLocalSession();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollDeveloperReplies(),
    );
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _nowTimeLabel() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _generateFreshTag() {
    final rnd = Random();
    final code = (100000 + rnd.nextInt(899999)).toString();
    return 'HZR-$code';
  }

  Future<void> _loadLocalSession() async {
    try {
      if (await _storageFile.exists()) {
        final raw = await _storageFile.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final savedTag = (data['sessionTag'] ?? '').toString();
        final savedLive = data['isLiveDeveloperMode'] == true;
        final savedLastUpdate = (data['lastProcessedUpdateId'] as int?) ?? 0;
        final list = (data['messages'] as List<dynamic>? ?? [])
            .map((e) => _HuzurChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        if (savedTag.isNotEmpty && list.isNotEmpty) {
          setState(() {
            _sessionTag = savedTag;
            _isLiveDeveloperMode = savedLive;
            _lastProcessedUpdateId = savedLastUpdate;
            _messages
              ..clear()
              ..addAll(list);
          });
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {}

    await _resetToWelcomeState();
  }

  Future<void> _resetToWelcomeState() async {
    setState(() {
      _sessionTag = _generateFreshTag();
      _isLiveDeveloperMode = false;
      _liveTypingTelegramMsgId = null;
      _lastSentTypingDraft = '';
      _messages
        ..clear()
        ..add(
          _HuzurChatMessage(
            id: 'welcome_init',
            text:
                'Selamün aleyküm, Huzur Rehberi ve Canlı Destek merkezine hoş geldiniz.\n\nAşağıdaki butonlardan Huzur’un felsefesini ve sunduğu külliyatı detaylıca inceleyebilir veya doğrudan geliştirici Ege Deniz ile canlı sohbete bağlanabilirsiniz.',
            isFromDeveloper: true,
            timeLabel: _nowTimeLabel(),
          ),
        );
    });
    await _saveLocalSession();
  }

  Future<void> _saveLocalSession() async {
    try {
      final payload = jsonEncode({
        'sessionTag': _sessionTag,
        'isLiveDeveloperMode': _isLiveDeveloperMode,
        'lastProcessedUpdateId': _lastProcessedUpdateId,
        'messages': _messages.map((m) => m.toJson()).toList(),
      });
      await _storageFile.writeAsString(payload);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleFaqSelection(String type) async {
    HapticFeedback.selectionClick();
    final questionText =
        type == 'nedir' ? 'Huzur Nedir?' : 'Bizlere Ne Sunuyor?';

    final answerText = type == 'nedir'
        ? '🌙 HUZUR NEDİR?\n\nHuzur; modern dünyanın gürültüsü, hızı ve veri sömürüsü içinde bunalan ruhlar için 21 yaşındaki bağımsız geliştirici Ege Deniz tarafından, hiçbir bilgisayar kullanmadan yalnızca tek bir iPhone 16 üzerinden gecelerce kodlanarak inşa edilmiş dijital bir tefekkür sığınağıdır.\n\n• Sıfır Reklam & Sıfır Takip (Zero Tracking): Uygulamanın içinde hiçbir reklam ağı, analitik dinleyicisi veya veri takip kodu bulunmaz. İbadetiniz ve tefekkürünüz yalnızca sizinle Rabbi arasındadır.\n• Cihaz İçi (Offline-First) Mimari: Tüm hesaplamalar ve okuma geçmişiniz cihazınızın içinde korunur.\n• Bağımsız Adanmışlık: Arkasında dev şirketler veya yatırımcılar değil; saf bir inanç, alın teri ve samimi bir dua beklentisi vardır.'
        : '🌟 HUZUR BİZLERE NE SUNUYOR?\n\n1. 114 Sure Kur’ân-ı Kerîm & Kesintisiz Tilavet: Sıfır bekleme (Zero-Latency) mimarisiyle arka planda ve Dynamic Island üzerinde çalışan sesli tilavet ve meal külliyatı.\n\n2. Tevrat (39 Kitap) ve İncil (27 Kitap) Canlı Türkçe Külliyat: İlahi metinleri karşılaştırmalı olarak inceleyebileceğiniz eksiksiz Türkçe kaynak kütüphanesi.\n\n3. 15 Büyük Kıssada 3’lü Karşılaştırmalı Tefekkür: Peygamber kıssalarının Kur’ân, Tevrat ve İncil’deki anlatımlarını yan yana, derinlikli olarak inceleme imkânı.\n\n4. Kilit Ekranı Saatlik Ayet Widget’ı & Hikâye Stüdyosu: Uzun ayetleri ruhu yormadan bölen akıllı algoritma ve Likit Cam tasarımlı paylaşım kartları.\n\n5. Sınırsız Akışkan Zikirmatik, 99 Esmaül Hüsna, Astronomik Ezan Vakitleri ve Hassas Kıble Pusulası.';

    setState(() {
      _messages.add(
        _HuzurChatMessage(
          id: 'faq_q_${DateTime.now().millisecondsSinceEpoch}',
          text: questionText,
          isFromDeveloper: false,
          timeLabel: _nowTimeLabel(),
        ),
      );
      _messages.add(
        _HuzurChatMessage(
          id: 'faq_a_${DateTime.now().millisecondsSinceEpoch}',
          text: answerText,
          isFromDeveloper: true,
          timeLabel: _nowTimeLabel(),
          showConnectDeveloperButton: true,
        ),
      );
    });
    await _saveLocalSession();
    _scrollToBottom();
  }

  Future<void> _activateLiveDeveloperChat() async {
    if (_isLiveDeveloperMode) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isLiveDeveloperMode = true;
      _messages.add(
        _HuzurChatMessage(
          id: 'live_connected_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Canlı geliştirici hattına bağlandınız. Şu andan itibaren yazdığınız her harf anlık olarak geliştirici Ege Deniz’in ekranına düşmektedir. Buyurun, doğrudan yazabilirsiniz.',
          isFromDeveloper: true,
          timeLabel: _nowTimeLabel(),
        ),
      );
    });
    await _saveLocalSession();
    _scrollToBottom();

    await _tgPost('sendMessage', {
      'chat_id': _developerChatId,
      'text':
          '🌙 Yeni Canlı Sohbet Başladı [#$_sessionTag]\n👤 Kullanıcı "Geliştirici ile Sohbet Et" butonuna bastı ve canlı hatta bağlandı.\n\n🔚 Sohbeti bitirip kullanıcıya puanlama ekranı göndermek için /sohbetikapa yazabilirsiniz.',
    });
  }

  // Kullanıcının yazdığı metni daha göndermeden Telegram'da canlı gösterme
  void _onUserTypingChanged(String value) {
    if (!_isLiveDeveloperMode || _isRatingMode) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 650), () {
      _syncLiveTypingPreviewToTelegram(value.trim());
    });
  }

  Future<void> _syncLiveTypingPreviewToTelegram(String draft) async {
    if (draft.isEmpty || draft == _lastSentTypingDraft) return;
    _lastSentTypingDraft = draft;

    final previewText =
        '✍️ [#$_sessionTag] Kullanıcı şu an yazıyor:\n"$draft..."';

    if (_liveTypingTelegramMsgId == null) {
      final res = await _tgPost('sendMessage', {
        'chat_id': _developerChatId,
        'text': previewText,
      });
      final msgId = res?['result']?['message_id'] as int?;
      if (msgId != null) {
        _liveTypingTelegramMsgId = msgId;
      }
    } else {
      await _tgPost('editMessageText', {
        'chat_id': _developerChatId,
        'message_id': _liveTypingTelegramMsgId,
        'text': previewText,
      });
    }
  }

  Future?> _tgPost(
    String method,
    Map<String, dynamic> payload,
  ) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://api.telegram.org/bot$_botToken/$method',
      );
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(jsonEncode(payload)));
      final resp = await req.close();
      final raw = await resp.transform(utf8.decoder).join();
      client.close();
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    if (!_isLiveDeveloperMode) {
      await _activateLiveDeveloperChat();
    }

    HapticFeedback.lightImpact();
    _typingDebounce?.cancel();
    if (presetText == null) {
      _inputController.clear();
    }

    final userMsg = _HuzurChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromDeveloper: false,
      timeLabel: _nowTimeLabel(),
    );

    setState(() {
      _isSending = true;
      _messages.add(userMsg);
    });
    await _saveLocalSession();
    _scrollToBottom();

    final finalTelegramText =
        '📩 Huzur Canlı Destek [#$_sessionTag]\n\n💬 $text\n\n↩️ Yanıtlamak için bu mesajı kaydırın (Reply) veya sohbeti bitirip puanlatmak için /sohbetikapa yazın.';

    if (_liveTypingTelegramMsgId != null) {
      await _tgPost('editMessageText', {
        'chat_id': _developerChatId,
        'message_id': _liveTypingTelegramMsgId,
        'text': finalTelegramText,
      });
      _liveTypingTelegramMsgId = null;
      _lastSentTypingDraft = '';
    } else {
      await _tgPost('sendMessage', {
        'chat_id': _developerChatId,
        'text': finalTelegramText,
      });
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pollDeveloperReplies() async {
    if (!mounted || _isRatingMode) return;
    try {
      final client = HttpClient();
      final offsetParam = _lastProcessedUpdateId > 0
          ? 'offset=${_lastProcessedUpdateId + 1}&limit=30'
          : 'offset=-25&limit=25';
      final uri = Uri.parse(
        'https://api.telegram.org/bot$_botToken/getUpdates?$offsetParam',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final raw = await resp.transform(utf8.decoder).join();
      client.close();

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['ok'] != true) return;

      final results = decoded['result'] as List<dynamic>? ?? [];
      bool addedNew = false;
      bool shouldCloseChat = false;

      for (final item in results) {
        final update = item as Map<String, dynamic>;
        final rawUpdateId = (update['update_id'] as int?) ?? 0;

        if (_lastProcessedUpdateId == 0) {
          // İlk açılışta geçmiş update ID'lerini baz al
          if (rawUpdateId > _lastProcessedUpdateId) {
            _lastProcessedUpdateId = rawUpdateId;
          }
          continue;
        }

        if (rawUpdateId > _lastProcessedUpdateId) {
          _lastProcessedUpdateId = rawUpdateId;
        }

        final updateKey = 'tg_$rawUpdateId';
        if (_messages.any((m) => m.id == updateKey)) continue;

        final msg = update['message'] as Map<String, dynamic>?;
        if (msg == null) continue;

        final fromId = (msg['chat']?['id'] ?? '').toString();
        if (fromId != _developerChatId) continue;

        final replyText = (msg['text'] ?? '').toString().trim();
        if (replyText.isEmpty) continue;

        final replyTo = msg['reply_to_message'] as Map<String, dynamic>?;
        final originalText = (replyTo?['text'] ?? '').toString();

        final isGlobalClose = replyText.startsWith('/sohbetikapa');
        final matchesSession = originalText.contains('[#$_sessionTag]') ||
            replyText.contains('#$_sessionTag') ||
            (_isLiveDeveloperMode && replyTo == null);

        if (isGlobalClose &&
            (matchesSession || _isLiveDeveloperMode)) {
          shouldCloseChat = true;
          break;
        }

        if (matchesSession && !isGlobalClose) {
          final cleaned =
              replyText.replaceAll('#$_sessionTag', '').trim();
          _messages.add(
            _HuzurChatMessage(
              id: updateKey,
              text: cleaned,
              isFromDeveloper: true,
              timeLabel: _nowTimeLabel(),
            ),
          );
          addedNew = true;
        }
      }

      if (shouldCloseChat && mounted) {
        await _triggerChatCloseAndRating();
        return;
      }

      if (addedNew && mounted) {
        HapticFeedback.mediumImpact();
        setState(() {});
        await _saveLocalSession();
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _triggerChatCloseAndRating() async {
    HapticFeedback.heavyImpact();
    try {
      if (await _storageFile.exists()) {
        await _storageFile.delete();
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _messages.clear();
      _isLiveDeveloperMode = false;
      _isRatingMode = true;
      _selectedStars = 5;
    });
  }

  Future<void> _submitRatingAndClose() async {
    HapticFeedback.mediumImpact();
    final starsVisual = '🌟' * _selectedStars;
    await _tgPost('sendMessage', {
      'chat_id': _developerChatId,
      'text':
          '🏆 Sohbet Değerlendirmesi [#$_sessionTag]\nPuan: $_selectedStars / 5 $starsVisual\nSohbet sıfırlandı ve kapatıldı.',
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.90,
        minChildSize: 0.58,
        maxChildSize: 0.96,
        builder: (context, _) {
          return GlassContainer(
            borderRadius: 32,
            enableBlur: true,
            blurSigma: 26,
            goldAccentBorder: true,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: SafeArea(
              top: false,
              child: _isRatingMode
                  ? _buildRatingView()
                  : _buildChatConversationView(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const HuzurCrescentEmblemSvg(size: 54),
        const SizedBox(height: 16),
        const HuzurDeveloperSvgBadge(fontSize: 16),
        const SizedBox(height: 10),
        const Text(
          'Sohbet Tamamlandı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Geliştirici Ege Deniz ile gerçekleştirdiğiniz canlı destek görüşmesini nasıl değerlendirirsiniz?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= _selectedStars;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedStars = starValue);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedScale(
                  scale: isSelected ? 1.18 : 0.92,
                  duration: const Duration(milliseconds: 180),
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.32,
                    child: const HuzurGlowingStarSvg(size: 36),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Text(
          '$_selectedStars / 5 Yıldız',
          style: const TextStyle(
            color: Color(0xFFFFE082),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 26),
        GlassContainer(
          borderRadius: 20,
          goldAccentBorder: true,
          emeraldGlow: true,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          onTap: _submitRatingAndClose,
          child: const Center(
            child: Text(
              'Puanı Gönder ve Sohbeti Kapat',
              style: TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatConversationView() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Üst Başlık: Hilal Amblemi + Ege Deniz • Geliştirici + 🌟 SVG
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE082).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFE082),
                  width: 1.1,
                ),
              ),
              child: const Center(
                child: HuzurCrescentEmblemSvg(size: 24),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HuzurDeveloperSvgBadge(fontSize: 14.5),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isLiveDeveloperMode
                              ? const Color(0xFF64FFDA)
                              : const Color(0xFFFFE082),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _isLiveDeveloperMode
                              ? 'Canlı Sohbet Aktif • #$_sessionTag'
                              : 'Huzur Rehberi & Canlı Destek',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // İlk Girişte "Huzur Nedir?" ve "Bizlere Ne Sunuyor?" Tuşları
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: 16,
                emeraldGlow: true,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                onTap: () => _handleFaqSelection('nedir'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HuzurCrescentEmblemSvg(size: 15),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Huzur Nedir?',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF64FFDA),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassContainer(
                borderRadius: 16,
                goldAccentBorder: true,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                onTap: () => _handleFaqSelection('sunuyor'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HuzurGlowingStarSvg(size: 15),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Bizlere Ne Sunuyor?',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildChatBubble(msg);
            },
          ),
        ),

        const SizedBox(height: 10),

        if (!_isLiveDeveloperMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              borderRadius: 18,
              goldAccentBorder: true,
              emeraldGlow: true,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              onTap: _activateLiveDeveloperChat,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HuzurCrescentEmblemSvg(size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Geliştirici ile Sohbet Etmek İster misin?',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  HuzurGlowingStarSvg(size: 16),
                ],
              ),
            ),
          ),

        Row(
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _inputController,
                  onChanged: _onUserTypingChanged,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                  ),
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: _isLiveDeveloperMode
                        ? 'Ege Deniz’e mesajınızı yazın...'
                        : 'Doğrudan geliştiriciye yazmak için dokunun...',
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.8,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GlassContainer(
              borderRadius: 22,
              emeraldGlow: true,
              goldAccentBorder: true,
              padding: const EdgeInsets.all(12),
              onTap: _sendMessage,
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFF64FFDA),
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatBubble(_HuzurChatMessage msg) {
    final isDev = msg.isFromDeveloper;
    return Align(
      alignment: isDev ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDev
              ? const Color(0xFFFFE082).withValues(alpha: 0.10)
              : const Color(0xFF64FFDA).withValues(alpha: 0.14),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isDev ? 4 : 18),
            bottomRight: Radius.circular(isDev ? 18 : 4),
          ),
          border: Border.all(
            color: isDev
                ? const Color(0xFFFFE082).withValues(alpha: 0.55)
                : const Color(0xFF64FFDA).withValues(alpha: 0.65),
            width: 0.9,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isDev ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isDev)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: HuzurDeveloperSvgBadge(fontSize: 11.5),
              ),
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.2,
                height: 1.5,
              ),
            ),
            if (msg.showConnectDeveloperButton && !_isLiveDeveloperMode) ...[
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: 14,
                goldAccentBorder: true,
                emeraldGlow: true,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                onTap: _activateLiveDeveloperChat,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HuzurCrescentEmblemSvg(size: 16),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Geliştirici ile Sohbet Etmek İster misin?',
                        style: TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    HuzurGlowingStarSvg(size: 14),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              isDev ? msg.timeLabel : '${msg.timeLabel} • ✓✓',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
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
            color: Color(0xFF64FFDA),
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geliştirici Hikâyesi & Vizyon',
                  style: TextStyle(
                    color: Color(0xFF64FFDA),
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
            color: Color(0xFF64FFDA),
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
                          'Geliştirici Hikâyesi & Vizyon',
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

                        GlassContainer(
                          borderRadius: 16,
                          goldAccentBorder: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            showHuzurInAppLiveChatModal(context);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HuzurCrescentEmblemSvg(size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Ege Deniz ile Canlı Sohbete Bağlan',
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 6),
                              HuzurGlowingStarSvg(size: 16),
                            ],
                          ),
                        ),

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
                                color: Color(0xFF64FFDA),
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
    color: Color(0xFF64FFDA),
    fontWeight: FontWeight.w700,
  );

  const gold = TextStyle(
    color: Color(0xFFFFE082),
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
        text: 'Her şey, modern dünyanın getirdiği o amansız hızın, karmaşanın ve samimiyetsizliğin içinde kalbimin sıkışmasıyla başladı. Ben de sizler gibi, henüz yolun başında, ',
      ),
      TextSpan(
        text: '21 yaşında bağımsız bir yazılımcıyım.',
        style: emerald,
      ),
      TextSpan(
        text: ' Arkamda devasa bütçeleri olan şirketler, reklam ajansları ya da bana sermaye veren yatırımcılar yok. En önemlisi, benim bir bilgisayarım bile yok! Sadece elimdeki tek bir telefonla, ',
      ),
      TextSpan(
        text: 'iPhone 16\'mla',
        style: gold,
      ),
      TextSpan(
        text: ' gecelerce terminale bağlanarak, uykumu feda ederek bu kod satırlarını tek tek işledim. Bu uygulamanın adını bu yüzden ',
      ),
      TextSpan(
        text: '"Huzur"',
        style: gold,
      ),
      TextSpan(
        text: ' koydum. İstedim ki bir insan telefonunun ekranını açtığında, karşısında sadece parıldayan pikseller değil; ruhuna dokunan, onu sakinleştiren temiz bir sığınak bulsun.',
      ),

      TextSpan(text: '\n\n'),

      TextSpan(
        text: 'Bugün nereye baksak, hangi uygulamayı indirmeye kalksak her yerinden reklamlar fırlıyor. Kullanıcıların verilerini gizlice toplayıp satan, her saniye karşınıza zorla 30 saniyelik videolar çıkaran, insan ruhunu sadece birer "veri" ve "para" olarak gören koca bir endüstri var. Ben 21 yaşındaki bu genç yaşımda, bu sisteme tek başıma meydan okumak istedim. Huzur’u tasarlarken en büyük yeminim şuydu: ',
      ),
      TextSpan(
        text: 'Bu uygulamada tek bir reklam ağı, tek bir takip kodu (Zero Tracking) olmayacak!',
        style: emerald,
      ),
      TextSpan(
        text: ' İnsanlar buraya tefekkür etmeye, dinlenmeye geldiklerinde arkalarında iz bırakmayacaklar, rahatsız edilmeyecekler. Ben insanların verilerini değil, sadece samimi bir teşekkürlerini ve dualarını almak için yola çıktım.',
      ),

      TextSpan(text: '\n\n'),

      TextSpan(
        text: 'Bu yolculuk benim için hiç kolay olmadı. Yaşıtlarım dışarıda gezip eğlenirken, ben avucumun içindeki o telefon ekranına bakarak sabaha karşı çöken sunucularla ve çözülmeyi bekleyen hata kodlarıyla baş başa kaldım. Kaç kez durup tıkandığımı, "acaba yapamayacak mıyım?" diye kendi kendimi yiyip bitirdiğimi ben bilirim. Apple\'ın o katı ödeme motorunu entegre etmekten, Tevrat ve İncil\'in canlı Türkçe API bağlantılarını hatasız kurmaya kadar her detayı telefonumdan, ilmek ilmek işledim. Sırf kilit ekranında ayetler taşmasın, alt alta temizce süzülsün, uzun cümleler arasında insan ruhu boğulmasın diye günlerce akıllı cümle bölücüler üzerinde çalıştım. Sesler geçiş yaparken kullanıcı uygulamayı kapandı sanmasın diye arka planda sıfır beklemeli ses sistemini kurmak için uykumu feda ettim.',
      ),

      TextSpan(text: '\n\n'),

      TextSpan(
        text: 'Bu uygulama, sadece satırlardan ve algoritmalardan ibaret ticari bir meta değil. Bu proje bağımsız bir geliştiricinin, 21 yaşındaki bir gencin tüm dünyaya ',
      ),
      TextSpan(
        text: '"Bir bilgisayarım olmasa bile, sadece bir telefonla reklamsız ve tertemiz bir dijital dünya inşa edebilirim"',
        style: emerald,
      ),
      TextSpan(
        text: ' deme şeklidir. Arkamda büyük sermayeler olmasa da, bu projede her bir satır kodda saf bir emek, telefon başında dökülen alın teri ve koca bir inanç var.',
      ),

      TextSpan(text: '\n\n'),

      TextSpan(
        text: 'Huzur, bir şirketin kazanç kapısı değil; bağımsız bir tefekkür, bir adanmışlık yolculuğudur. Bu limana sığınan, emeğime saygı duyan ve bu sessiz devrimde yanımda olan her bir kalbe selam olsun...',
      ),

      TextSpan(text: '\n\n'),

      TextSpan(
        text: 'Bağımsız Geliştirici: Ege Deniz (21)',
        style: signature,
      ),
    ],
  );
}
