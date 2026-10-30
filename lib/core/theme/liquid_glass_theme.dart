import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

enum PrayerPeriod { imsak, gunes, ogle, ikindi, aksam, yatsi }

class LiquidGlassPalette {
  final Color primaryBg;
  final Color secondaryBg;
  final Color orbEmerald;
  final Color orbTurquoise;
  final Color orbAmber;
  final Color orbSapphire;
  final Color accentGold;
  final Color specularHighlight;
  final String periodTitle;
  final String spiritualSubtitle;

  const LiquidGlassPalette({
    required this.primaryBg,
    required this.secondaryBg,
    required this.orbEmerald,
    required this.orbTurquoise,
    required this.orbAmber,
    required this.orbSapphire,
    required this.accentGold,
    required this.specularHighlight,
    required this.periodTitle,
    required this.spiritualSubtitle,
  });

  static LiquidGlassPalette forPeriod(PrayerPeriod period) {
    switch (period) {
      case PrayerPeriod.imsak:
        return const LiquidGlassPalette(
          primaryBg: Color(0xFF04071A),
          secondaryBg: Color(0xFF0E1438),
          orbEmerald: Color(0xFF00FF87),
          orbTurquoise: Color(0xFF00E5FF),
          orbAmber: Color(0xFFFFB300),
          orbSapphire: Color(0xFF1A237E),
          accentGold: Color(0xFF00E5FF),
          specularHighlight: Color(0xFF80F8FF),
          periodTitle: "İmsak & Seher Vakti",
          spiritualSubtitle: "Safir gece ve seher turkuazı",
        );
      case PrayerPeriod.gunes:
        return const LiquidGlassPalette(
          primaryBg: Color(0xFF081026),
          secondaryBg: Color(0xFF1A1B4B),
          orbEmerald: Color(0xFF00E676),
          orbTurquoise: Color(0xFF00E5FF),
          orbAmber: Color(0xFFFFB300),
          orbSapphire: Color(0xFF283593),
          accentGold: Color(0xFFFFB300),
          specularHighlight: Color(0xFFFFE082),
          periodTitle: "İşrak & Doğuş Vakti",
          spiritualSubtitle: "Şafak kehribarı ve nur yansıması",
        );
      case PrayerPeriod.ogle:
        return const LiquidGlassPalette(
          primaryBg: Color(0xFF021324),
          secondaryBg: Color(0xFF072B47),
          orbEmerald: Color(0xFF00FF87),
          orbTurquoise: Color(0xFF00E5FF),
          orbAmber: Color(0xFFFFCA28),
          orbSapphire: Color(0xFF1A237E),
          accentGold: Color(0xFF00FF87),
          specularHighlight: Color(0xFFA7FFEB),
          periodTitle: "Öğle Vakti",
          spiritualSubtitle: "Berrak turkuaz ve zümrüt parıltısı",
        );
      case PrayerPeriod.ikindi:
        return const LiquidGlassPalette(
          primaryBg: Color(0xFF0A0F24),
          secondaryBg: Color(0xFF1E193B),
          orbEmerald: Color(0xFF00E5FF),
          orbTurquoise: Color(0xFF00FF87),
          orbAmber: Color(0xFFFFB300),
          orbSapphire: Color(0xFF1A237E),
          accentGold: Color(0xFFFFB300),
          specularHighlight: Color(0xFFFFE57F),
          periodTitle: "İkindi Vakti",
          spiritualSubtitle: "Asr kehribarı ve derin safir",
        );
      case PrayerPeriod.aksam:
        return const LiquidGlassPalette(
          primaryBg: Color(0xFF12061F),
          secondaryBg: Color(0xFF280E3B),
          orbEmerald: Color(0xFFFFB300),
          orbTurquoise: Color(0xFF00E5FF),
          orbAmber: Color(0xFFFF6D00),
          orbSapphire: Color(0xFF1A237E),
          accentGold: Color(0xFFFFB300),
          specularHighlight: Color(0xFFFFD180),
          periodTitle: "Akşam Vakti",
          spiritualSubtitle: "Ufuk kehribarı ve safir yansıma",
        );
      case PrayerPeriod.yatsi:
        return const LiquidGlassPalette(
          primaryBg: Color(0xFF020612),
          secondaryBg: Color(0xFF071A24),
          orbEmerald: Color(0xFF00FF87),
          orbTurquoise: Color(0xFF00E5FF),
          orbAmber: Color(0xFFFFB300),
          orbSapphire: Color(0xFF1A237E),
          accentGold: Color(0xFF00FF87),
          specularHighlight: Color(0xFF84FFFF),
          periodTitle: "Yatsı & Gece Tefekkürü",
          spiritualSubtitle: "Gece safiri ve canlı zümrüt küreler",
        );
    }
  }

  static ThemeData buildTheme(LiquidGlassPalette palette) {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.primaryBg,
      colorScheme: ColorScheme.dark(
        primary: palette.accentGold,
        secondary: palette.orbTurquoise,
        surface: palette.secondaryBg,
      ),
      textTheme: baseText.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

class LiquidMeshBackground extends StatefulWidget {
  final LiquidGlassPalette palette;
  final Widget child;

  const LiquidMeshBackground({
    super.key,
    required this.palette,
    required this.child,
  });

  @override
  State<LiquidMeshBackground> createState() => _LiquidMeshBackgroundState();
}

class _LiquidMeshBackgroundState extends State<LiquidMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _HyperVibrantOrbPainter(
                progress: _controller.value,
                palette: widget.palette,
              ),
              size: Size.infinite,
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
          child: Container(color: Colors.transparent),
        ),
        widget.child,
      ],
    );
  }
}

class _HyperVibrantOrbPainter extends CustomPainter {
  final double progress;
  final LiquidGlassPalette palette;

  _HyperVibrantOrbPainter({
    required this.progress,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.primaryBg,
          palette.secondaryBg,
          const Color(0xFF040A18),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final angle = progress * 2 * math.pi;

    // 1. Parlak Zümrüt Küre (#00FF87)
    final cEmerald = Offset(
      size.width * (0.20 + 0.25 * math.sin(angle)),
      size.height * (0.18 + 0.14 * math.cos(angle * 1.2)),
    );
    _drawGlowOrb(canvas, cEmerald, size.width * 0.58, palette.orbEmerald.withOpacity(0.52));

    // 2. Parlak Turkuaz Küre (#00E5FF)
    final cTurquoise = Offset(
      size.width * (0.80 + 0.18 * math.cos(angle * 0.9)),
      size.height * (0.42 + 0.18 * math.sin(angle * 1.3)),
    );
    _drawGlowOrb(canvas, cTurquoise, size.width * 0.62, palette.orbTurquoise.withOpacity(0.48));

    // 3. Altın Kehribar Küre (#FFB300)
    final cAmber = Offset(
      size.width * (0.32 + 0.24 * math.sin(angle * 1.4 + 1.1)),
      size.height * (0.76 + 0.14 * math.cos(angle * 0.8)),
    );
    _drawGlowOrb(canvas, cAmber, size.width * 0.55, palette.orbAmber.withOpacity(0.42));

    // 4. Derin Safir Küre (#1A237E)
    final cSapphire = Offset(
      size.width * (0.70 + 0.20 * math.sin(angle * 0.7 + 2.0)),
      size.height * (0.85 + 0.10 * math.sin(angle)),
    );
    _drawGlowOrb(canvas, cSapphire, size.width * 0.70, palette.orbSapphire.withOpacity(0.65));
  }

  void _drawGlowOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withOpacity(0.35),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _HyperVibrantOrbPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.palette != palette;
  }
}

enum BespokeIconType {
  crescentOrb,
  sacredScroll,
  tasbihRipple,
  qiblaStar,
  crownGem,
  playTriangle,
  stopSquare,
  lockShield,
  bookmarkStar,
  audioWave,
  gpsTarget,
  shareCard,
  checkBadge,
  plusCircle,
  minusCircle,
}

class BespokeVectorIcon extends StatelessWidget {
  final BespokeIconType type;
  final Color color;
  final double size;

  const BespokeVectorIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 22,
  });

  String _svgForType(String hexColor) {
    switch (type) {
      case BespokeIconType.crownGem:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 18H21M4 15L2 7L8 11L12 4L16 11L22 7L20 15H4Z" stroke="$hexColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.playTriangle:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <polygon points="6,4 20,12 6,20" fill="$hexColor"/>
</svg>''';
      case BespokeIconType.stopSquare:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="6" width="12" height="12" rx="2" fill="$hexColor"/>
</svg>''';
      case BespokeIconType.lockShield:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="5" y="11" width="14" height="10" rx="3" stroke="$hexColor" stroke-width="1.8"/>
  <path d="M8 11V7C8 4.79086 9.79086 3 12 3C14.2091 3 16 4.79086 16 7V11" stroke="$hexColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.bookmarkStar:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="$hexColor" stroke-width="1.8" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.gpsTarget:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="7" stroke="$hexColor" stroke-width="1.8"/>
  <circle cx="12" cy="12" r="2.5" fill="$hexColor"/>
  <path d="M12 2V5M12 19V22M2 12H5M19 12H22" stroke="$hexColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.shareCard:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="18" cy="5" r="3" stroke="$hexColor" stroke-width="1.8"/>
  <circle cx="6" cy="12" r="3" stroke="$hexColor" stroke-width="1.8"/>
  <circle cx="18" cy="19" r="3" stroke="$hexColor" stroke-width="1.8"/>
  <path d="M8.59 13.51L15.42 17.49M15.41 6.51L8.59 10.49" stroke="$hexColor" stroke-width="1.8"/>
</svg>''';
      case BespokeIconType.checkBadge:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="$hexColor" stroke-width="1.8"/>
  <path d="M8 12.5L10.8 15.3L16.5 9.5" stroke="$hexColor" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.plusCircle:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="$hexColor" stroke-width="1.8"/>
  <path d="M12 8V16M8 12H16" stroke="$hexColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.minusCircle:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="$hexColor" stroke-width="1.8"/>
  <path d="M8 12H16" stroke="$hexColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.audioWave:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 10V14M8 6V18M12 3V21M16 7V17M20 10V14" stroke="$hexColor" stroke-width="2.0" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.crescentOrb:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z" stroke="$hexColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.sacredScroll:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2 4H8C10.2091 4 12 5.79086 12 8V20C12 18.3431 10.6569 17 9 17H2V4Z" stroke="$hexColor" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M22 4H16C13.7909 4 12 5.79086 12 8V20C12 18.3431 13.3431 17 15 17H22V4Z" stroke="$hexColor" stroke-width="1.8" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.tasbihRipple:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="3" fill="$hexColor"/>
  <circle cx="12" cy="12" r="7" stroke="$hexColor" stroke-width="1.6"/>
  <circle cx="12" cy="12" r="10.5" stroke="$hexColor" stroke-width="1.2" stroke-dasharray="3 3"/>
</svg>''';
      case BespokeIconType.qiblaStar:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <polygon points="12,2 15.5,10.5 22,12 15.5,13.5 12,22 8.5,13.5 2,12 8.5,10.5" stroke="$hexColor" stroke-width="1.7" stroke-linejoin="round"/>
  <circle cx="12" cy="12" r="2" fill="$hexColor"/>
</svg>''';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    return SvgPicture.string(
      _svgForType(hex),
      width: size,
      height: size,
    );
  }
}

class LiveSvgAudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const LiveSvgAudioVisualizer({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFF00FF87),
  });

  @override
  State<LiveSvgAudioVisualizer> createState() => _LiveSvgAudioVisualizerState();
}

class _LiveSvgAudioVisualizerState extends State<LiveSvgAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return BespokeVectorIcon(
        type: BespokeIconType.audioWave,
        color: Colors.white38,
        size: 22,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(38, 22),
          painter: _WaveBarsPainter(
            phase: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _WaveBarsPainter extends CustomPainter {
  final double phase;
  final Color color;

  _WaveBarsPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const count = 6;
    final spacing = size.width / (count + 1);
    for (int i = 0; i < count; i++) {
      final x = spacing * (i + 1);
      final wave = (math.sin((phase * 2 * math.pi) + (i * 1.1)) + 1.0) / 2.0;
      final barHeight = 5.0 + (size.height - 6.0) * wave;
      final top = (size.height - barHeight) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveBarsPainter oldDelegate) => true;
}
