import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'glass_container.dart';

class StoryShareSheet extends StatefulWidget {
  final String arabic;
  final String turkishText;
  final String reference;

  const StoryShareSheet({
    super.key,
    required this.arabic,
    required this.turkishText,
    required this.reference,
  });

  static Future<void> show(
    BuildContext context, {
    String arabic = '',
    String? turkishText,
    String? turkish,
    String reference = '',
    String? category,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoryShareSheet(
        arabic: arabic,
        turkishText: turkishText ?? turkish ?? '',
        reference: reference,
      ),
    );
  }

  @override
  State<StoryShareSheet> createState() => _StoryShareSheetState();
}

class _StoryShareSheetState extends State<StoryShareSheet> {
  final GlobalKey _repaintKey = GlobalKey();

  static const MethodChannel _mediaChannel =
      MethodChannel('com.ilahi.tefekkur/media');

  static const double _storyWidth = 360;
  static const double _storyHeight = 640;

  bool _isExporting = false;
  String? _feedbackMessage;

  Future<Uint8List?> _captureStoryPng() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null || boundary.debugNeedsPaint) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final result = byteData?.buffer.asUint8List();
      image.dispose();

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareToSocial({required String target}) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _feedbackMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final pngBytes = await _captureStoryPng();

      if (pngBytes == null) {
        throw Exception('Görsel oluşturulamadı.');
      }

      if (target == 'Instagram Hikâye') {
        final ok = await _mediaChannel.invokeMethod<bool>(
              'shareToInstagramStory',
              {'bytes': pngBytes},
            ) ??
            false;

        if (mounted) {
          setState(() {
            _feedbackMessage = ok
                ? 'Huzur Story, Instagram paylaşım ekranında hazır.'
                : 'Instagram açılamadı. Uygulamanın yüklü olduğunu kontrol edin.';
          });
        }
      } else {
        final caption = '${widget.turkishText}\n— ${widget.reference} • Huzur';

        await _mediaChannel.invokeMethod<bool>(
          'saveImageToGallery',
          {'bytes': pngBytes},
        );

        final ok = await _mediaChannel.invokeMethod<bool>(
              'shareToWhatsAppDirect',
              {'bytes': pngBytes, 'text': caption},
            ) ??
            false;

        if (mounted) {
          setState(() {
            _feedbackMessage =
                ok ? 'WhatsApp paylaşımı açıldı.' : 'WhatsApp açılamadı.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _feedbackMessage = 'Paylaşım sırasında hata oluştu.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveDirectlyToGallery() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _feedbackMessage = null;
    });

    try {
      final pngBytes = await _captureStoryPng();

      if (pngBytes == null) {
        throw Exception('Görsel oluşturulamadı.');
      }

      final saved = await _mediaChannel.invokeMethod<bool>(
            'saveImageToGallery',
            {'bytes': pngBytes},
          ) ??
          false;

      if (mounted) {
        setState(() {
          _feedbackMessage = saved
              ? '1080 × 1920 görsel galeriye kaydedildi.'
              : 'Görsel kaydedilemedi.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _feedbackMessage = 'Galeriye kaydetme başarısız.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildStoryCard() {
    const accent = Color(0xFF64FFDA);
    const gold = Color(0xFFFFE082);

    return RepaintBoundary(
      key: _repaintKey,
      child: SizedBox(
        width: _storyWidth,
        height: _storyHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF041712),
                      Color(0xFF092B25),
                      Color(0xFF07131D),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -105,
                right: -100,
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.16),
                        blurRadius: 90,
                        spreadRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.12),
                        blurRadius: 90,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: accent.withValues(alpha: 0.13),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: gold,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HUZUR',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'KALBE DOKUNAN BİR MOLA',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 8,
                                  letterSpacing: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: accent,
                          size: 23,
                        ),
                      ],
                    ),
                    const SizedBox(height: 23),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'KUR’ÂN-I KERÎM  •  TEFEKKÜR',
                        maxLines: 1,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: _StoryAutoFitText(
                            text: widget.arabic,
                            textAlign: TextAlign.center,
                            maxLines: 6,
                            maxFontSize: 33,
                            minFontSize: 18,
                            style: const TextStyle(
                              color: Color(0xFFFFF4DC),
                              height: 1.9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 58,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            gold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: _StoryAutoFitText(
                          text: widget.turkishText,
                          textAlign: TextAlign.center,
                          maxLines: 9,
                          maxFontSize: 19,
                          minFontSize: 12.5,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.65,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reference,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 39,
                                height: 39,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF176B55),
                                      Color(0xFF0A302A),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.graphic_eq_rounded,
                                  color: gold,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HUZUR • TİLAVET',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Kalbine iyi gelen ayetler',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: accent,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          SizedBox(
                            height: 18,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _StoryWavePainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF17634E),
                            Color(0xFF0D3933),
                          ],
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'HUZUR’U KEŞFET',
                            style: TextStyle(
                              color: Color(0xFFB5FFEA),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: gold,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'HUZUR  •  MANEVİYATIN SADE HÂLİ',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 7.5,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return SafeArea(
      top: false,
      child: Container(
        height: screen.height * 0.94,
        decoration: const BoxDecoration(
          color: Color(0xFF030B18),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 13),
            Container(
              width: 43,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFE082),
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Huzur Story Stüdyosu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '9:16',
                    style: TextStyle(
                      color: Color(0xFF64FFDA),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width =
                        (constraints.maxWidth - 36).clamp(120.0, 360.0);
                    return SizedBox(
                      width: width,
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: _buildStoryCard(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_feedbackMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 5, 18, 5),
                child: Text(
                  _feedbackMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 11,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 15,
                          emeraldGlow: true,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          onTap: _isExporting
                              ? null
                              : () =>
                                  _shareToSocial(target: 'Instagram Hikâye'),
                          child: const Center(
                            child: Text(
                              'Instagram Story',
                              style: TextStyle(
                                color: Color(0xFF64FFDA),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 15,
                          goldAccentBorder: true,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          onTap: _isExporting
                              ? null
                              : () => _shareToSocial(target: 'WhatsApp Durum'),
                          child: const Center(
                            child: Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: Color(0xFFFFE082),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  GlassContainer(
                    borderRadius: 15,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onTap: _isExporting ? null : _saveDirectlyToGallery,
                    child: Center(
                      child: _isExporting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF64FFDA),
                              ),
                            )
                          : const Text(
                              'Galeriye Kaydet • 1080 × 1920',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tıklanabilir yönlendirme için Instagram’da ayrıca Link sticker ekleyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef HuzurStoryShareSheet = StoryShareSheet;

class _StoryAutoFitText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final double maxFontSize;
  final double minFontSize;

  const _StoryAutoFitText({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.maxLines,
    required this.maxFontSize,
    required this.minFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = maxFontSize;
        final direction = Directionality.of(context);

        while (size > minFontSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(fontSize: size),
            ),
            textDirection: direction,
            textAlign: textAlign,
            maxLines: maxLines,
          )..layout(maxWidth: constraints.maxWidth);

          if (!painter.didExceedMaxLines &&
              painter.height <= constraints.maxHeight) {
            break;
          }
          size -= 0.5;
        }

        return Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }
}

class _StoryWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const heights = <double>[
      5,
      9,
      13,
      7,
      16,
      11,
      6,
      14,
      18,
      9,
      5,
      12,
      17,
      8,
      14,
      6,
      18,
      11,
      7,
      15,
      9,
      5,
      13,
      17,
      8,
      12,
      6,
      16,
      10,
      5,
      14,
      18,
      9,
      6,
      12,
      16,
    ];
    final paint = Paint()
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.8)
      ..strokeCap = StrokeCap.round;

    const gap = 2.0;
    final barWidth = (size.width - (heights.length - 1) * gap) / heights.length;

    for (var i = 0; i < heights.length; i++) {
      final h = heights[i].clamp(3.0, size.height);
      final x = i * (barWidth + gap);
      paint.strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x + barWidth / 2, (size.height - h) / 2),
        Offset(x + barWidth / 2, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
