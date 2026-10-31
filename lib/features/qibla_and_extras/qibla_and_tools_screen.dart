import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/services/ambiance_mixer_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';

class QiblaAndToolsScreen extends ConsumerStatefulWidget {
  const QiblaAndToolsScreen({super.key});

  @override
  ConsumerState< QiblaAndToolsScreen > createState() =>
      _QiblaAndToolsScreenState();
}

class _QiblaAndToolsScreenState extends ConsumerState< QiblaAndToolsScreen > {
  StreamSubscription< MagnetometerEvent >? _magSub;
  double _deviceHeading = 0.0;
  bool _sensorActive = false;

  @override
  void initState() {
    super.initState();
    try {
      _magSub = magnetometerEventStream().listen(
        (event) {
          final angle = math.atan2(event.y, event.x) * (180 / math.pi);
          if (mounted) {
            setState(() {
              _deviceHeading = (angle + 360) % 360;
              _sensorActive = true;
            });
          }
        },
        onError: (_) {
          if (mounted) setState(() => _sensorActive = false);
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerEngineProvider);
    final prayerNotifier = ref.read(prayerEngineProvider.notifier);
    final ambianceChannels = ref.watch(ambianceMixerProvider);
    final ambianceNotifier = ref.read(ambianceMixerProvider.notifier);
    final progress = ref.watch(userProgressProvider);
    final progressNotifier = ref.read(userProgressProvider.notifier);

    final qiblaAngle = prayerState.qiblaDirection;
    final relativeAngle = ((qiblaAngle - _deviceHeading) * (math.pi / 180));

    final completedRatio = progress.initialPrayers == 0
        ? 1.0
        : ((progress.initialPrayers - progress.missedPrayers) /
                progress.initialPrayers)
            .clamp(0.0, 1.0);
    final daysLeft =
        (progress.missedPrayers / progress.dailyPrayerPace).ceil();
    final finishDate = DateTime.now().add(Duration(days: daysLeft));
    final finishFormatted = DateFormat('dd.MM.yyyy').format(finishDate);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        const Text(
          "Kıble, Ambiyans Mikseri & İbadet Çetelesi",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),

        GlassContainer(
          borderRadius: 28,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kıble Pusulası",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${prayerState.selectedCity.name} • Kâbe Açısı: ${qiblaAngle.toStringAsFixed(1)}°",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64FFDA),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => prayerNotifier.detectGpsLocation(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.gpsTarget,
                            color: Color(0xFFFFE082),
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text("Konum Yenile", style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                child: SizedBox(
                  width: 172,
                  height: 172,
                  child: CustomPaint(
                    painter:
                        _QiblaBeamCompassPainter(relativeRadians: relativeAngle),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _sensorActive
                    ? "Pusulayı kalibre etmek için telefonu 8 çizecek şekilde hareket ettirin."
                    : "Manyetometre sensör verisi bekleniyor; Kâbe açısını (${qiblaAngle.toStringAsFixed(1)}°) referans alabilirsiniz.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassContainer(
          borderRadius: 28,
          emeraldGlow: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tefekkür Ambiyans Ses Mikseri",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => ambianceNotifier.stopAll(),
                    child: const Text(
                      "Tümünü Durdur",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Arka planda kesintisiz çalışan döngüsel meditatif ses katmanları",
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...ambianceChannels.map((ch) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ch.isPlaying
                          ? const Color(0xFF64FFDA).withOpacity(0.14)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ch.isPlaying
                            ? const Color(0xFF64FFDA)
                            : Colors.white12,
                        width: 0.9,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            LiveSvgAudioVisualizer(
                              isPlaying: ch.isPlaying,
                              color: const Color(0xFF64FFDA),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ch.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    ch.subtitle,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white60),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  ambianceNotifier.toggleChannel(ch.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: ch.isPlaying
                                      ? const Color(0xFFFFE082)
                                      : const Color(0xFF64FFDA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    BespokeVectorIcon(
                                      type: ch.isPlaying
                                          ? BespokeIconType.stopSquare
                                          : BespokeIconType.playTriangle,
                                      color: Colors.black,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      ch.isPlaying ? "Durdur" : "Başlat",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ch.isPlaying)
                          Slider(
                            value: ch.volume,
                            activeColor: const Color(0xFF64FFDA),
                            onChanged: (v) =>
                                ambianceNotifier.setVolume(ch.id, v),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassContainer(
          borderRadius: 28,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kaza Namazı & Orucu Takibi",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Tamamlanan: %${(completedRatio * 100).toStringAsFixed(0)} • Tahmini Bitiş: $finishFormatted",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64FFDA),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completedRatio,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation< Color >(Color(0xFF64FFDA)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildKazaCard(
                      label: "Kalan Kaza Namazı",
                      value: progress.missedPrayers,
                      onDec: () => progressNotifier.updateKaza(
                          missedPrayers: progress.missedPrayers - 1),
                      onInc: () => progressNotifier.updateKaza(
                          missedPrayers: progress.missedPrayers + 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKazaCard(
                      label: "Kalan Kaza Orucu",
                      value: progress.missedFasts,
                      onDec: () => progressNotifier.updateKaza(
                          missedFasts: progress.missedFasts - 1),
                      onInc: () => progressNotifier.updateKaza(
                          missedFasts: progress.missedFasts + 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Günlük Hedef: ${progress.dailyPrayerPace} Vakit / Gün",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => progressNotifier.updateKaza(
                            dailyPrayerPace: progress.dailyPrayerPace - 1),
                        child: const BespokeVectorIcon(
                          type: BespokeIconType.minusCircle,
                          color: Color(0xFFFFE082),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => progressNotifier.updateKaza(
                            dailyPrayerPace: progress.dailyPrayerPace + 1),
                        child: const BespokeVectorIcon(
                          type: BespokeIconType.plusCircle,
                          color: Color(0xFF64FFDA),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GlassContainer(
          borderRadius: 28,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "30 Cüz Hatim Takibi",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${progress.completedJuzs.length} / 30 Cüz Tamamlandı",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64FFDA),
                        ),
                      ),
                    ],
                  ),
                  if (progress.completedJuzs.isNotEmpty)
                    GestureDetector(
                      onTap: () => _confirmResetHatim(context, progressNotifier),
                      child: const Text(
                        "Sıfırla",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFE082),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List< Widget >.generate(30, (idx) {
                  final juz = idx + 1;
                  final done = progress.completedJuzs.contains(juz);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      progressNotifier.toggleJuzCompleted(juz);
                    },
                    child: Container(
                      width: 44,
                      height: 38,
                      decoration: BoxDecoration(
                        color: done
                            ? const Color(0xFF64FFDA).withOpacity(0.24)
                            : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: done
                              ? const Color(0xFF64FFDA)
                              : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$juz",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: done
                                ? const Color(0xFF64FFDA)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmResetHatim(
    BuildContext context,
    UserProgressNotifier notifier,
  ) {
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
                "Hatim Çizelgesini Sıfırla",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "İşaretlediğiniz tüm cüz ilerlemesini sıfırlamak istediğinize emin misiniz?",
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
                        await notifier.resetAllJuzProgress();
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

  Widget _buildKazaCard({
    required String label,
    required int value,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            "$value",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFE082),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onDec,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64FFDA).withOpacity(0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "- Eda Et",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onInc,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("+ Ekle", style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QiblaBeamCompassPainter extends CustomPainter {
  final double relativeRadians;
  _QiblaBeamCompassPainter({required this.relativeRadians});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF64FFDA).withOpacity(0.45);
    canvas.drawCircle(center, radius - 4, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(relativeRadians);

    final beamPath = Path()
      ..moveTo(0, -radius + 6)
      ..lineTo(-18, 12)
      ..lineTo(0, -4)
      ..lineTo(18, 12)
      ..close();

    final beamPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE082), Color(0xFF64FFDA)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawPath(beamPath, beamPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QiblaBeamCompassPainter oldDelegate) {
    return oldDelegate.relativeRadians != relativeRadians;
  }
}
