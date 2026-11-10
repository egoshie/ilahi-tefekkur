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
  final Brightness brightness;

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
    this.brightness = Brightness.dark,
  });

  static LiquidGlassPalette _darkForPeriod(PrayerPeriod period) {
    switch (period) {
      case PrayerPeriod.imsak:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF121212),
          deepCosmicMid: Color(0xFF211D19),
          deepCosmicEnd: Color(0xFF30251D),
          auroraPrimary: Color(0xFFFFA21A),
          auroraSecondary: Color(0xFFFFC15A),
          crystalAccent: Color(0xFFFFC15A),
          specularHighlight: Color(0xFFE0F7FA),
          periodTitle: "Seher Vakti",
          spiritualSubtitle: "Dingin seher serinliği",
        );
      case PrayerPeriod.gunes:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF121212),
          deepCosmicMid: Color(0xFF211D19),
          deepCosmicEnd: Color(0xFF30251D),
          auroraPrimary: Color(0xFFFFD54F),
          auroraSecondary: Color(0xFFFFA21A),
          crystalAccent: Color(0xFFFFE082),
          specularHighlight: Color(0xFFFFF8E1),
          periodTitle: "İşrak Vakti",
          spiritualSubtitle: "Sabah aydınlığı ve taze nefes",
        );
      case PrayerPeriod.ogle:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF121212),
          deepCosmicMid: Color(0xFF211D19),
          deepCosmicEnd: Color(0xFF30251D),
          auroraPrimary: Color(0xFFFFA21A),
          auroraSecondary: Color(0xFFFF8F00),
          crystalAccent: Color(0xFFFFA21A),
          specularHighlight: Color(0xFFE0F2F1),
          periodTitle: "Gün Ortası",
          spiritualSubtitle: "Berrak su kristali dinginliği",
        );
      case PrayerPeriod.ikindi:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF121212),
          deepCosmicMid: Color(0xFF211D19),
          deepCosmicEnd: Color(0xFF30251D),
          auroraPrimary: Color(0xFFFFD54F),
          auroraSecondary: Color(0xFFFFA21A),
          crystalAccent: Color(0xFFFFE082),
          specularHighlight: Color(0xFFFFECB3),
          periodTitle: "İkindi Vakti",
          spiritualSubtitle: "Asr sükûneti ve tefekkür",
        );
      case PrayerPeriod.aksam:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF121212),
          deepCosmicMid: Color(0xFF211D19),
          deepCosmicEnd: Color(0xFF30251D),
          auroraPrimary: Color(0xFFFFAB40),
          auroraSecondary: Color(0xFFFFA21A),
          crystalAccent: Color(0xFFFFD180),
          specularHighlight: Color(0xFFFFE0B2),
          periodTitle: "Grup Vakti",
          spiritualSubtitle: "Ufuk kızıllığı ve akşam huzuru",
        );
      case PrayerPeriod.yatsi:
        return const LiquidGlassPalette(
          deepCosmicStart: Color(0xFF121212),
          deepCosmicMid: Color(0xFF211D19),
          deepCosmicEnd: Color(0xFF30251D),
          auroraPrimary: Color(0xFFFFA21A),
          auroraSecondary: Color(0xFFFFB74D),
          crystalAccent: Color(0xFFFFA21A),
          specularHighlight: Color(0xFFB2DFDB),
          periodTitle: "Gece Vakti",
          spiritualSubtitle: "Derin gece ve kalp sükûneti",
        );
    }
  }

  static LiquidGlassPalette forPeriod(
    PrayerPeriod period, {
    Brightness brightness = Brightness.dark,
  }) {
    final dark = _darkForPeriod(period);
    if (brightness == Brightness.dark) return dark;

    return LiquidGlassPalette(
      deepCosmicStart: const Color(0xFFFFF8EF),
      deepCosmicMid: const Color(0xFFF6EADC),
      deepCosmicEnd: const Color(0xFFF0DDC5),
      auroraPrimary: const Color(0xFFB76B00),
      auroraSecondary: const Color(0xFFD98C22),
      crystalAccent: const Color(0xFF9C5700),
      specularHighlight: Colors.white,
      periodTitle: dark.periodTitle,
      spiritualSubtitle: dark.spiritualSubtitle,
      brightness: Brightness.light,
    );
  }

  static ThemeData buildTheme(LiquidGlassPalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF18372C);

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.deepCosmicStart,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: palette.crystalAccent,
              secondary: palette.auroraPrimary,
              surface: palette.deepCosmicMid,
            )
          : ColorScheme.light(
              primary: palette.crystalAccent,
              secondary: palette.auroraPrimary,
              surface: palette.deepCosmicMid,
            ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: palette.brightness).textTheme,
      ).apply(bodyColor: foreground, displayColor: foreground),
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
      duration: const Duration(seconds: 30),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final motionEnabled = TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

    if (motionEnabled) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else if (_controller.isAnimating) {
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
      palette.auroraPrimary.withValues(alpha: 0.32),
    );

    final center2 = Offset(
      size.width * (0.78 + 0.14 * math.cos(angle * 0.8)),
      size.height * (0.46 + 0.10 * math.sin(angle * 1.2)),
    );
    _drawSilkyAurora(
      canvas,
      center2,
      size.width * 0.72,
      palette.auroraSecondary.withValues(alpha: 0.28),
    );

    final center3 = Offset(
      size.width * (0.40 + 0.18 * math.sin(angle * 0.9 + 1.4)),
      size.height * (0.80 + 0.08 * math.cos(angle)),
    );
    _drawSilkyAurora(
      canvas,
      center3,
      size.width * 0.76,
      const Color(0xFFFFE082).withValues(alpha: 0.22),
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
          color.withValues(alpha: 0.06),
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
    this.color = const Color(0xFFFFA21A),
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
