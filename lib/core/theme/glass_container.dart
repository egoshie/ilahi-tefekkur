import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final bool goldAccentBorder;
  final bool emeraldGlow;
  final bool enableBlur;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 24,
    this.blurSigma = 20,
    this.tintColor,
    this.goldAccentBorder = false,
    this.emeraldGlow = false,
    this.enableBlur = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget surface = CustomPaint(
      foregroundPainter: _RefractiveSpecularRimPainter(
        borderRadius: borderRadius,
        goldAccent: goldAccentBorder,
        emeraldAccent: emeraldGlow,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.10),
              (tintColor ?? const Color(0xFF0A222E)).withOpacity(0.42),
              const Color(0xFF04111A).withOpacity(0.58),
            ],
            stops: const [0.0, 0.50, 1.0],
          ),
        ),
        child: child,
      ),
    );

    if (enableBlur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    final content = RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.26),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            if (emeraldGlow || goldAccentBorder)
              BoxShadow(
                color: (goldAccentBorder
                        ? const Color(0xFFFFE082)
                        : const Color(0xFF64FFDA))
                    .withOpacity(0.08),
                blurRadius: 14,
                spreadRadius: -2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: surface,
        ),
      ),
    );

    if (onTap == null) return content;

    return SpringGlassInteractive(
      onTap: onTap!,
      child: content,
    );
  }
}

class _RefractiveSpecularRimPainter extends CustomPainter {
  final double borderRadius;
  final bool goldAccent;
  final bool emeraldAccent;

  _RefractiveSpecularRimPainter({
    required this.borderRadius,
    required this.goldAccent,
    required this.emeraldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(borderRadius),
    );

    final topLeftRim = goldAccent
        ? const Color(0xFFFFE082).withOpacity(0.55)
        : Colors.white.withOpacity(0.42);

    final bottomRightRim = emeraldAccent
        ? const Color(0xFF64FFDA).withOpacity(0.38)
        : const Color(0xFF64FFDA).withOpacity(0.24);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          topLeftRim,
          Colors.white.withOpacity(0.06),
          bottomRightRim,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, borderPaint);

    final topHighlightPath = Path()
      ..moveTo(borderRadius * 0.85, 0.9)
      ..lineTo(size.width - borderRadius * 0.85, 0.9);

    final ceilingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.44),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 2));

    canvas.drawPath(topHighlightPath, ceilingPaint);
  }

  @override
  bool shouldRepaint(covariant _RefractiveSpecularRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.goldAccent != goldAccent ||
        oldDelegate.emeraldAccent != emeraldAccent;
  }
}

class SpringGlassInteractive extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const SpringGlassInteractive({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State< SpringGlassInteractive > createState() => _SpringGlassInteractiveState();
}

class _SpringGlassInteractiveState extends State< SpringGlassInteractive >
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _scale = 1.0 - (_controller.value * 0.032);
        });
      });
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    const spring = SpringDescription(mass: 1.0, stiffness: 480.0, damping: 24.0);
    _controller.animateWith(SpringSimulation(spring, _controller.value, 1.0, 0));
  }

  void _onTapUp(TapUpDetails details) {
    HapticFeedback.lightImpact();
    const spring = SpringDescription(mass: 1.0, stiffness: 360.0, damping: 18.0);
    _controller.animateWith(SpringSimulation(spring, _controller.value, 0.0, -2.0));
    widget.onTap();
  }

  void _onTapCancel() {
    const spring = SpringDescription(mass: 1.0, stiffness: 360.0, damping: 20.0);
    _controller.animateWith(SpringSimulation(spring, _controller.value, 0.0, 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale.clamp(0.95, 1.02),
        child: widget.child,
      ),
    );
  }
}
