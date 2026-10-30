import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/app_models.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../paywall/liquid_glass_paywall.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  Timer? _hourlyChecker;
  int _manualVerseOffset = 0;
  bool _alarmConfirmed = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _initSilentWidgetSync();
    _hourlyChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
        NotificationAndWidgetService.instance.syncHourlyVerseToWidget(
          manualOffset: _manualVerseOffset,
        );
      }
    });
  }

  Future<void> _initSilentWidgetSync() async {
    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getInt('hourly_verse_offset') ?? 0;
    if (mounted) {
      setState(() => _manualVerseOffset = offset);
    }
    await NotificationAndWidgetService.instance.syncHourlyVerseToWidget(
      manualOffset: offset,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _hourlyChecker?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.abs().toString().padLeft(2, '0');
    final m = (d.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds.abs() % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerEngineProvider);
    final prayerNotifier = ref.read(prayerEngineProvider.notifier);
    final premium = ref.watch(premiumServiceProvider);
    final palette = LiquidGlassPalette.forPeriod(prayerState.activePeriod);
    final timeFmt = DateFormat('HH:mm');
    final hijri = HijriCalendar.now();
    final gregorianStr = DateFormat('d MMMM yyyy').format(DateTime.now());

    final activeShortVerse = NotificationAndWidgetService.instance
        .getActiveHourlyVerse(offset: _manualVerseOffset);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 132),
      children: [
        // 1. Üst Başlık: Huzur & Tarih/Şehir
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Huzur",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${prayerState.selectedCity.name} • ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} ($gregorianStr)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              borderRadius: 18,
              goldAccentBorder: true,
              onTap: () => LiquidGlassPaywallSheet.show(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BespokeVectorIcon(
                    type: BespokeIconType.crownGem,
                    color: Color(0xFFFFE082),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    premium.isPremium ? "VIP AÇIK" : "PREMIUM",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Kesilmeyen Saf Kristal Dairesel Vakit Küresi ve 6 Vakit Çizelgesi
        GlassContainer(
          borderRadius: 32,
          emeraldGlow: true,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: 204,
                  height: 204,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _CrystalOrbGaugePainter(
                          progress: prayerState.cycleProgress,
                          wavePhase: _waveController.value,
                          accentColor: palette.crystalAccent,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${prayerState.nextPrayerName} Vaktine",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.78),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDuration(prayerState.timeUntilNext),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  palette.periodTitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.crystalAccent,
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
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimePillar("İmsak", timeFmt.format(prayerState.fajr),
                      prayerState.activePeriod == PrayerPeriod.imsak, palette),
                  _buildTimePillar("Güneş", timeFmt.format(prayerState.sunrise),
                      prayerState.activePeriod == PrayerPeriod.gunes, palette),
                  _buildTimePillar("Öğle", timeFmt.format(prayerState.dhuhr),
                      prayerState.activePeriod == PrayerPeriod.ogle, palette),
                  _buildTimePillar("İkindi", timeFmt.format(prayerState.asr),
                      prayerState.activePeriod == PrayerPeriod.ikindi, palette),
                  _buildTimePillar("Akşam", timeFmt.format(prayerState.maghrib),
                      prayerState.activePeriod == PrayerPeriod.aksam, palette),
                  _buildTimePillar("Yatsı", timeFmt.format(prayerState.isha),
                      prayerState.activePeriod == PrayerPeriod.yatsi, palette),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      borderRadius: 16,
                      onTap: () => _showLocationAndMethodModal(context, prayerState, prayerNotifier),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.gpsTarget,
                            color: Color(0xFF64FFDA),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Konum & Makam",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassContainer(
                      goldAccentBorder: true,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      borderRadius: 16,
                      onTap: () async {
                        await NotificationAndWidgetService.instance
                            .scheduleExactPrayerAlarm(
                          id: 101,
                          prayerName: prayerState.nextPrayerName,
                          prayerTime:
                              DateTime.now().add(prayerState.timeUntilNext),
                          maqam: prayerState.selectedMaqam,
                          preReminderMinutes: prayerState.preReminderMinutes,
                        );
                        if (mounted) {
                          setState(() => _alarmConfirmed = true);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.checkBadge,
                            color: _alarmConfirmed
                                ? const Color(0xFF64FFDA)
                                : const Color(0xFFFFE082),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _alarmConfirmed ? "Hatırlatıcı Açık" : "Vakit Hatırlatıcı",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Saatlik Huzur Ayeti Kartı (Doğal ve Manevi Tasarım)
        GlassContainer(
          borderRadius: 30,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Saatlik Huzur Ayeti",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                  Text(
                    activeShortVerse.reference,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  activeShortVerse.arabicShort,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFF8E1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "\"${activeShortVerse.turkishShort}\"",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      onTap: () async {
                        setState(() => _manualVerseOffset++);
                        await NotificationAndWidgetService.instance
                            .syncHourlyVerseToWidget(
                          manualOffset: _manualVerseOffset,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.refreshSpark,
                            color: Color(0xFF64FFDA),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Yenile",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64FFDA),
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
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      onTap: () => _showFullScreenInspiration(context, activeShortVerse, palette),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.expandFrame,
                            color: Color(0xFFFFE082),
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Tam Ekran",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFE082),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Vakit Atmosferi (Otomatik, Seher, Gün Ortası, Grup, Gece)
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vakit Atmosferi",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAtmosphereChip("Otomatik", null, prayerNotifier),
                    _buildAtmosphereChip("Seher", PrayerPeriod.imsak, prayerNotifier),
                    _buildAtmosphereChip("Gün Ortası", PrayerPeriod.ogle, prayerNotifier),
                    _buildAtmosphereChip("Grup", PrayerPeriod.aksam, prayerNotifier),
                    _buildAtmosphereChip("Gece", PrayerPeriod.yatsi, prayerNotifier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullScreenInspiration(
    BuildContext context,
    HourlyShortVerse verse,
    LiquidGlassPalette palette,
  ) {
    final clockFmt = DateFormat('HH:mm').format(DateTime.now());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "InspirationFullScreen",
      pageBuilder: (ctx, _, __) {
        return Scaffold(
          backgroundColor: palette.deepCosmicStart,
          body: LiquidMeshBackground(
            palette: palette,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  children: [
                    Text(
                      "Günün İlhamı",
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      clockFmt,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      borderRadius: 28,
                      emeraldGlow: true,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              verse.arabicShort,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFF8E1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "\"${verse.turkishShort}\"",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "— ${verse.reference}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64FFDA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 32),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        "Kapat",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFE082),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePillar(
      String label, String time, bool isActive, LiquidGlassPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.14)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? palette.crystalAccent.withOpacity(0.75)
              : Colors.white.withOpacity(0.10),
          width: 0.9,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? palette.crystalAccent : Colors.white60,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphereChip(
    String label,
    PrayerPeriod? period,
    PrayerEngineNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => notifier.setManualPeriodPreview(period),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showLocationAndMethodModal(
    BuildContext context,
    PrayerEngineState state,
    PrayerEngineNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return GlassContainer(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                "Şehir ve Ezan Makamı Seçimi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: 16,
                emeraldGlow: true,
                padding: const EdgeInsets.symmetric(vertical: 11),
                onTap: () {
                  notifier.detectGpsLocation();
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BespokeVectorIcon(
                      type: BespokeIconType.gpsTarget,
                      color: Color(0xFF64FFDA),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Bulunduğum Konumu Algıla",
                      style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text("Şehirler:", style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kGlobalCityPresets.map((city) {
                  return GestureDetector(
                    onTap: () {
                      notifier.setCity(city);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(city.name, style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text("Ezan Makamı:", style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  "Saba Makamı",
                  "Hicaz Makamı",
                  "Rast Makamı",
                  "Uşşak Makamı",
                  "Nahavend Makamı"
                ].map((m) {
                  return GestureDetector(
                    onTap: () {
                      notifier.setMaqam(m);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(m, style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CrystalOrbGaugePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color accentColor;

  _CrystalOrbGaugePainter({
    required this.progress,
    required this.wavePhase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    // Saf Kristal İç Yüzey
    final sphereBg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.1,
        colors: [
          Colors.white.withOpacity(0.14),
          Colors.white.withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sphereBg);

    // Akışkan Kristal Su Dalgası
    final waterHeight = size.height * (1.0 - progress.clamp(0.18, 0.84));
    final wavePath = Path()..moveTo(0, size.height);
    wavePath.lineTo(0, waterHeight);

    for (double x = 0; x <= size.width; x += 5) {
      final y = waterHeight +
          math.sin((x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi)) * 6 +
          math.cos((x / size.width * 4 * math.pi) - (wavePhase * 2 * math.pi)) * 3;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.32),
          const Color(0xFF00B0FF).withOpacity(0.10),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(wavePath, waterPaint);
    canvas.restore();

    // 3D Kristal Mercek Dış Çemberi
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.65),
          Colors.white.withOpacity(0.10),
          accentColor.withOpacity(0.55),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _CrystalOrbGaugePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
