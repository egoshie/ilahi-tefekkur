import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

enum PrayerPeriod { imsak, gunes, ogle, ikindi, aksam, yatsi }

class LiquidGlassPalette {
  final Color deepCosmicStart;
  final Color deepCosmicMid;
  final Color deepCosmicEnd;
  final Color auroraPrimary;
  final Color auroraSecondary;
  final Color crystalAccent;
  final Color specularHighlight;
  final String periodTitle;
  final String spiritualSubtitle;

  const LiquidGlassPalette({
    required this.deepCosmicStart,
    required this.deepCosmicMid,
    required this.deepCosmicEnd,
    required this.auroraPrimary,
    required this.auroraSecondary,
    required this.crystalAccent,
    required this.specularHighlight,
    required this.periodTitle,
    required this.spiritualSubtitle,
  });

  static LiquidGlassPalette forPeriod(PrayerPeriod period) {
    switch (period) {
      case PrayerPeriod.imsak:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF030914),
          deepCosmicMid: Color(0xFF071B2E),
          deepCosmicEnd: Color(0xFF0A2838),
          auroraPrimary: Color(0xFF64FFDA),
          auroraSecondary: Color(0xFF40C4FF),
          crystalAccent: Color(0xFF80CBC4),
          specularHighlight: Color(0xFFE0F7FA),
          periodTitle: "Seher Vakti",
          spiritualSubtitle: "Dingin seher serinliği",
        );
      case PrayerPeriod.gunes:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF040B18),
          deepCosmicMid: Color(0xFF092230),
          deepCosmicEnd: Color(0xFF0F313A),
          auroraPrimary: Color(0xFFFFD54F),
          auroraSecondary: Color(0xFF64FFDA),
          crystalAccent: Color(0xFFFFE082),
          specularHighlight: Color(0xFFFFF8E1),
          periodTitle: "İşrak Vakti",
          spiritualSubtitle: "Sabah aydınlığı ve taze nefes",
        );
      case PrayerPeriod.ogle:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF030A14),
          deepCosmicMid: Color(0xFF07222B),
          deepCosmicEnd: Color(0xFF0A323A),
          auroraPrimary: Color(0xFF64FFDA),
          auroraSecondary: Color(0xFF18FFFF),
          crystalAccent: Color(0xFF64FFDA),
          specularHighlight: Color(0xFFE0F2F1),
          periodTitle: "Gün Ortası",
          spiritualSubtitle: "Berrak su kristali dinginliği",
        );
      case PrayerPeriod.ikindi:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF040914),
          deepCosmicMid: Color(0xFF081E28),
          deepCosmicEnd: Color(0xFF0C2B34),
          auroraPrimary: Color(0xFFFFD54F),
          auroraSecondary: Color(0xFF64FFDA),
          crystalAccent: Color(0xFFFFE082),
          specularHighlight: Color(0xFFFFECB3),
          periodTitle: "İkindi Vakti",
          spiritualSubtitle: "Asr sükûneti ve tefekkür",
        );
      case PrayerPeriod.aksam:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF040814),
          deepCosmicMid: Color(0xFF091B29),
          deepCosmicEnd: Color(0xFF0E2933),
          auroraPrimary: Color(0xFFFFAB40),
          auroraSecondary: Color(0xFF64FFDA),
          crystalAccent: Color(0xFFFFD180),
          specularHighlight: Color(0xFFFFE0B2),
          periodTitle: "Grup Vakti",
          spiritualSubtitle: "Ufuk kızıllığı ve akşam huzuru",
        );
      case PrayerPeriod.yatsi:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF030914),
          deepCosmicMid: Color(0xFF071E26),
          deepCosmicEnd: Color(0xFF0A2E36),
          auroraPrimary: Color(0xFF64FFDA),
          auroraSecondary: Color(0xFF00B0FF),
          crystalAccent: Color(0xFF64FFDA),
          specularHighlight: Color(0xFFB2DFDB),
          periodTitle: "Gece Vakti",
          spiritualSubtitle: "Derin gece ve kalp sükûneti",
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
      scaffoldBackgroundColor: palette.deepCosmicStart,
      colorScheme: ColorScheme.dark(
        primary: palette.crystalAccent,
        secondary: palette.auroraPrimary,
        surface: palette.deepCosmicMid,
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
      duration: const Duration(seconds: 24),
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
              painter: _AuroraCosmicPainter(
                progress: _controller.value,
                palette: widget.palette,
              ),
              size: Size.infinite,
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: const SizedBox.expand(),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraCosmicPainter extends CustomPainter {
  final double progress;
  final LiquidGlassPalette palette;

  _AuroraCosmicPainter({
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
          palette.deepCosmicStart,
          palette.deepCosmicMid,
          palette.deepCosmicEnd,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final angle = progress * 2 * math.pi;

    // İpeksi Aurora Işık Katmanı 1
    final center1 = Offset(
      size.width * (0.28 + 0.18 * math.sin(angle)),
      size.height * (0.20 + 0.10 * math.cos(angle * 1.1)),
    );
    _drawSilkyAurora(
      canvas,
      center1,
      size.width * 0.65,
      palette.auroraPrimary.withOpacity(0.18),
    );

    // İpeksi Aurora Işık Katmanı 2
    final center2 = Offset(
      size.width * (0.76 + 0.15 * math.cos(angle * 0.8)),
      size.height * (0.52 + 0.12 * math.sin(angle * 1.2)),
    );
    _drawSilkyAurora(
      canvas,
      center2,
      size.width * 0.60,
      palette.auroraSecondary.withOpacity(0.14),
    );

    // İpeksi Aurora Işık Katmanı 3
    final center3 = Offset(
      size.width * (0.45 + 0.20 * math.sin(angle * 0.9 + 1.4)),
      size.height * (0.82 + 0.08 * math.cos(angle)),
    );
    _drawSilkyAurora(
      canvas,
      center3,
      size.width * 0.70,
      palette.crystalAccent.withOpacity(0.12),
    );

    // Su Kırılması İnce Kristal Dalgalar
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.05);

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final baseY = size.height * (0.24 + i * 0.26);
      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 20) {
        final y = baseY +
            math.sin((x / size.width * 2 * math.pi) + angle + i) * 16 +
            math.cos((x / size.width * 3 * math.pi) - angle) * 6;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, ribbonPaint);
    }
  }

  void _drawSilkyAurora(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraCosmicPainter oldDelegate) {
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
  refreshSpark,
  expandFrame,
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
  <path d="M3 18H21M4 15L2 7L8 11L12 4L16 11L22 7L20 15H4Z" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.playTriangle:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <polygon points="6,4 20,12 6,20" fill="$hexColor"/>
</svg>''';
      case BespokeIconType.stopSquare:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="6" width="12" height="12" rx="2.5" fill="$hexColor"/>
</svg>''';
      case BespokeIconType.lockShield:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="5" y="11" width="14" height="10" rx="3" stroke="$hexColor" stroke-width="1.7"/>
  <path d="M8 11V7C8 4.79086 9.79086 3 12 3C14.2091 3 16 4.79086 16 7V11" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.bookmarkStar:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="$hexColor" stroke-width="1.7" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.gpsTarget:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="7" stroke="$hexColor" stroke-width="1.7"/>
  <circle cx="12" cy="12" r="2.5" fill="$hexColor"/>
  <path d="M12 2V5M12 19V22M2 12H5M19 12H22" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.shareCard:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="18" cy="5" r="3" stroke="$hexColor" stroke-width="1.7"/>
  <circle cx="6" cy="12" r="3" stroke="$hexColor" stroke-width="1.7"/>
  <circle cx="18" cy="19" r="3" stroke="$hexColor" stroke-width="1.7"/>
  <path d="M8.59 13.51L15.42 17.49M15.41 6.51L8.59 10.49" stroke="$hexColor" stroke-width="1.7"/>
</svg>''';
      case BespokeIconType.checkBadge:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="$hexColor" stroke-width="1.7"/>
  <path d="M8 12.5L10.8 15.3L16.5 9.5" stroke="$hexColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.plusCircle:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="$hexColor" stroke-width="1.7"/>
  <path d="M12 8V16M8 12H16" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.minusCircle:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="$hexColor" stroke-width="1.7"/>
  <path d="M8 12H16" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.audioWave:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 10V14M8 6V18M12 3V21M16 7V17M20 10V14" stroke="$hexColor" stroke-width="1.9" stroke-linecap="round"/>
</svg>''';
      case BespokeIconType.crescentOrb:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.sacredScroll:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2 4H8C10.2091 4 12 5.79086 12 8V20C12 18.3431 10.6569 17 9 17H2V4Z" stroke="$hexColor" stroke-width="1.7" stroke-linejoin="round"/>
  <path d="M22 4H16C13.7909 4 12 5.79086 12 8V20C12 18.3431 13.3431 17 15 17H22V4Z" stroke="$hexColor" stroke-width="1.7" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.tasbihRipple:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="3" fill="$hexColor"/>
  <circle cx="12" cy="12" r="7" stroke="$hexColor" stroke-width="1.5"/>
  <circle cx="12" cy="12" r="10.5" stroke="$hexColor" stroke-width="1.1" stroke-dasharray="3 3"/>
</svg>''';
      case BespokeIconType.qiblaStar:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <polygon points="12,2 15.5,10.5 22,12 15.5,13.5 12,22 8.5,13.5 2,12 8.5,10.5" stroke="$hexColor" stroke-width="1.6" stroke-linejoin="round"/>
  <circle cx="12" cy="12" r="2" fill="$hexColor"/>
</svg>''';
      case BespokeIconType.refreshSpark:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 12A9 9 0 0 0 6 5.3L3 8M3 3V8H8M3 12A9 9 0 0 0 18 18.7L21 16M21 21V16H16" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
      case BespokeIconType.expandFrame:
        return '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 3H21V9M9 21H3V15M21 3L14 10M3 21L10 14" stroke="$hexColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
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
    this.color = const Color(0xFF64FFDA),
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
      return const BespokeVectorIcon(
        type: BespokeIconType.audioWave,
        color: Colors.white38,
        size: 20,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(34, 20),
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
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    const count = 5;
    final spacing = size.width / (count + 1);
    for (int i = 0; i < count; i++) {
      final x = spacing * (i + 1);
      final wave = (math.sin((phase * 2 * math.pi) + (i * 1.1)) + 1.0) / 2.0;
      final barHeight = 4.0 + (size.height - 5.0) * wave;
      final top = (size.height - barHeight) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveBarsPainter oldDelegate) => true;
}
