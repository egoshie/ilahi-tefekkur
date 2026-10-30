import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  State< LiquidMeshBackground > createState() => _LiquidMeshBackgroundState();
}

class _LiquidMeshBackgroundState extends State< LiquidMeshBackground >
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
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
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                isComplex: true,
                willChange: true,
                painter: _AuroraCosmicPainter(
                  progress: _controller.value,
                  palette: widget.palette,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        RepaintBoundary(child: widget.child),
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

    final center1 = Offset(
      size.width * (0.25 + 0.15 * math.sin(angle)),
      size.height * (0.18 + 0.08 * math.cos(angle * 1.1)),
    );
    _drawSilkyAurora(
      canvas,
      center1,
      size.width * 0.70,
      palette.auroraPrimary.withOpacity(0.15),
    );

    final center2 = Offset(
      size.width * (0.76 + 0.13 * math.cos(angle * 0.8)),
      size.height * (0.48 + 0.10 * math.sin(angle * 1.2)),
    );
    _drawSilkyAurora(
      canvas,
      center2,
      size.width * 0.65,
      palette.auroraSecondary.withOpacity(0.12),
    );

    final center3 = Offset(
      size.width * (0.42 + 0.16 * math.sin(angle * 0.9 + 1.4)),
      size.height * (0.82 + 0.07 * math.cos(angle)),
    );
    _drawSilkyAurora(
      canvas,
      center3,
      size.width * 0.72,
      palette.crystalAccent.withOpacity(0.10),
    );
  }

  void _drawSilkyAurora(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
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
  pauseBars,
  lockShield,
  bookmarkStar,
  heartFavorite,
  widgetSpark,
  searchLens,
  audioWave,
  gpsTarget,
  shareCard,
  checkBadge,
  plusCircle,
  minusCircle,
  refreshSpark,
  expandFrame,
  instagramStory,
  whatsappShare,
  downloadCard,
  verifiedSeal,
  esmaGrid,
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

  IconData _resolveIconData() {
    switch (type) {
      case BespokeIconType.crescentOrb:
        return CupertinoIcons.moon_stars_fill;
      case BespokeIconType.sacredScroll:
        return CupertinoIcons.book_fill;
      case BespokeIconType.tasbihRipple:
        return CupertinoIcons.circle_grid_hex_fill;
      case BespokeIconType.qiblaStar:
        return CupertinoIcons.compass_fill;
      case BespokeIconType.crownGem:
        return CupertinoIcons.sparkles;
      case BespokeIconType.playTriangle:
        return CupertinoIcons.play_arrow_solid;
      case BespokeIconType.stopSquare:
        return CupertinoIcons.stop_fill;
      case BespokeIconType.pauseBars:
        return CupertinoIcons.pause_fill;
      case BespokeIconType.lockShield:
        return CupertinoIcons.lock_shield_fill;
      case BespokeIconType.bookmarkStar:
        return CupertinoIcons.bookmark_fill;
      case BespokeIconType.heartFavorite:
        return CupertinoIcons.heart_fill;
      case BespokeIconType.widgetSpark:
        return CupertinoIcons.square_grid_2x2_fill;
      case BespokeIconType.searchLens:
        return CupertinoIcons.search;
      case BespokeIconType.audioWave:
        return CupertinoIcons.waveform;
      case BespokeIconType.gpsTarget:
        return CupertinoIcons.location_fill;
      case BespokeIconType.shareCard:
        return CupertinoIcons.share;
      case BespokeIconType.checkBadge:
      case BespokeIconType.verifiedSeal:
        return CupertinoIcons.checkmark_seal_fill;
      case BespokeIconType.plusCircle:
        return CupertinoIcons.add_circled;
      case BespokeIconType.minusCircle:
        return CupertinoIcons.minus_circled;
      case BespokeIconType.refreshSpark:
        return CupertinoIcons.arrow_2_circlepath;
      case BespokeIconType.expandFrame:
        return CupertinoIcons.fullscreen;
      case BespokeIconType.instagramStory:
        return CupertinoIcons.camera_viewfinder;
      case BespokeIconType.whatsappShare:
        return CupertinoIcons.paperplane_fill;
      case BespokeIconType.downloadCard:
        return CupertinoIcons.arrow_down_to_line;
      case BespokeIconType.esmaGrid:
        return CupertinoIcons.sparkles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _resolveIconData(),
      color: color,
      size: size,
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
  State< LiveSvgAudioVisualizer > createState() => _LiveSvgAudioVisualizerState();
}

class _LiveSvgAudioVisualizerState extends State< LiveSvgAudioVisualizer >
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LiveSvgAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
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
  bool shouldRepaint(covariant _WaveBarsPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
