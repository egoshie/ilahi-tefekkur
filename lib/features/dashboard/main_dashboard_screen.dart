import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../../core/theme/story_share_sheet.dart';
import '../esma/esmaul_husna_sheet.dart';
import '../paywall/liquid_glass_paywall.dart';
class MainDashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const MainDashboardScreen({
    super.key,
    this.onSwitchTab,
  });

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
  bool _widgetPinnedFeedback = false;

  static const Map<int, String> _trHijriMonths = {
    1: "Muharrem",
    2: "Safer",
    3: "Rebîülevvel",
    4: "Rebîülâhir",
    5: "Cemâziyelevvel",
    6: "Cemâziyelâhir",
    7: "Recep",
    8: "Şaban",
    9: "Ramazan",
    10: "Şevval",
    11: "Zilkade",
    12: "Zilhicce",
  };

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
    final progress = ref.watch(userProgressProvider);
    final palette = LiquidGlassPalette.forPeriod(prayerState.activePeriod);
    final timeFmt = DateFormat('HH:mm');
    final hijri = HijriCalendar.now();
    final hijriMonthTr = _trHijriMonths[hijri.hMonth] ?? hijri.longMonthName;

    final activeShortVerse = NotificationAndWidgetService.instance
        .getActiveHourlyVerse(offset: _manualVerseOffset);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      children: [
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
                    "${prayerState.selectedCity.name} • ${hijri.hDay} $hijriMonthTr ${hijri.hYear}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              borderRadius: 18,
              goldAccentBorder: true,
              onTap: () => LiquidGlassPaywallSheet.show(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BespokeVectorIcon(
                    type: BespokeIconType.crownGem,
                    color: Color(0xFFFFE082),
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Huzur Özel",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: 32,
          emeraldGlow: true,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
          child: Column(
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 196,
                  height: 196,
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
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDuration(prayerState.timeUntilNext),
                                style: const TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  palette.periodTitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 10,
                      ),
                      borderRadius: 16,
                      onTap: () => _showLocationAndMethodModal(
                        context,
                        prayerState,
                        prayerNotifier,
                      ),
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
                              "Şehir & Makam",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 10,
                      ),
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
                              _alarmConfirmed
                                  ? "Hatırlatıcı Açık"
                                  : "Vakit Hatırlatıcı",
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
        GlassContainer(
          borderRadius: 30,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(20),
          onTap: () => HuzurStoryShareSheet.show(
            context,
            arabic: activeShortVerse.arabicShort,
            turkish: activeShortVerse.turkishShort,
            reference: activeShortVerse.reference,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Günün İlhamı",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                  Text(
                    activeShortVerse.reference,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  activeShortVerse.arabicShort,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 25,
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
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  height: 1.42,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 15,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () async {
                        setState(() {
                          _manualVerseOffset++;
                          _widgetPinnedFeedback = false;
                        });
                        await NotificationAndWidgetService.instance
                            .syncHourlyVerseToWidget(
                          manualOffset: _manualVerseOffset,
                        );
                        if (mounted) setState(() {});
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.refreshSpark,
                            color: Color(0xFF64FFDA),
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Yenile",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64FFDA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 15,
                      emeraldGlow: _widgetPinnedFeedback,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await NotificationAndWidgetService.instance
                            .pinCustomVerseToWidget(
                          arabic: activeShortVerse.arabicShort,
                          turkish: activeShortVerse.turkishShort,
                          reference: activeShortVerse.reference,
                        );
                        if (mounted) {
                          setState(() => _widgetPinnedFeedback = true);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: _widgetPinnedFeedback
                                ? BespokeIconType.checkBadge
                                : BespokeIconType.widgetSpark,
                            color: const Color(0xFF64FFDA),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _widgetPinnedFeedback
                                  ? "Widget'ta"
                                  : "Widget Yap",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64FFDA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 15,
                      goldAccentBorder: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () => HuzurStoryShareSheet.show(
                        context,
                        arabic: activeShortVerse.arabicShort,
                        turkish: activeShortVerse.turkishShort,
                        reference: activeShortVerse.reference,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.instagramStory,
                            color: Color(0xFFFFE082),
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Paylaş",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
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
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                borderRadius: 22,
                emeraldGlow: true,
                padding: const EdgeInsets.all(16),
                onTap: () => EsmaulHusnaSheet.show(
                  context,
                  onNavigateToTasbih: () => widget.onSwitchTab?.call(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BespokeVectorIcon(
                          type: BespokeIconType.esmaGrid,
                          color: Color(0xFF64FFDA),
                          size: 20,
                        ),
                        Text(
                          "99 İsim",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64FFDA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Esmaül Hüsna",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Anlamlar ve zikir hedefleri",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassContainer(
                borderRadius: 22,
                goldAccentBorder: true,
                padding: const EdgeInsets.all(16),
                onTap: () => widget.onSwitchTab?.call(1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const BespokeVectorIcon(
                          type: BespokeIconType.sacredScroll,
                          color: Color(0xFFFFE082),
                          size: 20,
                        ),
                        Text(
                          progress.lastRead != null
                              ? "Kaldığım Yer"
                              : "${progress.favorites.length} Favori",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      progress.lastRead != null
                          ? progress.lastRead!.title
                          : "İlahi Kitaplar",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress.lastRead != null
                          ? "Ayet / Bölüm ${progress.lastRead!.chapterOrAyah}"
                          : "Kur'ân, Tevrat ve İncil",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vakit Atmosferi",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    _buildAtmosphereChip("Otomatik", null, prayerNotifier),
                    _buildAtmosphereChip(
                        "Seher", PrayerPeriod.imsak, prayerNotifier),
                    _buildAtmosphereChip(
                        "Gün Ortası", PrayerPeriod.ogle, prayerNotifier),
                    _buildAtmosphereChip(
                        "Grup", PrayerPeriod.aksam, prayerNotifier),
                    _buildAtmosphereChip(
                        "Gece", PrayerPeriod.yatsi, prayerNotifier),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),


      ],
    );
  }

  Widget _buildTimePillar(
    String label,
    String time,
    bool isActive,
    LiquidGlassPalette palette,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? palette.crystalAccent.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.0,
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 0.9,
            ),
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
          enableBlur: true,
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
                      "Bulunduğum Şehri Otomatik Algıla",
                      style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Şehirler:",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        city.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                "Ezan Makamı:",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
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

    final sphereBg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.1,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sphereBg);

    final waterHeight = size.height * (1.0 - progress.clamp(0.18, 0.84));
    final wavePath = Path()..moveTo(0, size.height);
    wavePath.lineTo(0, waterHeight);

    for (double x = 0; x <= size.width; x += 6) {
      final y = waterHeight +
          math.sin((x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi)) *
              5.5 +
          math.cos((x / size.width * 4 * math.pi) - (wavePhase * 2 * math.pi)) *
              2.5;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.38),
          const Color(0xFF00E5FF).withValues(alpha: 0.14),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(wavePath, waterPaint);
    canvas.restore();

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.15),
          accentColor.withValues(alpha: 0.65),
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
