import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableBlur;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final bool goldAccentBorder;
  final bool emeraldGlow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.enableBlur = true,
    this.blurSigma = 24.0,
    this.tintColor,
    this.borderColor,
    this.gradientColors,
    this.goldAccentBorder = false,
    this.emeraldGlow = false,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      reverseDuration: const Duration(milliseconds: 210),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.978).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    final List<Color> effectiveGradient = widget.gradientColors ??
        (widget.emeraldGlow
            ? [
                const Color(0xFF154233).withValues(alpha: _isPressed ? 0.62 : 0.50),
                const Color(0xFF0A241B).withValues(alpha: 0.68),
                const Color(0xFF05110D).withValues(alpha: 0.82),
              ]
            : [
                (widget.tintColor ?? const Color(0xFF103126))
                    .withValues(alpha: _isPressed ? 0.54 : 0.42),
                const Color(0xFF081C15).withValues(alpha: 0.66),
                const Color(0xFF040D0A).withValues(alpha: 0.80),
              ]);

    final Color outerBorderColor = widget.borderColor ??
        (widget.goldAccentBorder
            ? const Color(0xFFFFE082).withValues(alpha: _isPressed ? 0.62 : 0.42)
            : const Color(0xFF9CE5C9).withValues(alpha: _isPressed ? 0.36 : 0.22));

    Widget surface = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.46),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          if (widget.emeraldGlow)
            BoxShadow(
              color: const Color(0xFF3F9D7B).withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 4),
            ),
          if (widget.goldAccentBorder)
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
              blurRadius: 16,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: widget.enableBlur
              ? ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: CustomPaint(
            foregroundPainter: _LiquidGlassRimPainter(
              borderRadius: widget.borderRadius,
              outerBorderColor: outerBorderColor,
              goldAccent: widget.goldAccentBorder,
              isPressed: _isPressed,
            ),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: const Alignment(-0.85, -1.0),
                  end: const Alignment(0.85, 1.0),
                  stops: const [0.0, 0.48, 1.0],
                  colors: effectiveGradient,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      surface = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: ScaleTransition(scale: _scaleAnim, child: surface),
      );
    }

    return widget.margin != null
        ? Padding(padding: widget.margin!, child: surface)
        : surface;
  }
}

class _LiquidGlassRimPainter extends CustomPainter {
  final double borderRadius;
  final Color outerBorderColor;
  final bool goldAccent;
  final bool isPressed;

  const _LiquidGlassRimPainter({
    required this.borderRadius,
    required this.outerBorderColor,
    required this.goldAccent,
    required this.isPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;

    final outerRRect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(borderRadius),
    );

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = goldAccent ? 1.25 : 1.05
      ..shader = LinearGradient(
        begin: const Alignment(-1.0, -1.0),
        end: const Alignment(1.0, 1.0),
        stops: const [0.0, 0.35, 0.70, 1.0],
        colors: [
          goldAccent
              ? const Color(0xFFFFF3C4).withValues(alpha: isPressed ? 0.85 : 0.68)
              : const Color(0xFFE2FFF3).withValues(alpha: isPressed ? 0.62 : 0.45),
          outerBorderColor,
          const Color(0xFF0A261D).withValues(alpha: 0.35),
          goldAccent
              ? const Color(0xFFD4AF37).withValues(alpha: 0.42)
              : const Color(0xFF9CE5C9).withValues(alpha: 0.28),
        ],
      ).createShader(rect);

    canvas.drawRRect(outerRRect, outerPaint);

    if (size.width > 8 && size.height > 8) {
      final innerRRect = RRect.fromRectAndRadius(
        rect.deflate(1.75),
        Radius.circular((borderRadius - 1.5).clamp(2.0, borderRadius)),
      );
      final innerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isPressed ? 0.22 : 0.14),
            Colors.transparent,
            const Color(0xFF9CE5C9).withValues(alpha: 0.06),
          ],
        ).createShader(rect);
      canvas.drawRRect(innerRRect, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassRimPainter old) =>
      old.borderRadius != borderRadius ||
      old.outerBorderColor != outerBorderColor ||
      old.goldAccent != goldAccent ||
      old.isPressed != isPressed;
}
