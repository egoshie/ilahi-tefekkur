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
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 26,
    this.blurSigma = 32,
    this.tintColor,
    this.goldAccentBorder = false,
    this.emeraldGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseTint = tintColor ??
        (emeraldGlow
            ? const Color(0xFF00FF87)
            : (goldAccentBorder ? const Color(0xFFFFB300) : const Color(0xFF00E5FF)));

    final glowShadowColor = emeraldGlow
        ? const Color(0xFF00FF87).withOpacity(0.24)
        : (goldAccentBorder
            ? const Color(0xFFFFB300).withOpacity(0.24)
            : const Color(0xFF00E5FF).withOpacity(0.16));

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowShadowColor,
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            foregroundPainter: _HyperSpecularBorderPainter(
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
                    Colors.white.withOpacity(0.19),
                    baseTint.withOpacity(0.11),
                    const Color(0xFF071329).withOpacity(0.45),
                  ],
                  stops: const [0.0, 0.52, 1.0],
                ),
              ),
              child: child,
            ),
          ),
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

class _HyperSpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final bool goldAccent;
  final bool emeraldAccent;

  _HyperSpecularBorderPainter({
    required this.borderRadius,
    required this.goldAccent,
    required this.emeraldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.6),
      Radius.circular(borderRadius),
    );

    final topColor = emeraldAccent
        ? const Color(0xFF00FF87)
        : (goldAccent ? const Color(0xFFFFD54F) : Colors.white.withOpacity(0.85));

    final bottomColor = emeraldAccent
        ? const Color(0xFF00E5FF)
        : const Color(0xFF00E5FF).withOpacity(0.65);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          topColor,
          Colors.white.withOpacity(0.20),
          bottomColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _HyperSpecularBorderPainter oldDelegate) {
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
  State<SpringGlassInteractive> createState() => _SpringGlassInteractiveState();
}

class _SpringGlassInteractiveState extends State<SpringGlassInteractive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _scale = 1.0 - (_controller.value * 0.04);
        });
      });
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    const spring = SpringDescription(mass: 1.0, stiffness: 450.0, damping: 22.0);
    _controller.animateWith(SpringSimulation(spring, _controller.value, 1.0, 0));
  }

  void _onTapUp(TapUpDetails details) {
    HapticFeedback.lightImpact();
    const spring = SpringDescription(mass: 1.0, stiffness: 320.0, damping: 16.0);
    _controller.animateWith(SpringSimulation(spring, _controller.value, 0.0, -2.0));
    widget.onTap();
  }

  void _onTapCancel() {
    const spring = SpringDescription(mass: 1.0, stiffness: 320.0, damping: 18.0);
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
        scale: _scale.clamp(0.93, 1.04),
        child: widget.child,
      ),
    );
  }
}
