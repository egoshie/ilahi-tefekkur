import 'package:flutter/material.dart';
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
  String _selectedTier = 'annual';

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
          blurSigma: 38,
          goldAccentBorder: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BespokeVectorIcon(
                    type: BespokeIconType.crownGem,
                    color: Color(0xFFFFB300),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "İlahi Tefekkür • VIP Ekosistem",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFD54F),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Sıfır Reklam • Canlı Tevrat ve İncil API • 15'li Karşılaştırmalı Teoloji",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bölgesel Fiyatlandırma (PPP): ${offer.regionLabel}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRegionChip("TR (TL)", "tr_TR", offer.localeCode == "tr_TR", notifier),
                        const SizedBox(width: 8),
                        _buildRegionChip("US (USD)", "en_US", offer.localeCode == "en_US", notifier),
                        const SizedBox(width: 8),
                        _buildRegionChip("EU (EUR)", "de_DE", offer.localeCode == "de_DE", notifier),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              GlassContainer(
                emeraldGlow: premium.isSandboxUnlocked,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                borderRadius: 18,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sandbox / Test Mode: Unlock Premium",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF00FF87),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "APK testinde ödeme yapmadan tüm VIP modülleri anında açar.",
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: premium.isSandboxUnlocked,
                      activeColor: const Color(0xFF00FF87),
                      onChanged: (val) => notifier.toggleSandboxMode(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _buildFeatureRow("Tevrat / Tanah (39 Kitap) ve İncil (27 Kitap) Canlı API"),
              _buildFeatureRow("15 Büyük Konuda 3'lü Teolojik Karşılaştırma Motoru"),
              _buildFeatureRow("Tefekkür Ambiyans Ses Mikseri (432Hz Ney, Yağmur, Harem)"),
              _buildFeatureRow("Kilit Ekranı Saatlik Kısa Ayet Kartı & Ayet Paylaşım Stüdyosu"),
              _buildFeatureRow("Sınırsız Özel Zikirmatik & 99 Esmaül Hüsna Ebced Aktarımı"),
              const SizedBox(height: 18),

              _buildPlanCard(
                id: 'monthly',
                title: "Aylık Esnek Plan",
                price: offer.monthlyPrice,
                subtitle: "İstediğin zaman tek dokunuşla iptal et",
                badge: null,
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                id: 'annual',
                title: "Yıllık Tefekkür Planı",
                price: offer.annualPrice,
                subtitle: "${offer.annualMonthlyEquivalent} • 7 Gün Ücretsiz Deneme",
                badge: "EN POPÜLER • %50 AVANTAJ",
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                id: 'lifetime',
                title: "Ömür Boyu VIP Erişim (Lifetime)",
                price: offer.lifetimePrice,
                subtitle: "Tek seferlik ödeme • Sonsuza dek sınırsız kullanım",
                badge: "SINIRSIZ MİRAS",
              ),
              const SizedBox(height: 20),

              GlassContainer(
                goldAccentBorder: true,
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onTap: () async {
                  await notifier.activatePlan(_selectedTier);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BespokeVectorIcon(
                        type: BespokeIconType.checkBadge,
                        color: Color(0xFF00FF87),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        premium.isPremium
                            ? "Premium Aktif (${premium.activePlanId.toUpperCase()})"
                            : "Seçili Paketi Başlat ve Kilidi Aç",
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
              const Text(
                "114 Sure Kuran-ı Kerim, sesli tilavet, ezan vakitleri ve kıble pusulası herkes için sonsuza dek %100 ücretsizdir.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionChip(
    String label,
    String code,
    bool selected,
    PremiumServiceNotifier notifier,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.switchSimulatedRegion(code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFB300).withOpacity(0.24)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFFFFB300) : Colors.white24,
              width: 0.9,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFFFFE082) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const BespokeVectorIcon(
            type: BespokeIconType.checkBadge,
            color: Color(0xFF00FF87),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.white),
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
                color: const Color(0xFFFFB300).withOpacity(0.22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB300), width: 0.8),
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
                  color: Color(0xFF00FF87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
