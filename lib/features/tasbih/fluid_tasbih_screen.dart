import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/services/tasbih_session_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../esma/esmaul_husna_sheet.dart';
import '../paywall/liquid_glass_paywall.dart';

class _RippleWave {
  final Offset center;
  final DateTime createdAt;
  _RippleWave(this.center, this.createdAt);
}

class FluidTasbihScreen extends ConsumerStatefulWidget {
  const FluidTasbihScreen({super.key});

  @override
  ConsumerState< FluidTasbihScreen > createState() => _FluidTasbihScreenState();
}

class _FluidTasbihScreenState extends ConsumerState< FluidTasbihScreen >
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleTicker;
  final List< _RippleWave > _ripples = [];

  @override
  void initState() {
    super.initState();
    _rippleTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  Future< void > _handleTouch(TapDownDetails details) async {
    final session = ref.read(tasbihSessionProvider);
    final notifier = ref.read(tasbihSessionProvider.notifier);

    setState(() {
      _ripples.add(_RippleWave(details.localPosition, DateTime.now()));
    });

    final nextCount = await notifier.incrementActive();

    if (session.hapticEnabled) {
      if (nextCount % 100 == 0) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 80));
        HapticFeedback.heavyImpact();
      } else if (nextCount % 33 == 0) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _confirmResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 24,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sayacı Sıfırla",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Mevcut zikir sayacını sıfırlamak istediğinize emin misiniz?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () => Navigator.pop(ctx),
                      child: const Center(
                        child: Text("Vazgeç", style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 14,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(tasbihSessionProvider.notifier)
                            .resetActiveCount();
                      },
                      child: const Center(
                        child: Text(
                          "Sıfırla",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rippleTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tasbihSessionProvider);
    final notifier = ref.read(tasbihSessionProvider.notifier);
    final premium = ref.watch(premiumServiceProvider);
    final activeTasbih = session.activeRecord;

    final progressRatio = (activeTasbih == null || activeTasbih.target <= 0)
        ? 0.0
        : ((activeTasbih.count % activeTasbih.target) / activeTasbih.target)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Akışkan Zikirmatik",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      "Günlük Toplam: ${session.todayTotalCount} Zikir",
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64FFDA)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => notifier.toggleHaptic(!session.hapticEnabled),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: session.hapticEnabled
                        ? const Color(0xFF64FFDA).withOpacity(0.16)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: session.hapticEnabled
                          ? const Color(0xFF64FFDA)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    session.hapticEnabled ? "Titreşim Açık" : "Sessiz",
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: 14,
                goldAccentBorder: true,
                onTap: () => EsmaulHusnaSheet.show(context),
                child: const Text(
                  "99 Esmaül Hüsna",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFE082),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...List< Widget >.generate(session.records.length, (i) {
                  final r = session.records[i];
                  final sel = i == session.activeIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => notifier.selectIndex(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF64FFDA).withOpacity(0.20)
                              : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF64FFDA)
                                : Colors.white24,
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          "${r.title} (${r.count}/${r.target})",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                sel ? const Color(0xFF64FFDA) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () =>
                      _handleAddCustomTasbih(context, premium.isPremium),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE082).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFE082), width: 0.9),
                    ),
                    child: const Row(
                      children: [
                        BespokeVectorIcon(
                          type: BespokeIconType.plusCircle,
                          color: Color(0xFFFFE082),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Özel Zikir Ekle",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _handleTouch,
              child: GlassContainer(
                borderRadius: 34,
                emeraldGlow: true,
                padding: const EdgeInsets.all(20),
                child: AnimatedBuilder(
                  animation: _rippleTicker,
                  builder: (context, _) {
                    final now = DateTime.now();
                    _ripples.removeWhere((r) =>
                        now.difference(r.createdAt).inMilliseconds > 1000);
                    return CustomPaint(
                      painter:
                          _TasbihRipplePainter(ripples: List.of(_ripples)),
                      child: Center(
                        child: activeTasbih == null
                            ? const SizedBox()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    activeTasbih.arabic,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFF8E1),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    activeTasbih.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    "${activeTasbih.count}",
                                    style: const TextStyle(
                                      fontSize: 68,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64FFDA),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 180,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progressRatio,
                                        minHeight: 6,
                                        backgroundColor: Colors.white12,
                                        valueColor:
                                            const AlwaysStoppedAnimation< Color >(
                                          Color(0xFF64FFDA),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Hedef: ${activeTasbih.target} • Devir: ${(activeTasbih.count ~/ activeTasbih.target)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFE082),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  GestureDetector(
                                    onTap: () => _confirmResetDialog(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "Sayacı Sıfırla",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddCustomTasbih(BuildContext context, bool isPremium) {
    final session = ref.read(tasbihSessionProvider);
    final customCount = session.records.where((r) => r.isCustom).length;
    if (!isPremium && customCount >= 3) {
      LiquidGlassPaywallSheet.show(context);
      return;
    }

    final titleCtrl = TextEditingController();
    final arabicCtrl =
        TextEditingController(text: "سُبْحَانَ ٱللَّهِ وَبِحَمْدِهِ");
    final targetCtrl = TextEditingController(text: "99");

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 24,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Yeni Zikir Hedefi Oluştur",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(hintText: "Zikir Başlığı"),
              ),
              TextField(
                controller: arabicCtrl,
                decoration: const InputDecoration(hintText: "Arapça Hat"),
              ),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: "Hedef Sayı (Örn: 33, 99, 100)"),
              ),
              const SizedBox(height: 14),
              GlassContainer(
                emeraldGlow: true,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () async {
                  final target = int.tryParse(targetCtrl.text) ?? 33;
                  await ref
                      .read(tasbihSessionProvider.notifier)
                      .addCustomDhikr(
                        title: titleCtrl.text.trim().isEmpty
                            ? "Özel Zikir"
                            : titleCtrl.text.trim(),
                        arabic: arabicCtrl.text.trim(),
                        target: target,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Center(
                  child: Text(
                    "Kaydet ve Başla",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64FFDA)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasbihRipplePainter extends CustomPainter {
  final List< _RippleWave > ripples;
  _TasbihRipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final r in ripples) {
      final elapsed = now.difference(r.createdAt).inMilliseconds / 1000.0;
      final t = elapsed.clamp(0.0, 1.0);
      final radius = 20.0 + (size.width * 0.62 * t);
      final opacity = (1.0 - t) * 0.55;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * (1.0 - t * 0.5)
        ..color = const Color(0xFF64FFDA).withOpacity(opacity);

      canvas.drawCircle(r.center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihRipplePainter oldDelegate) => true;
}
