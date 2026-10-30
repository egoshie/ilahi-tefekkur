import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/database_seeder.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../paywall/liquid_glass_paywall.dart';

class _RippleWave {
  final Offset center;
  final DateTime createdAt;
  _RippleWave(this.center, this.createdAt);
}

class FluidTasbihScreen extends ConsumerStatefulWidget {
  const FluidTasbihScreen({super.key});

  @override
  ConsumerState<FluidTasbihScreen> createState() => _FluidTasbihScreenState();
}

class _FluidTasbihScreenState extends ConsumerState<FluidTasbihScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleTicker;
  final List<_RippleWave> _ripples = [];
  List<TasbihRecord> _records = [];
  List<EsmaItem> _esmas = [];
  int _activeIndex = 0;
  bool _showEsmaGuide = false;

  @override
  void initState() {
    super.initState();
    _rippleTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseServiceProvider);
    final rec = await db.getTasbihRecords();
    final esm = await db.fetchEsmaulHusna();
    if (mounted) {
      setState(() {
        _records = rec;
        _esmas = esm;
      });
    }
  }

  Future<void> _handleTouch(TapDownDetails details) async {
    if (_records.isEmpty) return;
    final current = _records[_activeIndex];
    final nextCount = current.count + 1;

    setState(() {
      _ripples.add(_RippleWave(details.localPosition, DateTime.now()));
      _records[_activeIndex] = TasbihRecord(
        id: current.id,
        title: current.title,
        arabic: current.arabic,
        count: nextCount,
        target: current.target,
        isCustom: current.isCustom,
      );
    });

    if (nextCount % 100 == 0) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 90));
      HapticFeedback.heavyImpact();
    } else if (nextCount % 33 == 0) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    if (current.id != null) {
      await ref.read(databaseServiceProvider).updateTasbihCount(current.id!, nextCount);
    }
  }

  @override
  void dispose() {
    _rippleTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumServiceProvider);
    final activeTasbih = _records.isNotEmpty ? _records[_activeIndex] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 118),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Akışkan Zikirmatik & 99 Esmaül Hüsna",
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Ekrana bakmadan dokunarak zikir çekin • 99 Esma Ebced Rehberi",
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: 14,
                emeraldGlow: _showEsmaGuide,
                goldAccentBorder: !_showEsmaGuide,
                onTap: () => setState(() => _showEsmaGuide = !_showEsmaGuide),
                child: Text(
                  _showEsmaGuide ? "Zikirmatiğe Dön" : "99 Esmaül Hüsna",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FF87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_showEsmaGuide)
            Expanded(child: _buildEsmaList())
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(_records.length, (i) {
                    final r = _records[i];
                    final sel = i == _activeIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF00FF87).withOpacity(0.22)
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? const Color(0xFF00FF87) : Colors.white24,
                              width: 0.9,
                            ),
                          ),
                          child: Text(
                            "${r.title} (${r.count}/${r.target})",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? const Color(0xFF00FF87) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => _handleAddCustomTasbih(context, premium.isPremium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 0.9),
                      ),
                      child: const Row(
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.plusCircle,
                            color: Color(0xFF00E5FF),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Özel Zikir Ekle",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00E5FF),
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
                  padding: EdgeInsets.zero,
                  child: AnimatedBuilder(
                    animation: _rippleTicker,
                    builder: (context, _) {
                      final now = DateTime.now();
                      _ripples.removeWhere(
                          (r) => now.difference(r.createdAt).inMilliseconds > 1100);
                      return CustomPaint(
                        painter: _TasbihRipplePainter(ripples: List.of(_ripples)),
                        child: Center(
                          child: activeTasbih == null
                              ? const SizedBox()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      activeTasbih.arabic,
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFE082),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      activeTasbih.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Text(
                                      "${activeTasbih.count}",
                                      style: const TextStyle(
                                        fontSize: 70,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF00FF87),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      "Hedef: ${activeTasbih.target} • Devir: ${(activeTasbih.count ~/ activeTasbih.target)}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF00E5FF),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () async {
                                        if (activeTasbih.id != null) {
                                          await ref
                                              .read(databaseServiceProvider)
                                              .updateTasbihCount(activeTasbih.id!, 0);
                                          await _loadData();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Sayacı Sıfırla",
                                          style: TextStyle(fontSize: 12, color: Colors.white70),
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
        ],
      ),
    );
  }

  Widget _buildEsmaList() {
    return ListView.separated(
      itemCount: _esmas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final e = _esmas[index];
        return GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(16),
          onTap: () async {
            await ref
                .read(databaseServiceProvider)
                .addCustomTasbih("Ya ${e.transliteration}", e.arabic, e.ebcedValue);
            await _loadData();
            setState(() {
              _showEsmaGuide = false;
              _activeIndex = _records.length - 1;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${e.number}. ${e.transliteration} (Ebced: ${e.ebcedValue})",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                  ),
                  Text(
                    e.arabic,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00FF87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(e.turkishMeaning, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              const Text(
                "Zikirmatik'e Ebced hedefiyle aktarmak için karta dokunun",
                style: TextStyle(fontSize: 11, color: Color(0xFF00E5FF)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAddCustomTasbih(BuildContext context, bool isPremium) {
    final customCount = _records.where((r) => r.isCustom).length;
    if (!isPremium && customCount >= 2) {
      LiquidGlassPaywallSheet.show(context);
      return;
    }

    final titleCtrl = TextEditingController();
    final arabicCtrl = TextEditingController(text: "سُبْحَانَ ٱللَّهِ وَبِحَمْدِهِ");
    final targetCtrl = TextEditingController(text: "99");

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 24,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Yeni Özel Zikir Oluştur",
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
                decoration: const InputDecoration(hintText: "Hedef Sayı (Örn: 33, 99, 100)"),
              ),
              const SizedBox(height: 14),
              GlassContainer(
                emeraldGlow: true,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () async {
                  final target = int.tryParse(targetCtrl.text) ?? 33;
                  await ref.read(databaseServiceProvider).addCustomTasbih(
                        titleCtrl.text.isEmpty ? "Özel Zikir" : titleCtrl.text,
                        arabicCtrl.text,
                        target,
                      );
                  await _loadData();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Center(
                  child: Text(
                    "Zikri Kaydet",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FF87)),
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
  final List<_RippleWave> ripples;
  _TasbihRipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final r in ripples) {
      final elapsed = now.difference(r.createdAt).inMilliseconds / 1100.0;
      final t = elapsed.clamp(0.0, 1.0);
      final radius = 20.0 + (size.width * 0.65 * t);
      final opacity = (1.0 - t) * 0.65;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * (1.0 - t * 0.5)
        ..color = const Color(0xFF00FF87).withOpacity(opacity);

      canvas.drawCircle(r.center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihRipplePainter oldDelegate) => true;
}
