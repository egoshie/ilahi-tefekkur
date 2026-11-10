import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/app_theme_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../../core/theme/story_share_sheet.dart';
import '../esma/esmaul_husna_sheet.dart';
import '../ai_huzur/ai_huzur_entry_screen.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _waveController;
  Timer? _hourlyChecker;
  int _manualVerseOffset = 0;
  bool _alarmConfirmed = false;
  bool _widgetPinnedFeedback = false;
  int _lastWidgetHourSeed = -1;
  ProviderSubscription<PrayerEngineState>? _prayerScheduleSubscription;

  static const Map<int, String> _trHijriMonths = {
    1: 'Muharrem',
    2: 'Safer',
    3: 'Rebîülevvel',
    4: 'Rebîülâhir',
    5: 'Cemâziyelevvel',
    6: 'Cemâziyelâhir',
    7: 'Recep',
    8: 'Şaban',
    9: 'Ramazan',
    10: 'Şevval',
    11: 'Zilkade',
    12: 'Zilhicce',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _lastWidgetHourSeed = _currentHourSeed();
    _initSilentWidgetSync();
    _restorePrayerNotificationState();

    _prayerScheduleSubscription = ref.listenManual<PrayerEngineState>(
      prayerEngineProvider,
      (previous, next) {
        if (!_alarmConfirmed || previous == null) return;
        if (_prayerNotificationSettingsKey(previous) !=
            _prayerNotificationSettingsKey(next)) {
          unawaited(_refreshPrayerNotifications());
        }
      },
    );

    _hourlyChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
      final hourSeed = _currentHourSeed();
      if (hourSeed != _lastWidgetHourSeed) {
        _lastWidgetHourSeed = hourSeed;
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
    _lastWidgetHourSeed = _currentHourSeed();
    await NotificationAndWidgetService.instance.syncHourlyVerseToWidget(
      manualOffset: offset,
    );
  }

  Future<void> _restorePrayerNotificationState() async {
    final enabled = await NotificationAndWidgetService.instance
        .arePrayerNotificationsEnabled();

    if (!mounted || !enabled) return;

    setState(() => _alarmConfirmed = true);
    await _refreshPrayerNotifications();
  }

  String _prayerNotificationSettingsKey(PrayerEngineState state) {
    return [
      state.selectedCity.latitude,
      state.selectedCity.longitude,
      state.methodChoice.index,
      state.preReminderMinutes,
    ].join('|');
  }

  Future<bool> _applyPrayerNotifications({
    required bool requestPermission,
  }) async {
    final prayerState = ref.read(prayerEngineProvider);
    final upcoming = ref
        .read(prayerEngineProvider.notifier)
        .upcomingPrayerNotificationTimes(days: 5);

    final service = NotificationAndWidgetService.instance;

    try {
      if (requestPermission) {
        return await service.enablePrayerNotifications(
          prayerTimes: upcoming,
          maqam: prayerState.selectedMaqam,
          preReminderMinutes: prayerState.preReminderMinutes,
        );
      }

      return await service.refreshPrayerNotifications(
        prayerTimes: upcoming,
        maqam: prayerState.selectedMaqam,
        preReminderMinutes: prayerState.preReminderMinutes,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshPrayerNotifications() async {
    if (!_alarmConfirmed) return;
    await _applyPrayerNotifications(requestPermission: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _alarmConfirmed) {
      unawaited(_refreshPrayerNotifications());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prayerScheduleSubscription?.close();
    _waveController.dispose();
    _hourlyChecker?.cancel();
    super.dispose();
  }

  int _currentHourSeed() {
    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    return hourStart.millisecondsSinceEpoch ~/ 3600000;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.abs().toString().padLeft(2, '0');
    final m = (d.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds.abs() % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showThemePicker(BuildContext context) {
    final selectedMode = ref.read(huzurThemeModeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: GlassContainer(
              borderRadius: 28,
              enableBlur: true,
              blurSigma: 24,
              goldAccentBorder: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Görünüm ve Tema',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildThemeModeOption(
                    sheetContext,
                    ThemeMode.dark,
                    selectedMode,
                    'Koyu Amber',
                    'Füme zemin ve sıcak amber ışık',
                    Icons.dark_mode_rounded,
                  ),
                  _buildThemeModeOption(
                    sheetContext,
                    ThemeMode.system,
                    selectedMode,
                    'Cihaz Ayarı',
                    'iPhone görünüm ayarını takip et',
                    Icons.brightness_auto_rounded,
                  ),
                  _buildThemeModeOption(
                    sheetContext,
                    ThemeMode.light,
                    selectedMode,
                    'Aydınlık',
                    'Sıcak ve açık renkli görünüm',
                    Icons.light_mode_rounded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeModeOption(
    BuildContext sheetContext,
    ThemeMode mode,
    ThemeMode selectedMode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final selected = mode == selectedMode;
    const amber = Color(0xFFFFB52E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: amber.withValues(alpha: 0.16),
          onTap: () async {
            await ref.read(huzurThemeModeProvider.notifier).setMode(mode);
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
            }
          },
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? const [
                        Color(0xFF493516),
                        Color(0xFF241B10),
                      ]
                    : const [
                        Color(0xFF30261D),
                        Color(0xFF171411),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? amber : const Color(0xFF9D8870),
                width: selected ? 1.7 : 1.1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: amber.withValues(alpha: 0.16),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: amber.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DefaultTextStyle(
                        style: const TextStyle(color: Colors.white),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE6DCCF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? amber : Colors.white70,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                    'Huzur',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prayerState.selectedCity.name} • ${hijri.hDay} $hijriMonthTr ${hijri.hYear}',
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
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(10),
              goldAccentBorder: true,
              onTap: () => _showThemePicker(context),
              child: const Icon(
                Icons.palette_outlined,
                color: Color(0xFFFFA21A),
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
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
                    'Huzur Özel',
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
                                '${prayerState.nextPrayerName} Vaktine',
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
                  _buildTimePillar('İmsak', timeFmt.format(prayerState.fajr),
                      prayerState.activePeriod == PrayerPeriod.imsak, palette),
                  _buildTimePillar('Güneş', timeFmt.format(prayerState.sunrise),
                      prayerState.activePeriod == PrayerPeriod.gunes, palette),
                  _buildTimePillar('Öğle', timeFmt.format(prayerState.dhuhr),
                      prayerState.activePeriod == PrayerPeriod.ogle, palette),
                  _buildTimePillar('İkindi', timeFmt.format(prayerState.asr),
                      prayerState.activePeriod == PrayerPeriod.ikindi, palette),
                  _buildTimePillar('Akşam', timeFmt.format(prayerState.maghrib),
                      prayerState.activePeriod == PrayerPeriod.aksam, palette),
                  _buildTimePillar('Yatsı', timeFmt.format(prayerState.isha),
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
                            color: Color(0xFFFFA21A),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Şehir & Makam',
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
                        final messenger = ScaffoldMessenger.of(context);

                        if (_alarmConfirmed) {
                          await NotificationAndWidgetService.instance
                              .disablePrayerNotifications();
                          if (!mounted) return;
                          setState(() => _alarmConfirmed = false);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Namaz vakti bildirimleri kapatıldı.',
                              ),
                            ),
                          );
                          return;
                        }

                        final scheduled = await _applyPrayerNotifications(
                          requestPermission: true,
                        );
                        if (!mounted) return;
                        setState(() => _alarmConfirmed = scheduled);

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              scheduled
                                  ? '5 günlük namaz vakti ve yaklaşma bildirimleri açıldı.'
                                  : 'Bildirim izni alınamadı. iPhone Ayarları > Bildirimler > Huzur bölümünden ses ve bildirimleri açın.',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.checkBadge,
                            color: _alarmConfirmed
                                ? const Color(0xFFFFA21A)
                                : const Color(0xFFFFE082),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _alarmConfirmed
                                  ? 'Bildirimler Açık'
                                  : 'Vakit Bildirimleri',
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
                    'Günün İlhamı',
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
                      color: Color(0xFFFFA21A),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                '"${activeShortVerse.turkishShort}"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
                          forceAuto: true,
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.refreshSpark,
                            color: Color(0xFFFFA21A),
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Yenile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFA21A),
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
                        final pinSucceeded = await NotificationAndWidgetService
                            .instance
                            .pinCustomVerseToWidget(
                          arabic: activeShortVerse.arabicShort,
                          turkish: activeShortVerse.turkishShort,
                          reference: activeShortVerse.reference,
                        );
                        if (mounted) {
                          setState(() => _widgetPinnedFeedback = pinSucceeded);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: _widgetPinnedFeedback
                                ? BespokeIconType.checkBadge
                                : BespokeIconType.widgetSpark,
                            color: const Color(0xFFFFA21A),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _widgetPinnedFeedback
                                  ? "Widget'ta"
                                  : 'Widget Yap',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFA21A),
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
                              'Paylaş',
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
                          color: Color(0xFFFFA21A),
                          size: 20,
                        ),
                        Text(
                          '99 İsim',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFA21A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Esmaül Hüsna',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Anlamlar ve zikir hedefleri',
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
                              ? 'Kaldığım Yer'
                              : '${progress.favorites.length} Favori',
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
                          : 'İlahi Kitaplar',
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
                          ? 'Ayet / Bölüm ${progress.lastRead!.chapterOrAyah}'
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
        GlassContainer(
          borderRadius: 24,
          emeraldGlow: true,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    AiHuzurEntryScreen(onNavigateToTab: widget.onSwitchTab)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA21A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFFFA21A).withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFA21A),
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Huzur Dini Asistan",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text("Dini sorularını yapay zekâ ile keşfet",
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFFE082), size: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vakit Atmosferi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    _buildAtmosphereChip('Otomatik', null, prayerNotifier),
                    _buildAtmosphereChip(
                        'Seher', PrayerPeriod.imsak, prayerNotifier),
                    _buildAtmosphereChip(
                        'Gün Ortası', PrayerPeriod.ogle, prayerNotifier),
                    _buildAtmosphereChip(
                        'Grup', PrayerPeriod.aksam, prayerNotifier),
                    _buildAtmosphereChip(
                        'Gece', PrayerPeriod.yatsi, prayerNotifier),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final searchController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredCities = kGlobalCityPresets.where((city) {
              return city.name.toLowerCase().contains(query) ||
                  city.country.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: GlassContainer(
                borderRadius: 30,
                enableBlur: true,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFFFA21A),
                          size: 21,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Şehir ve Namaz Vakitleri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seçtiğin şehre göre namaz vakitleri ve kıble yönü hesaplanır.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      autofocus: false,
                      onChanged: (_) => setSheetState(() {}),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Şehir veya ülke ara...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFFFA21A),
                        ),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() {});
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFFA21A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassContainer(
                      borderRadius: 15,
                      emeraldGlow: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onTap: () {
                        notifier.detectGpsLocation();
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFFFFA21A),
                            size: 17,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Konumumu otomatik algıla',
                            style: TextStyle(
                              color: Color(0xFFFFA21A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Şehirler',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${filteredCities.length} sonuç',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 230,
                      child: filteredCities.isEmpty
                          ? const Center(
                              child: Text(
                                'Bu isimle eşleşen şehir bulunamadı.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = filteredCities[index];
                                final selected = city.name ==
                                        state.selectedCity.name &&
                                    city.country == state.selectedCity.country;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Material(
                                    color: selected
                                        ? const Color(0xFFFFA21A)
                                            .withValues(alpha: 0.13)
                                        : Colors.white.withValues(alpha: 0.045),
                                    borderRadius: BorderRadius.circular(13),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(13),
                                      onTap: () {
                                        notifier.setCity(city);
                                        Navigator.of(sheetContext).pop();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 13,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_city_rounded,
                                              size: 17,
                                              color: selected
                                                  ? const Color(0xFFFFA21A)
                                                  : Colors.white60,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    city.name,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: selected
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      color: selected
                                                          ? const Color(
                                                              0xFFFFA21A)
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                  Text(
                                                    city.country,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (selected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFFFFA21A),
                                                size: 19,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ezan Makamı',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        'Saba Makamı',
                        'Hicaz Makamı',
                        'Rast Makamı',
                        'Uşşak Makamı',
                        'Nahavend Makamı',
                      ].map((maqam) {
                        final selected = maqam == state.selectedMaqam;
                        return ChoiceChip(
                          label: Text(
                            maqam,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: selected
                                  ? const Color(0xFF06251E)
                                  : Colors.white,
                            ),
                          ),
                          selected: selected,
                          selectedColor: const Color(0xFFFFA21A),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFFFA21A)
                                : Colors.white24,
                          ),
                          onSelected: (_) {
                            notifier.setMaqam(maqam);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
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
          const Color(0xFFFFB74D).withValues(alpha: 0.14),
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
