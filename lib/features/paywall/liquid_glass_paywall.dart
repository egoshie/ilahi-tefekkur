import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';

class LiquidGlassPaywallSheet extends ConsumerStatefulWidget {
  const LiquidGlassPaywallSheet({super.key});

  static Future< void > show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LiquidGlassPaywallSheet(),
    );
  }

  @override
  ConsumerState< LiquidGlassPaywallSheet > createState() =>
      _LiquidGlassPaywallSheetState();
}

class _LiquidGlassPaywallSheetState
    extends ConsumerState< LiquidGlassPaywallSheet > {
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
          enableBlur: true,
          blurSigma: 26,
          goldAccentBorder: true,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
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
                    color: Color(0xFFFFE082),
                    size: 26,
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
                "Reklamsız İbadet • Tüm İlahi Kitaplar • Karşılaştırmalı Tefekkür",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

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
                            "Tüm Huzur Özel Kitaplarını Etkinleştir",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF64FFDA),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Tevrat, İncil ve Karşılaştırmalı Kıssalar erişimini bu cihazda açar.",
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: premium.isSandboxUnlocked,
                      activeColor: const Color(0xFF64FFDA),
                      onChanged: (val) => notifier.toggleSandboxMode(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildFeatureRow("Tevrat (39 Kitap) ve İncil (27 Kitap) Tam Külliyat"),
              _buildFeatureRow("15 Büyük Kıssada 3'lü Karşılaştırmalı İnceleme"),
              _buildFeatureRow("Çevrimdışı Meditatif Ambiyans Ses Mikseri"),
              _buildFeatureRow("Kilit Ekranı Geniş Ayet Kartı & Hikâye Stüdyosu"),
              _buildFeatureRow("Sınırsız Zikirmatik & 99 Esmaül Hüsna Rehberi"),
              const SizedBox(height: 18),

              _buildPlanCard(
                id: 'monthly',
                title: "Aylık Plan",
                price: offer.monthlyPrice,
                subtitle: "Esnek aylık katkı",
                badge: null,
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                id: 'annual',
                title: "Yıllık Huzur Planı",
                price: offer.annualPrice,
                subtitle: "${offer.annualMonthlyEquivalent} • 7 Gün Ücretsiz Deneme",
                badge: "EN ÇOK TERCİH EDİLEN",
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                id: 'lifetime',
                title: "Ömür Boyu Tam Erişim",
                price: offer.lifetimePrice,
                subtitle: "Tek seferlik katkı • Süresiz kullanım",
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
                                  : "Seçili Planı Etkinleştir",
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
              const SizedBox(height: 10),
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
          const BespokeVectorIcon(
            type: BespokeIconType.checkBadge,
            color: Color(0xFF64FFDA),
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
                color: const Color(0xFFFFE082).withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
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
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
