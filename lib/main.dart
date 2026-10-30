import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/services/prayer_service.dart';
import 'core/theme/glass_container.dart';
import 'core/theme/liquid_glass_theme.dart';
import 'features/dashboard/main_dashboard_screen.dart';
import 'features/paywall/liquid_glass_paywall.dart';
import 'features/qibla_and_extras/qibla_and_tools_screen.dart';
import 'features/sacred_texts/sacred_texts_screen.dart';
import 'features/tasbih/fluid_tasbih_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await NotificationAndWidgetService.instance.initialize();
  runApp(const ProviderScope(child: HuzurApp()));
}

class HuzurApp extends ConsumerWidget {
  const HuzurApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerEngineProvider);
    final palette = LiquidGlassPalette.forPeriod(prayerState.activePeriod);

    return MaterialApp(
      title: 'Huzur',
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassPalette.buildTheme(palette),
      home: LiquidRootShell(palette: palette),
    );
  }
}

class LiquidRootShell extends StatefulWidget {
  final LiquidGlassPalette palette;
  const LiquidRootShell({super.key, required this.palette});

  @override
  State<LiquidRootShell> createState() => _LiquidRootShellState();
}

class _LiquidRootShellState extends State<LiquidRootShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MainDashboardScreen(),
    SacredTextsScreen(),
    FluidTasbihScreen(),
    QiblaAndToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LiquidMeshBackground(
        palette: widget.palette,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: GlassContainer(
            borderRadius: 30,
            enableBlur: true,
            blurSigma: 22,
            emeraldGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(0, "Huzur", BespokeIconType.crescentOrb),
                ),
                Expanded(
                  child: _buildNavItem(1, "Kitaplar", BespokeIconType.sacredScroll),
                ),
                Expanded(
                  child: _buildNavItem(2, "Zikirmatik", BespokeIconType.tasbihRipple),
                ),
                Expanded(
                  child: _buildNavItem(3, "Kıble & Ses", BespokeIconType.qiblaStar),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => LiquidGlassPaywallSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFE082).withOpacity(0.55),
                        width: 0.9,
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BespokeVectorIcon(
                          type: BespokeIconType.crownGem,
                          color: Color(0xFFFFE082),
                          size: 17,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Özel",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, BespokeIconType iconType) {
    final selected = _currentIndex == index;
    final color = selected ? widget.palette.crystalAccent : Colors.white60;

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
          color: selected ? Colors.white.withOpacity(0.11) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
