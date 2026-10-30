import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/app_models.dart';
import '../../core/services/database_seeder.dart';
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
  bool _lockScreenHourlyEnabled = true;
  int _manualVerseOffset = 0;
  bool _alarmConfirmed = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _initHourlyLockScreenSystem();
    _hourlyChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_lockScreenHourlyEnabled && mounted) {
        setState(() {});
        NotificationAndWidgetService.instance.setHourlyLockScreenEnabled(
          enabled: true,
          manualOffset: _manualVerseOffset,
        );
      }
    });
  }

  Future<void> _initHourlyLockScreenSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('hourly_lock_screen_enabled') ?? true;
    final offset = prefs.getInt('hourly_verse_offset') ?? 0;
    if (mounted) {
      setState(() {
        _lockScreenHourlyEnabled = enabled;
        _manualVerseOffset = offset;
      });
    }
    if (enabled) {
      await NotificationAndWidgetService.instance.setHourlyLockScreenEnabled(
        enabled: true,
        manualOffset: offset,
      );
    }
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

    final activeShortVerse = NotificationAndWidgetService.instance
        .getActiveHourlyVerse(offset: _manualVerseOffset);
    final minutesToNextHour = 60 - DateTime.now().minute;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    palette.periodTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "${prayerState.selectedCity.name} • ${palette.spiritualSubtitle}",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 16,
              goldAccentBorder: true,
              onTap: () => LiquidGlassPaywallSheet.show(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BespokeVectorIcon(
                    type: BespokeIconType.crownGem,
                    color: Color(0xFFFFB300),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    premium.isPremium ? "VIP AKTİF" : "PREMIUM",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dairesel Su Dalgası Doluluk Efektli Liquid Glass Vakit Sayacı
        GlassContainer(
          borderRadius: 30,
          emeraldGlow: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: 195,
                height: 195,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _LiquidOrbGaugePainter(
                        progress: prayerState.cycleProgress,
                        wavePhase: _waveController.value,
                        accentColor: palette.accentGold,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${prayerState.nextPrayerName} Vaktine",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDuration(prayerState.timeUntilNext),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prayerState.selectedMaqam,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

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
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      borderRadius: 14,
                      onTap: () => _showLocationAndMethodModal(context, prayerState, prayerNotifier),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.gpsTarget,
                            color: Color(0xFF00E5FF),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Şehir & Makam",
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
                      borderRadius: 14,
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
                                ? const Color(0xFF00FF87)
                                : const Color(0xFFFFB300),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _alarmConfirmed ? "Ezan Alarmı Aktif" : "Sıfır Sapma Alarmı",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // iOS WIDGETKIT & KİLİT EKRANI SAATLİK KISA AYET SİSTEMİ
        GlassContainer(
          borderRadius: 28,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "iOS WIDGETKIT & KİLİT EKRANI SAATLİK AYET",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFF00FF87),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Her saat başı otomatik değişen 2-4 kelimelik öz ayet kartı",
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _lockScreenHourlyEnabled,
                    activeColor: const Color(0xFF00FF87),
                    onChanged: (val) async {
                      setState(() => _lockScreenHourlyEnabled = val);
                      await NotificationAndWidgetService.instance
                          .setHourlyLockScreenEnabled(
                        enabled: val,
                        manualOffset: _manualVerseOffset,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.45),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      activeShortVerse.arabicShort,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "\"${activeShortVerse.turkishShort}\"",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sonraki otomatik değişim: $minutesToNextHour dk sonra",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        Text(
                          "— ${activeShortVerse.reference}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00FF87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () async {
                        setState(() {
                          _manualVerseOffset++;
                          _lockScreenHourlyEnabled = true;
                        });
                        await NotificationAndWidgetService.instance
                            .setHourlyLockScreenEnabled(
                          enabled: true,
                          manualOffset: _manualVerseOffset,
                        );
                      },
                      child: const Center(
                        child: Text(
                          "Sonraki Kısa Ayete Geç",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00FF87),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 14,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () => _showIosLockScreenSimulator(context, activeShortVerse, palette),
                      child: const Center(
                        child: Text(
                          "Kilit Ekranı Önizleme",
                          style: TextStyle(
                            fontSize: 12,
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
        const SizedBox(height: 16),

        GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hyper-Vibrant Atmosfer Küreleri (Vakit Önizleme)",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildShaderChip("Canlı Vakit", null, prayerNotifier),
                    _buildShaderChip("İmsak", PrayerPeriod.imsak, prayerNotifier),
                    _buildShaderChip("Öğle", PrayerPeriod.ogle, prayerNotifier),
                    _buildShaderChip("Akşam", PrayerPeriod.aksam, prayerNotifier),
                    _buildShaderChip("Yatsı", PrayerPeriod.yatsi, prayerNotifier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIosLockScreenSimulator(
    BuildContext context,
    HourlyShortVerse verse,
    LiquidGlassPalette palette,
  ) {
    final clockFmt = DateFormat('HH:mm').format(DateTime.now());
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "LockScreenPreview",
      pageBuilder: (ctx, _, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: LiquidMeshBackground(
            palette: palette,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  children: [
                    const Text(
                      "iOS 18 WIDGETKIT KİLİT EKRANI GÖRÜNÜMÜ",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00FF87),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      clockFmt,
                      style: const TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // iOS AccessoryRectangular Widget Kartı
                    GlassContainer(
                      borderRadius: 24,
                      emeraldGlow: true,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "İLAHİ TEFEKKÜR • SAATLİK KISA AYET",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FF87),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              verse.arabicShort,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFE082),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\"${verse.turkishShort}\"",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "— ${verse.reference}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        "Önizlemeyi Kapat",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
            ? palette.accentGold.withOpacity(0.24)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? palette.accentGold : Colors.white12,
          width: 0.9,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? palette.accentGold : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildShaderChip(
    String label,
    PrayerPeriod? period,
    PrayerEngineNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => notifier.setManualPeriodPreview(period),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
          borderRadius: 28,
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                "Küresel Şehir, GPS & Makam Ayarları",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                borderRadius: 14,
                emeraldGlow: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: () {
                  notifier.detectGpsLocation();
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BespokeVectorIcon(
                      type: BespokeIconType.gpsTarget,
                      color: Color(0xFF00FF87),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Cihaz GPS Koordinatlarını Otomatik Algıla",
                      style: TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text("Hazır Küresel Merkezler:", style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(city.name, style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text("Ezan Makamı Seçimi:", style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
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

class _LiquidOrbGaugePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color accentColor;

  _LiquidOrbGaugePainter({
    required this.progress,
    required this.wavePhase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    final waterHeight = size.height * (1.0 - progress.clamp(0.14, 0.88));
    final wavePath = Path()..moveTo(0, size.height);
    wavePath.lineTo(0, waterHeight);

    for (double x = 0; x <= size.width; x += 6) {
      final y = waterHeight +
          math.sin((x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi)) * 7 +
          math.cos((x / size.width * 4 * math.pi) - (wavePhase * 2 * math.pi)) * 4;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withOpacity(0.45),
          const Color(0xFF00E5FF).withOpacity(0.18),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(wavePath, waterPaint);
    canvas.restore();

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = accentColor.withOpacity(0.80);
    canvas.drawCircle(center, radius - 1.5, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidOrbGaugePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
