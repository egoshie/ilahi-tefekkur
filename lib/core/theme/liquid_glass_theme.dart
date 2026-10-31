import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'huzur_vector_icons.dart';

export 'huzur_vector_icons.dart';

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
          deepCosmicStart: Color(0xFF040C1C),
          deepCosmicMid: Color(0xFF0A243C),
          deepCosmicEnd: Color(0xFF0F364C),
          auroraPrimary: Color(0xFF64FFDA),
          auroraSecondary: Color(0xFF40C4FF),
          crystalAccent: Color(0xFF80FFE5),
          specularHighlight: Color(0xFFE0F7FA),
          periodTitle: "Seher Vakti",
          spiritualSubtitle: "Dingin seher serinliği",
        );
      case PrayerPeriod.gunes:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF061022),
          deepCosmicMid: Color(0xFF0D2C3E),
          deepCosmicEnd: Color(0xFF14404A),
          auroraPrimary: Color(0xFFFFD54F),
          auroraSecondary: Color(0xFF64FFDA),
          crystalAccent: Color(0xFFFFE082),
          specularHighlight: Color(0xFFFFF8E1),
          periodTitle: "İşrak Vakti",
          spiritualSubtitle: "Sabah aydınlığı ve taze nefes",
        );
      case PrayerPeriod.ogle:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF04101E),
          deepCosmicMid: Color(0xFF0A2C38),
          deepCosmicEnd: Color(0xFF10424C),
          auroraPrimary: Color(0xFF64FFDA),
          auroraSecondary: Color(0xFF18FFFF),
          crystalAccent: Color(0xFF64FFDA),
          specularHighlight: Color(0xFFE0F2F1),
          periodTitle: "Gün Ortası",
          spiritualSubtitle: "Berrak su kristali dinginliği",
        );
      case PrayerPeriod.ikindi:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF060E1E),
          deepCosmicMid: Color(0xFF0D2634),
          deepCosmicEnd: Color(0xFF143844),
          auroraPrimary: Color(0xFFFFD54F),
          auroraSecondary: Color(0xFF64FFDA),
          crystalAccent: Color(0xFFFFE082),
          specularHighlight: Color(0xFFFFECB3),
          periodTitle: "İkindi Vakti",
          spiritualSubtitle: "Asr sükûneti ve tefekkür",
        );
      case PrayerPeriod.aksam:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF070B1C),
          deepCosmicMid: Color(0xFF112336),
          deepCosmicEnd: Color(0xFF183644),
          auroraPrimary: Color(0xFFFFAB40),
          auroraSecondary: Color(0xFF64FFDA),
          crystalAccent: Color(0xFFFFD180),
          specularHighlight: Color(0xFFFFE0B2),
          periodTitle: "Grup Vakti",
          spiritualSubtitle: "Ufuk kızıllığı ve akşam huzuru",
        );
      case PrayerPeriod.yatsi:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF030B18),
          deepCosmicMid: Color(0xFF092430),
          deepCosmicEnd: Color(0xFF0E3842),
          auroraPrimary: Color(0xFF64FFDA),
          auroraSecondary: Color(0xFF00E5FF),
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
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final angle = progress * 2 * math.pi;

    final center1 = Offset(
      size.width * (0.24 + 0.16 * math.sin(angle)),
      size.height * (0.18 + 0.09 * math.cos(angle * 1.1)),
    );
    _drawSilkyAurora(
      canvas,
      center1,
      size.width * 0.78,
      palette.auroraPrimary.withOpacity(0.32),
    );

    final center2 = Offset(
      size.width * (0.78 + 0.14 * math.cos(angle * 0.8)),
      size.height * (0.46 + 0.10 * math.sin(angle * 1.2)),
    );
    _drawSilkyAurora(
      canvas,
      center2,
      size.width * 0.72,
      palette.auroraSecondary.withOpacity(0.28),
    );

    final center3 = Offset(
      size.width * (0.40 + 0.18 * math.sin(angle * 0.9 + 1.4)),
      size.height * (0.80 + 0.08 * math.cos(angle)),
    );
    _drawSilkyAurora(
      canvas,
      center3,
      size.width * 0.76,
      const Color(0xFFFFE082).withOpacity(0.22),
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
          color.withOpacity(0.06),
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
      duration: const Duration(milliseconds: 620),
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
