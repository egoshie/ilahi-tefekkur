import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geomag/geomag.dart';
import '../../core/services/ambiance_mixer_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';

const String _kaabaSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <path d="M7 17 32 5 57 17 32 29Z" fill="#302116"/>
  <path d="M7 17 32 29 32 58 7 46Z" fill="#100D0B"/>
  <path d="M32 29 57 17 57 46 32 58Z" fill="#211812"/>
  <path d="M7 22 32 34 57 22 57 27 32 39 7 27Z" fill="#D99A36"/>
  <path d="M7 29 32 41 32 44 7 32Z" fill="#A96B20"/>
  <path d="M32 41 57 29 57 32 32 44Z" fill="#E8B957"/>
  <path d="M12 35 27 42 27 54 12 47Z" fill="#1A1511"/>
  <path d="M17 38 23 41 23 49 17 46Z" fill="#D5A34D"/>
  <path d="M9 16 32 6 54 16 32 27Z"
        fill="none" stroke="#F0C46B" stroke-width="1.2" opacity=".8"/>
</svg>
''';

class QiblaAndToolsScreen extends ConsumerStatefulWidget {
  const QiblaAndToolsScreen({super.key});

  @override
  ConsumerState<QiblaAndToolsScreen> createState() =>
      _QiblaAndToolsScreenState();
}

class _QiblaAndToolsScreenState extends ConsumerState<QiblaAndToolsScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  double _magneticHeading = 0.0;
  double _magneticDeclination = 0.0;
  double? _sensorAccuracy;
  bool _sensorActive = false;
  bool _sensorUnavailable = false;
  bool _isQiblaAligned = false;
  String? _declinationCityKey;

  @override
  void initState() {
    super.initState();

    final events = FlutterCompass.events;
    if (events == null) {
      _sensorUnavailable = true;
      return;
    }

    _compassSub = events.listen(
      (event) {
        final heading = event.heading;

        if (!mounted) return;

        if (heading == null || !heading.isFinite) {
          setState(() {
            _sensorActive = false;
            _sensorUnavailable = true;
            _isQiblaAligned = false;
          });
          return;
        }

        final currentPrayerState = ref.read(prayerEngineProvider);
        final city = currentPrayerState.selectedCity;
        final cityKey = '${city.latitude}_${city.longitude}';

        if (_declinationCityKey != cityKey) {
          _declinationCityKey = cityKey;
          try {
            _magneticDeclination = GeoMag()
                .calculate(city.latitude, city.longitude, 0, DateTime.now())
                .dec;
          } catch (_) {
            _magneticDeclination = 0.0;
          }
        }

        final normalizedHeading = (heading + 360.0) % 360.0;
        final correctedHeading =
            (normalizedHeading + _magneticDeclination + 360.0) % 360.0;
        final signedError = ((currentPrayerState.qiblaDirection -
                    correctedHeading +
                    540.0) %
                360.0) -
            180.0;
        final absoluteError = signedError.abs();

        // Histerezis: hizalanma 6° içinde başlar, 10° dışına çıkınca biter.
        final nextAligned =
            _isQiblaAligned ? absoluteError <= 10.0 : absoluteError <= 6.0;

        if (!_isQiblaAligned && nextAligned) {
          HapticFeedback.mediumImpact();
        }

        setState(() {
          _magneticHeading = normalizedHeading;
          _sensorAccuracy = event.accuracy;
          _sensorActive = true;
          _sensorUnavailable = false;
          _isQiblaAligned = nextAligned;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _sensorActive = false;
          _sensorUnavailable = true;
          _isQiblaAligned = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
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

    final city = prayerState.selectedCity;
    final cityKey = '${city.latitude}_${city.longitude}';

    if (_declinationCityKey != cityKey) {
      _declinationCityKey = cityKey;
      try {
        _magneticDeclination = GeoMag()
            .calculate(city.latitude, city.longitude, 0, DateTime.now())
            .dec;
      } catch (_) {
        _magneticDeclination = 0.0;
      }
    }

    // Pusula manyetik kuzeyi verir. Doğu yönlü sapma eklenerek
    // coğrafi kuzeye göre gerçek cihaz başlığı hesaplanır.
    final trueHeading =
        (_magneticHeading + _magneticDeclination + 360.0) % 360.0;
    final qiblaAngle = prayerState.qiblaDirection;
    final relativeAngle = (qiblaAngle - trueHeading) * (math.pi / 180.0);
    final alignmentColor = _isQiblaAligned
        ? const Color(0xFF35D982)
        : const Color(0xFFFFA21A);

    final completedRatio = progress.initialPrayers == 0
        ? 1.0
        : ((progress.initialPrayers - progress.missedPrayers) /
                progress.initialPrayers)
            .clamp(0.0, 1.0);
    final daysLeft = (progress.missedPrayers / progress.dailyPrayerPace).ceil();
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
                          color: Color(0xFFFFA21A),
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
                        color: Colors.white.withValues(alpha: 0.08),
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
                  width: 236,
                  height: 236,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(236, 236),
                        painter: _QiblaCompassPainter(
                          headingDegrees: trueHeading,
                          relativeRadians: relativeAngle,
                          isAligned: _isQiblaAligned,
                        ),
                      ),
                      Positioned(
                        left: 118 + math.sin(relativeAngle) * 83 - 17,
                        top: 118 - math.cos(relativeAngle) * 83 - 17,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _isQiblaAligned
                                ? const Color(0xFFE8FFF1)
                                : const Color(0xFFFFF3DF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: alignmentColor,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: alignmentColor.withValues(alpha: 0.42),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(5),
                          child: SvgPicture.string(
                            _kaabaSvg,
                            semanticsLabel: 'Kâbe',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _sensorActive
                    ? (_isQiblaAligned
                        ? 'Kıble yönü hizalandı • Titreşimle onaylandı'
                        : (_sensorAccuracy != null
                            ? 'Pusula aktif • Sensör doğruluğu ±${_sensorAccuracy!.toStringAsFixed(0)}°'
                            : 'Telefonun üst kenarını Kâbe yönüne çevirin.'))
                    : (_sensorUnavailable
                        ? 'Pusula sensörü okunamıyor. Cihaz sensörünü ve konum ayarlarını kontrol edin.'
                        : 'Pusula sensöründen yön bilgisi bekleniyor...'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  fontWeight:
                      _isQiblaAligned ? FontWeight.w800 : FontWeight.w500,
                  color: _isQiblaAligned ? alignmentColor : Colors.white70,
                ),
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
                          ? const Color(0xFFFFA21A).withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ch.isPlaying
                            ? const Color(0xFFFFA21A)
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
                              color: const Color(0xFFFFA21A),
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
                                      : const Color(0xFFFFA21A),
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
                            activeColor: const Color(0xFFFFA21A),
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
                  color: Color(0xFFFFA21A),
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
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFFA21A)),
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
                          color: Color(0xFFFFA21A),
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
                          color: Color(0xFFFFA21A),
                        ),
                      ),
                    ],
                  ),
                  if (progress.completedJuzs.isNotEmpty)
                    GestureDetector(
                      onTap: () =>
                          _confirmResetHatim(context, progressNotifier),
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
                children: List<Widget>.generate(30, (idx) {
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
                            ? const Color(0xFFFFA21A).withValues(alpha: 0.24)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              done ? const Color(0xFFFFA21A) : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "$juz",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color:
                                done ? const Color(0xFFFFA21A) : Colors.white70,
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
        color: Colors.white.withValues(alpha: 0.05),
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
                    color: const Color(0xFFFFA21A).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "- Eda Et",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFA21A),
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
                    color: Colors.white.withValues(alpha: 0.12),
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

class _QiblaCompassPainter extends CustomPainter {
  final double headingDegrees;
  final double relativeRadians;
  final bool isAligned;

  const _QiblaCompassPainter({
    required this.headingDegrees,
    required this.relativeRadians,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFA21A).withValues(alpha: 0.65);

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10);

    canvas.drawCircle(center, radius, outerRing);
    canvas.drawCircle(center, radius * 0.68, innerRing);

    final headingRadians = headingDegrees * math.pi / 180.0;

    // Kuzey, doğu, güney ve batı işaretleri gerçek cihaz yönüne göre döner.
    for (int i = 0; i < 72; i++) {
      final angle = (i * 2 * math.pi / 72) - math.pi / 2 - headingRadians;

      final major = i % 6 == 0;
      final medium = i % 3 == 0;
      final length = major ? 12.0 : (medium ? 8.0 : 4.0);

      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 5 - length),
        center.dy + math.sin(angle) * (radius - 5 - length),
      );

      final tickPaint = Paint()
        ..color = major
            ? const Color(0xFFFFC15A)
            : Colors.white.withValues(alpha: medium ? 0.48 : 0.20)
        ..strokeWidth = major ? 2.0 : 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(outer, inner, tickPaint);
    }

    _drawCardinal(canvas, center, radius * 0.77, -math.pi / 2 - headingRadians,
        'N', const Color(0xFFFFA21A));
    _drawCardinal(
        canvas, center, radius * 0.77, -headingRadians, 'E', Colors.white70);
    _drawCardinal(canvas, center, radius * 0.77, math.pi / 2 - headingRadians,
        'S', Colors.white70);
    _drawCardinal(canvas, center, radius * 0.77, math.pi - headingRadians, 'W',
        Colors.white70);

    // Kıble oku telefonun gerçek yönüne göre konumlanır.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(relativeRadians);

    final guidanceColor = isAligned
        ? const Color(0xFF35D982)
        : const Color(0xFFFFA21A);

    final shaft = Paint()
      ..color = guidanceColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset.zero,
      Offset(0, -radius * 0.54),
      shaft,
    );

    final arrow = Path()
      ..moveTo(0, -radius * 0.64)
      ..lineTo(-8, -radius * 0.47)
      ..lineTo(0, -radius * 0.52)
      ..lineTo(8, -radius * 0.47)
      ..close();

    final arrowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isAligned
            ? const [
                Color(0xFFB8FFD2),
                Color(0xFF20B968),
              ]
            : const [
                Color(0xFFFFE3A3),
                Color(0xFFFF8F00),
              ],
      ).createShader(
        Rect.fromCircle(center: Offset.zero, radius: radius),
      );

    canvas.drawPath(arrow, arrowPaint);
    canvas.restore();

    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: isAligned
            ? const [
                Color(0xFFB8FFD2),
                Color(0xFF20B968),
                Color(0xFF075B32),
              ]
            : const [
                Color(0xFFFFD17B),
                Color(0xFFFF8F00),
                Color(0xFF7A3B08),
              ],
      ).createShader(Rect.fromCircle(center: center, radius: 9));

    canvas.drawCircle(center, 8, centerPaint);
  }

  void _drawCardinal(
    Canvas canvas,
    Offset center,
    double distance,
    double angle,
    String label,
    Color color,
  ) {
    final point = Offset(
      center.dx + math.cos(angle) * distance,
      center.dy + math.sin(angle) * distance,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _QiblaCompassPainter oldDelegate) {
    return oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.relativeRadians != relativeRadians ||
        oldDelegate.isAligned != isAligned;
  }
}
