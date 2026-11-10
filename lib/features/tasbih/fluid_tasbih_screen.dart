import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/services/tasbih_session_service.dart';
import '../../core/theme/glass_container.dart';
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
  ConsumerState<FluidTasbihScreen> createState() => _FluidTasbihScreenState();
}

class _FluidTasbihScreenState extends ConsumerState<FluidTasbihScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleTicker;
  final List<_RippleWave> _ripples = [];

  @override
  void initState() {
    super.initState();
    _rippleTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  Future<void> _handleTouch(TapDownDetails details) async {
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

  Future<void> _moveRecord(int delta) async {
    final session = ref.read(tasbihSessionProvider);
    if (session.records.length < 2) return;
    final next = (session.activeIndex + delta) % session.records.length;
    await ref.read(tasbihSessionProvider.notifier).selectIndex(next);
    await HapticFeedback.selectionClick();
  }

  String _meaningFor(String title) {
    switch (title.toLowerCase()) {
      case 'sübhanallah':
        return 'Allah eksik sıfatlardan münezzehtir.';
      case 'elhamdülillah':
        return 'Hamd, âlemlerin Rabbi Allah’a mahsustur.';
      case 'allahü ekber':
      case 'allahu ekber':
        return 'Allah en yücedir.';
      case 'lâ ilâhe illallah':
      case 'la ilahe illallah':
        return 'Allah’tan başka ilah yoktur.';
      default:
        return 'Kalbini zikirle huzura yönelt.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tasbihSessionProvider);
    final premium = ref.watch(premiumServiceProvider);
    final notifier = ref.read(tasbihSessionProvider.notifier);
    final activeTasbih = session.activeRecord;

    if (activeTasbih == null) {
      return const Center(
        child: Text(
          'Zikir kayıtları yükleniyor...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final target = activeTasbih.target > 0 ? activeTasbih.target : 1;
    final currentInRound = activeTasbih.count == 0
        ? 0
        : (activeTasbih.count % target == 0
            ? target
            : activeTasbih.count % target);
    final completedRounds =
        activeTasbih.count == 0 ? 1 : ((activeTasbih.count - 1) ~/ target) + 1;
    final progressRatio = currentInRound / target;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Zikirmatik',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
              ),
              PopupMenuButton<int>(
                tooltip: 'Zikir listem',
                onSelected: (index) => notifier.selectIndex(index),
                itemBuilder: (context) => List<PopupMenuEntry<int>>.generate(
                  session.records.length,
                  (index) {
                    final record = session.records[index];
                    return PopupMenuItem<int>(
                      value: index,
                      child: Text(
                          '${record.title}  ${record.count}/${record.target}'),
                    );
                  },
                ),
                child: const GlassContainer(
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                  goldAccentBorder: true,
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.format_list_bulleted_rounded,
                    color: Color(0xFFFFA21A),
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassContainer(
                width: 44,
                height: 44,
                borderRadius: 22,
                padding: const EdgeInsets.all(10),
                onTap: () => notifier.toggleHaptic(!session.hapticEnabled),
                child: Icon(
                  session.hapticEnabled
                      ? Icons.vibration_rounded
                      : Icons.phonelink_erase_rounded,
                  color: session.hapticEnabled
                      ? const Color(0xFFFFA21A)
                      : Colors.white60,
                  size: 21,
                ),
              ),
              const SizedBox(width: 8),
              GlassContainer(
                width: 44,
                height: 44,
                borderRadius: 22,
                padding: const EdgeInsets.all(10),
                onTap: () => _handleAddCustomTasbih(context, premium.isPremium),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFFFA21A),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Column(
            children: [
              Text(
                activeTasbih.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFA21A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _meaningFor(activeTasbih.title),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassContainer(
            borderRadius: 24,
            enableBlur: true,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$completedRounds',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'TUR',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 46, color: Colors.white12),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$target',
                        style: const TextStyle(
                          color: Color(0xFFFFA21A),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'HEDEF',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final diameter = math
                    .min(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    )
                    .clamp(210.0, 520.0)
                    .toDouble();
                return Center(
                  child: SizedBox(
                    width: diameter,
                    height: diameter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _handleTouch,
                      child: AnimatedBuilder(
                        animation: _rippleTicker,
                        builder: (context, _) {
                          final now = DateTime.now();
                          _ripples.removeWhere(
                            (r) =>
                                now.difference(r.createdAt).inMilliseconds >
                                1000,
                          );
                          return CustomPaint(
                            painter: _DhikrBeadPainter(
                              progress: progressRatio,
                              totalBeads: 33,
                            ),
                            foregroundPainter: _TasbihRipplePainter(
                              ripples: List.of(_ripples),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: 0.70,
                                  heightFactor: 0.70,
                                  child: GlassContainer(
                                    borderRadius: diameter,
                                    enableBlur: true,
                                    blurSigma: 20,
                                    borderColor: Colors.white24,
                                    gradientColors: [
                                      const Color(0xFF4A4037)
                                          .withValues(alpha: 0.62),
                                      const Color(0xFF28221D)
                                          .withValues(alpha: 0.78),
                                    ],
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            child: Text(
                                              '${activeTasbih.count}',
                                              key: ValueKey(activeTasbih.count),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: diameter * 0.19,
                                                fontWeight: FontWeight.w900,
                                                height: 1,
                                                letterSpacing: -2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          const Text(
                                            'ZİKİR',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 30,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: () => _moveRecord(-1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 25),
                      SizedBox(width: 3),
                      Text('Önceki',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GlassContainer(
                width: 54,
                height: 54,
                borderRadius: 27,
                padding: const EdgeInsets.all(12),
                onTap: () => _confirmResetDialog(context),
                child: const Icon(
                  Icons.restart_alt_rounded,
                  color: Colors.white70,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  borderRadius: 30,
                  goldAccentBorder: true,
                  gradientColors: const [
                    Color(0xFFFFA21A),
                    Color(0xFFFF8F00),
                  ],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: () => _moveRecord(1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sonraki',
                        style: TextStyle(
                          color: Color(0xFF21160A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF21160A),
                        size: 25,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bugün ${session.todayTotalCount} zikir',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => EsmaulHusnaSheet.show(context),
                child: const Text(
                  '99 Esmaül Hüsna',
                  style: TextStyle(
                    color: Color(0xFFFFC15A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
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
                  await ref.read(tasbihSessionProvider.notifier).addCustomDhikr(
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
                        fontWeight: FontWeight.bold, color: Color(0xFFFFA21A)),
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
      final elapsed = now.difference(r.createdAt).inMilliseconds / 1000.0;
      final t = elapsed.clamp(0.0, 1.0);
      final radius = 20.0 + (size.width * 0.62 * t);
      final opacity = (1.0 - t) * 0.55;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * (1.0 - t * 0.5)
        ..color = const Color(0xFFFFA21A).withValues(alpha: opacity);

      canvas.drawCircle(r.center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbihRipplePainter oldDelegate) => true;
}

class _DhikrBeadPainter extends CustomPainter {
  final double progress;
  final int totalBeads;

  const _DhikrBeadPainter({required this.progress, required this.totalBeads});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.405;
    final beadRadius = size.width * 0.024;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawCircle(center, radius, track);

    final activeCount = (progress * totalBeads).round().clamp(0, totalBeads);
    for (var index = 0; index < totalBeads; index++) {
      final angle = -math.pi / 2 + (2 * math.pi * index / totalBeads);
      final point = center +
          Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          );
      final isActive = index < activeCount;

      if (isActive) {
        final glow = Paint()
          ..color = const Color(0xFFFFA21A).withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, beadRadius * 1.4);
        canvas.drawCircle(point, beadRadius * 1.35, glow);
      }

      final beadPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.42),
          colors: isActive
              ? const [Color(0xFFFFE0A3), Color(0xFFFFA21A), Color(0xFF9A4D08)]
              : const [Color(0xFF3D2A20), Color(0xFF160F0C), Color(0xFF080605)],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: point, radius: beadRadius));
      canvas.drawCircle(point, beadRadius, beadPaint);

      final highlight = Paint()
        ..color = Colors.white.withValues(alpha: isActive ? 0.50 : 0.13);
      canvas.drawCircle(
        point + Offset(-beadRadius * 0.28, -beadRadius * 0.30),
        beadRadius * 0.20,
        highlight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DhikrBeadPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.totalBeads != totalBeads;
}
