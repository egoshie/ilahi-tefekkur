import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ambiance_mixer_service.dart';
import '../../core/services/prayer_service.dart';
import '../esma/esmaul_husna_sheet.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';

class QiblaAndToolsScreen extends ConsumerStatefulWidget {
  const QiblaAndToolsScreen({super.key});

  @override
  ConsumerState<QiblaAndToolsScreen> createState() =>
      _QiblaAndToolsScreenState();
}

class _QiblaAndToolsScreenState extends ConsumerState<QiblaAndToolsScreen> {
  StreamSubscription<MagnetometerEvent>? _magSub;
  double _deviceHeading = 0.0;

  int _initialPrayers = 60;
  int _remainingPrayers = 18;
  int _dailyPace = 2;
  int _remainingFasts = 4;
  int _completedJuz = 0;
  int _dailyReadJuz = 0;
  static const int _dailyJuzGoal = 1;

  @override
  void initState() {
    super.initState();
    _loadKazaCounts();
    try {
      _magSub = magnetometerEventStream().listen((event) {
        final angle = math.atan2(event.y, event.x) * (180 / math.pi);
        if (mounted) {
          setState(() {
            _deviceHeading = (angle + 360) % 360;
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _loadKazaCounts() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _initialPrayers = prefs.getInt('kaza_initial_prayers') ?? 60;
        _remainingPrayers = prefs.getInt('kaza_prayers') ?? 18;
        _dailyPace = prefs.getInt('kaza_daily_pace') ?? 2;
        _remainingFasts = prefs.getInt('kaza_fasts') ?? 4;
        _completedJuz = prefs.getInt('huzur_hatim_juz') ?? 0;
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final savedDay = prefs.getString('huzur_daily_juz_date');
        _dailyReadJuz = savedDay == today ? (prefs.getInt('huzur_daily_juz_count') ?? 0) : 0;
      });
    }
  }

  Future<void> _updateHatim(int value) async {
    final next = value.clamp(0, 30).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('huzur_hatim_juz', next);
    if (mounted) setState(() => _completedJuz = next);
  }

  Future<void> _recordDailyJuz() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDay = prefs.getString('huzur_daily_juz_date');
    final current = savedDay == today ? (prefs.getInt('huzur_daily_juz_count') ?? 0) : 0;
    final nextDaily = current + 1;
    await prefs.setString('huzur_daily_juz_date', today);
    await prefs.setInt('huzur_daily_juz_count', nextDaily);
    await _updateHatim(_completedJuz + 1);
    if (mounted) setState(() => _dailyReadJuz = nextDaily);
  }

  Future<void> _updateKaza({
    int? remainingPrayers,
    int? remainingFasts,
    int? dailyPace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nextPrayers = (remainingPrayers ?? _remainingPrayers).clamp(0, 99999).toInt();
    final nextFasts = (remainingFasts ?? _remainingFasts).clamp(0, 9999).toInt();
    final nextPace = (dailyPace ?? _dailyPace).clamp(1, 20).toInt();
    final nextInitial =
        nextPrayers > _initialPrayers ? nextPrayers : _initialPrayers;

    await prefs.setInt('kaza_initial_prayers', nextInitial);
    await prefs.setInt('kaza_prayers', nextPrayers);
    await prefs.setInt('kaza_fasts', nextFasts);
    await prefs.setInt('kaza_daily_pace', nextPace);

    if (!mounted) return;
    setState(() {
      _initialPrayers = nextInitial;
      _remainingPrayers = nextPrayers;
      _remainingFasts = nextFasts;
      _dailyPace = nextPace;
    });
  }

  @override
  void dispose() {
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerEngineProvider);
    final ambianceChannels = ref.watch(ambianceMixerProvider);
    final ambianceNotifier = ref.read(ambianceMixerProvider.notifier);
    final hijri = HijriCalendar.now();

    final qiblaAngle = prayerState.qiblaDirection;
    final relativeAngle = ((qiblaAngle - _deviceHeading) * (math.pi / 180));

    final completedRatio = _initialPrayers == 0
        ? 1.0
        : ((_initialPrayers - _remainingPrayers) / _initialPrayers)
            .clamp(0.0, 1.0)
            .toDouble();
    final daysLeft = (_remainingPrayers / _dailyPace).ceil();
    final finishDate = DateTime.now().add(Duration(days: daysLeft));
    final finishFormatted = DateFormat('dd.MM.yyyy').format(finishDate);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 148),
      children: [
        const Text(
          "Kıble Pusulası, Ambiyans Sesleri & Kaza Takibi",
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        GlassContainer(
          borderRadius: 20, emeraldGlow: true, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          onTap: () => EsmaulHusnaSheet.show(context),
          child: const Row(children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFFE082), size: 24),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('99 Esmaül Hüsna', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFE082))),
              SizedBox(height: 3), Text('İsimleri keşfet • Ebced değerini gör • Zikirmatik hedefi kur', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ])),
            Icon(Icons.chevron_right, color: Color(0xFF64FFDA)),
          ]),
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
                  const Text(
                    "Canlı Kıble Pusulası",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Kâbe Açısı: ${qiblaAngle.toStringAsFixed(1)}°",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: _QiblaBeamCompassPainter(relativeRadians: relativeAngle),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Yön Derecesi: ${_deviceHeading.toStringAsFixed(0)}° • Işık ibresi Kâbe yönünü gösterir",
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
              const Text(
                "Tefekkür Ambiyans Ses Mikseri",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Okuma ve zikir esnasında arka plan su, ney ve kubbe akustiği",
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
                              onTap: () => ambianceNotifier.toggleChannel(ch.id),
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
                            onChanged: (v) => ambianceNotifier.setVolume(ch.id, v),
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
                "Kaza Namazı & Orucu Planlayıcı",
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
                      const AlwaysStoppedAnimation<Color>(Color(0xFF64FFDA)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildKazaCard(
                      label: "Kalan Kaza Namazı",
                      value: _remainingPrayers,
                      onDec: () =>
                          _updateKaza(remainingPrayers: _remainingPrayers - 1),
                      onInc: () =>
                          _updateKaza(remainingPrayers: _remainingPrayers + 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKazaCard(
                      label: "Kalan Kaza Orucu",
                      value: _remainingFasts,
                      onDec: () =>
                          _updateKaza(remainingFasts: _remainingFasts - 1),
                      onInc: () =>
                          _updateKaza(remainingFasts: _remainingFasts + 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Günlük Hedef: $_dailyPace Vakit / Gün",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _updateKaza(dailyPace: _dailyPace - 1),
                        child: const BespokeVectorIcon(
                          type: BespokeIconType.minusCircle,
                          color: Color(0xFFFFE082),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _updateKaza(dailyPace: _dailyPace + 1),
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
          borderRadius: 26, emeraldGlow: true, padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Hatim İlerleme Takibi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFE082))),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(width: 74, height: 74, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: _completedJuz / 30, strokeWidth: 7, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Color(0xFF64FFDA))), SizedBox(width: 56, height: 56, child: CircularProgressIndicator(value: (_dailyReadJuz / _dailyJuzGoal).clamp(0.0, 1.0).toDouble(), strokeWidth: 3, backgroundColor: Colors.transparent, valueColor: const AlwaysStoppedAnimation(Color(0xFFFFE082))) )])),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_completedJuz.toString() + ' / 30 cüz tamamlandı', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4), Text('%' + ((_completedJuz / 30) * 100).toStringAsFixed(0) + ' toplam hatim ilerlemesi', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 5), Text('Bugün: ' + _dailyReadJuz.toString() + ' cüz • Hedef: ' + _dailyJuzGoal.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF64FFDA))),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _updateHatim(_completedJuz - 1), icon: const Icon(Icons.remove), label: const Text('Cüz azalt'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: _recordDailyJuz, icon: const Icon(Icons.add), label: const Text('Bugünkü cüzü kaydet'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64FFDA), foregroundColor: const Color(0xFF04221F)))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        GlassContainer(
          borderRadius: 26,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hicri Takvim: ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFE082),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Mübarek geceler ve Eyyâm-ı Biyd (Hicri 13, 14 ve 15. günler) sünnet orucu hatırlatıcıları vakit motoruna bağlıdır.",
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.45),
              ),
            ],
          ),
        ),
      ],
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
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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