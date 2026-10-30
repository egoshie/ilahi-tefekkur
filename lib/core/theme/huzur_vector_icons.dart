import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  skipNext,
  skipPrev,
  closeCross,
}

typedef HuzurIcon = BespokeVectorIcon;

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PureCanvasVectorIconPainter(
          type: type,
          color: color,
        ),
      ),
    );
  }
}

class _PureCanvasVectorIconPainter extends CustomPainter {
  final BespokeIconType type;
  final Color color;

  _PureCanvasVectorIconPainter({
    required this.type,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2.0, h / 2.0);
    final strokeW = (w * 0.085).clamp(1.4, 2.4);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (type) {
      case BespokeIconType.crescentOrb:
        final path = Path();
        final r1 = w * 0.38;
        path.addArc(
          Rect.fromCircle(center: c, radius: r1),
          0.35,
          math.pi * 1.45,
        );
        canvas.drawPath(path, stroke);
        canvas.drawCircle(Offset(w * 0.68, h * 0.30), w * 0.06, fill);
        break;

      case BespokeIconType.sacredScroll:
        final book = Path()
          ..moveTo(w * 0.50, h * 0.24)
          ..quadraticBezierTo(w * 0.28, h * 0.17, w * 0.12, h * 0.25)
          ..lineTo(w * 0.12, h * 0.78)
          ..quadraticBezierTo(w * 0.28, h * 0.70, w * 0.50, h * 0.80)
          ..quadraticBezierTo(w * 0.72, h * 0.70, w * 0.88, h * 0.78)
          ..lineTo(w * 0.88, h * 0.25)
          ..quadraticBezierTo(w * 0.72, h * 0.17, w * 0.50, h * 0.24);
        canvas.drawPath(book, stroke);
        canvas.drawLine(
          Offset(w * 0.50, h * 0.24),
          Offset(w * 0.50, h * 0.80),
          stroke,
        );
        break;

      case BespokeIconType.tasbihRipple:
        canvas.drawCircle(c, w * 0.11, fill);
        for (int i = 0; i < 8; i++) {
          final a = (i * math.pi / 4.0);
          final p = Offset(
            c.dx + math.cos(a) * w * 0.34,
            c.dy + math.sin(a) * h * 0.34,
          );
          canvas.drawCircle(p, w * 0.065, fill);
        }
        break;

      case BespokeIconType.qiblaStar:
        final diamond = Path()
          ..moveTo(w * 0.50, h * 0.10)
          ..lineTo(w * 0.64, h * 0.50)
          ..lineTo(w * 0.50, h * 0.90)
          ..lineTo(w * 0.36, h * 0.50)
          ..close();
        canvas.drawPath(diamond, stroke);
        canvas.drawCircle(c, w * 0.38, stroke..strokeWidth = strokeW * 0.75);
        canvas.drawCircle(c, w * 0.07, fill);
        break;

      case BespokeIconType.crownGem:
      case BespokeIconType.esmaGrid:
        final star = Path()
          ..moveTo(w * 0.50, h * 0.10)
          ..quadraticBezierTo(w * 0.54, h * 0.46, w * 0.90, h * 0.50)
          ..quadraticBezierTo(w * 0.54, h * 0.54, w * 0.50, h * 0.90)
          ..quadraticBezierTo(w * 0.46, h * 0.54, w * 0.10, h * 0.50)
          ..quadraticBezierTo(w * 0.46, h * 0.46, w * 0.50, h * 0.10)
          ..close();
        canvas.drawPath(star, stroke);
        canvas.drawCircle(Offset(w * 0.78, h * 0.22), w * 0.055, fill);
        break;

      case BespokeIconType.playTriangle:
        final tri = Path()
          ..moveTo(w * 0.28, h * 0.20)
          ..lineTo(w * 0.80, h * 0.50)
          ..lineTo(w * 0.28, h * 0.80)
          ..close();
        canvas.drawPath(tri, fill);
        break;

      case BespokeIconType.stopSquare:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: w * 0.52, height: h * 0.52),
            Radius.circular(w * 0.10),
          ),
          fill,
        );
        break;

      case BespokeIconType.pauseBars:
        final barW = w * 0.16;
        final barH = h * 0.58;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w * 0.34, h * 0.50),
              width: barW,
              height: barH,
            ),
            Radius.circular(w * 0.06),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w * 0.66, h * 0.50),
              width: barW,
              height: barH,
            ),
            Radius.circular(w * 0.06),
          ),
          fill,
        );
        break;

      case BespokeIconType.skipNext:
        final nextTri = Path()
          ..moveTo(w * 0.20, h * 0.22)
          ..lineTo(w * 0.66, h * 0.50)
          ..lineTo(w * 0.20, h * 0.78)
          ..close();
        canvas.drawPath(nextTri, fill);
        canvas.drawLine(
          Offset(w * 0.76, h * 0.24),
          Offset(w * 0.76, h * 0.76),
          stroke,
        );
        break;

      case BespokeIconType.skipPrev:
        final prevTri = Path()
          ..moveTo(w * 0.80, h * 0.22)
          ..lineTo(w * 0.34, h * 0.50)
          ..lineTo(w * 0.80, h * 0.78)
          ..close();
        canvas.drawPath(prevTri, fill);
        canvas.drawLine(
          Offset(w * 0.24, h * 0.24),
          Offset(w * 0.24, h * 0.76),
          stroke,
        );
        break;

      case BespokeIconType.closeCross:
        canvas.drawLine(
          Offset(w * 0.26, h * 0.26),
          Offset(w * 0.74, h * 0.74),
          stroke,
        );
        canvas.drawLine(
          Offset(w * 0.74, h * 0.26),
          Offset(w * 0.26, h * 0.74),
          stroke,
        );
        break;

      case BespokeIconType.lockShield:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.22, h * 0.45, w * 0.56, h * 0.42),
            Radius.circular(w * 0.10),
          ),
          stroke,
        );
        final shackle = Path()
          ..moveTo(w * 0.33, h * 0.45)
          ..lineTo(w * 0.33, h * 0.32)
          ..arcToPoint(
            Offset(w * 0.67, h * 0.32),
            radius: Radius.circular(w * 0.17),
          )
          ..lineTo(w * 0.67, h * 0.45);
        canvas.drawPath(shackle, stroke);
        break;

      case BespokeIconType.bookmarkStar:
        final bm = Path()
          ..moveTo(w * 0.25, h * 0.16)
          ..lineTo(w * 0.75, h * 0.16)
          ..lineTo(w * 0.75, h * 0.86)
          ..lineTo(w * 0.50, h * 0.68)
          ..lineTo(w * 0.25, h * 0.86)
          ..close();
        canvas.drawPath(bm, stroke);
        break;

      case BespokeIconType.heartFavorite:
        final heart = Path()
          ..moveTo(w * 0.50, h * 0.82)
          ..cubicTo(
            w * 0.12,
            h * 0.58,
            w * 0.14,
            h * 0.22,
            w * 0.36,
            h * 0.22,
          )
          ..cubicTo(
            w * 0.45,
            h * 0.22,
            w * 0.50,
            h * 0.30,
            w * 0.50,
            h * 0.34,
          )
          ..cubicTo(
            w * 0.50,
            h * 0.30,
            w * 0.55,
            h * 0.22,
            w * 0.64,
            h * 0.22,
          )
          ..cubicTo(
            w * 0.86,
            h * 0.22,
            w * 0.88,
            h * 0.58,
            w * 0.50,
            h * 0.82,
          );
        canvas.drawPath(heart, stroke);
        break;

      case BespokeIconType.widgetSpark:
        final r = Radius.circular(w * 0.07);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.16, w * 0.32, h * 0.30),
            r,
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.54, h * 0.16, w * 0.32, h * 0.30),
            r,
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.54, w * 0.72, h * 0.30),
            r,
          ),
          stroke,
        );
        break;

      case BespokeIconType.searchLens:
        canvas.drawCircle(Offset(w * 0.44, h * 0.44), w * 0.26, stroke);
        canvas.drawLine(
          Offset(w * 0.63, h * 0.63),
          Offset(w * 0.84, h * 0.84),
          stroke,
        );
        break;

      case BespokeIconType.audioWave:
        final xs = [0.20, 0.35, 0.50, 0.65, 0.80];
        final hs = [0.28, 0.52, 0.72, 0.48, 0.28];
        for (int i = 0; i < xs.length; i++) {
          final x = w * xs[i];
          final hh = h * hs[i];
          canvas.drawLine(
            Offset(x, (h - hh) / 2.0),
            Offset(x, (h + hh) / 2.0),
            stroke,
          );
        }
        break;

      case BespokeIconType.gpsTarget:
        canvas.drawCircle(c, w * 0.28, stroke);
        canvas.drawCircle(c, w * 0.09, fill);
        canvas.drawLine(Offset(w * 0.50, h * 0.08), Offset(w * 0.50, h * 0.22), stroke);
        canvas.drawLine(Offset(w * 0.50, h * 0.78), Offset(w * 0.50, h * 0.92), stroke);
        canvas.drawLine(Offset(w * 0.08, h * 0.50), Offset(w * 0.22, h * 0.50), stroke);
        canvas.drawLine(Offset(w * 0.78, h * 0.50), Offset(w * 0.92, h * 0.50), stroke);
        break;

      case BespokeIconType.shareCard:
        final p1 = Offset(w * 0.72, h * 0.24);
        final p2 = Offset(w * 0.26, h * 0.50);
        final p3 = Offset(w * 0.72, h * 0.76);
        canvas.drawLine(p2, p1, stroke);
        canvas.drawLine(p2, p3, stroke);
        canvas.drawCircle(p1, w * 0.10, fill);
        canvas.drawCircle(p2, w * 0.10, fill);
        canvas.drawCircle(p3, w * 0.10, fill);
        break;

      case BespokeIconType.checkBadge:
      case BespokeIconType.verifiedSeal:
        canvas.drawCircle(c, w * 0.38, stroke);
        final chk = Path()
          ..moveTo(w * 0.32, h * 0.52)
          ..lineTo(w * 0.45, h * 0.65)
          ..lineTo(w * 0.68, h * 0.38);
        canvas.drawPath(chk, stroke);
        break;

      case BespokeIconType.plusCircle:
        canvas.drawCircle(c, w * 0.38, stroke);
        canvas.drawLine(Offset(w * 0.50, h * 0.32), Offset(w * 0.50, h * 0.68), stroke);
        canvas.drawLine(Offset(w * 0.32, h * 0.50), Offset(w * 0.68, h * 0.50), stroke);
        break;

      case BespokeIconType.minusCircle:
        canvas.drawCircle(c, w * 0.38, stroke);
        canvas.drawLine(Offset(w * 0.32, h * 0.50), Offset(w * 0.68, h * 0.50), stroke);
        break;

      case BespokeIconType.refreshSpark:
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: w * 0.34),
          0.3,
          math.pi * 1.45,
          false,
          stroke,
        );
        final arr = Path()
          ..moveTo(w * 0.72, h * 0.16)
          ..lineTo(w * 0.84, h * 0.34)
          ..lineTo(w * 0.64, h * 0.36);
        canvas.drawPath(arr, stroke);
        break;

      case BespokeIconType.expandFrame:
        final exp = Path()
          ..moveTo(w * 0.62, h * 0.18)
          ..lineTo(w * 0.82, h * 0.18)
          ..lineTo(w * 0.82, h * 0.38)
          ..moveTo(w * 0.38, h * 0.82)
          ..lineTo(w * 0.18, h * 0.82)
          ..lineTo(w * 0.18, h * 0.62);
        canvas.drawPath(exp, stroke);
        canvas.drawLine(Offset(w * 0.82, h * 0.18), Offset(w * 0.56, h * 0.44), stroke);
        canvas.drawLine(Offset(w * 0.18, h * 0.82), Offset(w * 0.44, h * 0.56), stroke);
        break;

      case BespokeIconType.instagramStory:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.68),
            Radius.circular(w * 0.18),
          ),
          stroke,
        );
        canvas.drawCircle(c, w * 0.16, stroke);
        canvas.drawCircle(Offset(w * 0.68, h * 0.32), w * 0.045, fill);
        break;

      case BespokeIconType.whatsappShare:
        final send = Path()
          ..moveTo(w * 0.14, h * 0.46)
          ..lineTo(w * 0.86, h * 0.18)
          ..lineTo(w * 0.58, h * 0.86)
          ..lineTo(w * 0.46, h * 0.56)
          ..close();
        canvas.drawPath(send, stroke);
        break;

      case BespokeIconType.downloadCard:
        canvas.drawLine(Offset(w * 0.50, h * 0.18), Offset(w * 0.50, h * 0.66), stroke);
        final dArr = Path()
          ..moveTo(w * 0.32, h * 0.50)
          ..lineTo(w * 0.50, h * 0.68)
          ..lineTo(w * 0.68, h * 0.50);
        canvas.drawPath(dArr, stroke);
        canvas.drawLine(Offset(w * 0.22, h * 0.82), Offset(w * 0.78, h * 0.82), stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PureCanvasVectorIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
