import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_theme_service.dart';
import 'core/services/prayer_service.dart';
import 'core/services/quran_background_audio_service.dart';
import 'core/theme/glass_container.dart';
import 'core/theme/liquid_glass_theme.dart';
import 'features/dashboard/main_dashboard_screen.dart';
import 'features/hifz/hifz_academy_screen.dart';
import 'features/planner/daily_planner_screen.dart';
import 'features/qibla_and_extras/qibla_and_tools_screen.dart';
import 'features/sacred_texts/sacred_texts_screen.dart';
import 'features/sacred_texts/quran_audio_player_sheet.dart';
import 'features/tasbih/fluid_tasbih_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    providerApple: const AppleDeviceCheckProvider(),
  );
  await NotificationAndWidgetService.instance.initialize();
  runApp(const ProviderScope(child: HuzurApp()));
}

class HuzurApp extends ConsumerWidget {
  const HuzurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(prayerEngineProvider);
    final mode = ref.watch(huzurThemeModeProvider);
    final darkPalette = LiquidGlassPalette.forPeriod(prayer.activePeriod);
    final coalPalette = LiquidGlassPalette.coalForPeriod(prayer.activePeriod);
    return MaterialApp(
      title: 'Huzur',
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassPalette.buildTheme(coalPalette),
      darkTheme: LiquidGlassPalette.buildTheme(darkPalette),
      themeMode: mode,
      home: Builder(
        builder: (context) {
          final platformDark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          final useAmber = mode == ThemeMode.dark ||
              (mode == ThemeMode.system && platformDark);
          final palette = useAmber ? darkPalette : coalPalette;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: LiquidRootShell(palette: palette),
          );
        },
      ),
    );
  }
}

class LiquidRootShell extends ConsumerStatefulWidget {
  final LiquidGlassPalette palette;
  const LiquidRootShell({super.key, required this.palette});

  @override
  ConsumerState<LiquidRootShell> createState() => _LiquidRootShellState();
}

class _LiquidRootShellState extends ConsumerState<LiquidRootShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(quranAudioProvider);
    final audioNotifier = ref.read(quranAudioProvider.notifier);

    final pages = <Widget>[
      MainDashboardScreen(
        onSwitchTab: (idx) => setState(() => _currentIndex = idx),
      ),
      const SacredTextsScreen(),
      const FluidTasbihScreen(),
      const QiblaAndToolsScreen(),
      const HifzAcademyScreen(),
      const DailyPlannerScreen(),
    ];

    return Scaffold(
      extendBody: false,
      body: LiquidMeshBackground(
        palette: widget.palette,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Sayfa içerikleri alt barın üstünde biter; asla alt barın altına girip ezilmez!
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),

              // Arka plan Kur'ân tilaveti aktifken görünen Dinamik Mini Oynatıcı
              if (audioState.hasActiveSession)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                  child: GlassContainer(
                    borderRadius: 22,
                    emeraldGlow: true,
                    goldAccentBorder: true,
                    enableBlur: true,
                    blurSigma: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    onTap: () {
                      showQuranAudioPlayerSheet(context);
                    },
                    child: Row(
                      children: [
                        LiveSvgAudioVisualizer(
                          isPlaying: audioState.isPlaying,
                          color: const Color(0xFFFFA21A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${audioState.activeAyah!.surahName} • ${audioState.activeAyah!.numberInSurah}. Ayet",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFE082),
                                ),
                              ),
                              const Text(
                                "Mishary Rashid Al-Afasy • Arka Plan Tilaveti",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.skipToPrevious(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: BespokeVectorIcon(
                              type: BespokeIconType.skipPrev,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.togglePlayPause(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA21A)
                                  .withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: BespokeVectorIcon(
                              type: audioState.isPlaying
                                  ? BespokeIconType.pauseBars
                                  : BespokeIconType.playTriangle,
                              color: const Color(0xFFFFA21A),
                              size: 15,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.skipToNext(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: BespokeVectorIcon(
                              type: BespokeIconType.skipNext,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => audioNotifier.stop(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: BespokeVectorIcon(
                              type: BespokeIconType.closeCross,
                              color: Color(0xFFFFE082),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Alt Navigasyon Barı (Güçlü Bulanıklık & Koyu Kristal Zemin ile Korunmuş)
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.palette.deepCosmicMid.withValues(alpha: 0.62),
                          widget.palette.deepCosmicStart
                              .withValues(alpha: 0.78),
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 0.9,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildNavItem(
                                  0, "Huzur", BespokeIconType.crescentOrb),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                  1, "Kur'an", BespokeIconType.sacredScroll),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                  4, "Hıfz", BespokeIconType.checkBadge),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                5,
                                "Plan",
                                BespokeIconType.checkBadge,
                                materialIcon: Icons.event_note_outlined,
                              ),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                  2, "Zikir", BespokeIconType.tasbihRipple),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                  3, "Araçlar", BespokeIconType.qiblaStar),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, BespokeIconType iconType,
      {IconData? materialIcon}) {
    final selected = _currentIndex == index;
    final color = selected ? widget.palette.crystalAccent : Colors.white70;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (materialIcon != null)
              Icon(materialIcon, color: color, size: 20)
            else
              BespokeVectorIcon(type: iconType, color: color, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
