import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'glass_container.dart';

const String _huzurShareMarkSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="huzurGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFF0B4"/>
      <stop offset="0.42" stop-color="#D8AE58"/>
      <stop offset="1" stop-color="#8B5D19"/>
    </linearGradient>
  </defs>
  <path d="M11 51V29.5C11 17.9 20.4 9 32 9s21 8.9 21 20.5V51"
        fill="none" stroke="url(#huzurGold)" stroke-width="4.2"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M22 51V30.5c0-5.5 4.5-10 10-10s10 4.5 10 10V51"
        fill="none" stroke="url(#huzurGold)" stroke-width="4.2"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M7 52.5h50M32 20.5v31" fill="none"
        stroke="url(#huzurGold)" stroke-width="4.2"
        stroke-linecap="round"/>
  <path d="M15 42h8M41 42h8" fill="none" stroke="#FFF0B4"
        stroke-width="2.1" stroke-linecap="round" opacity=".9"/>
</svg>
''';

const String _huzurGoldVerifiedSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <defs>
    <linearGradient id="verifiedGold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FFF4BF"/>
      <stop offset="0.35" stop-color="#E4BD66"/>
      <stop offset="0.72" stop-color="#BD8730"/>
      <stop offset="1" stop-color="#825516"/>
    </linearGradient>
  </defs>
  <path d="M12 1.15l2.35 1.65 2.86-.12 1.25 2.57 2.57 1.25-.12 2.86L22.55 12l-1.64 2.35.12 2.86-2.57 1.25-1.25 2.57-2.86-.12L12 22.55l-2.35-1.64-2.86.12-1.25-2.57-2.57-1.25.12-2.86L1.45 12l1.64-2.35-.12-2.86 2.57-1.25 1.25-2.57 2.86.12z"
        fill="url(#verifiedGold)" stroke="#F8E2A0" stroke-width=".55"/>
  <path d="M7.15 12.15l3.05 3.05 6.75-6.8" fill="none"
        stroke="#2B1D08" stroke-width="2.05" stroke-linecap="round"
        stroke-linejoin="round"/>
</svg>
''';

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

  String _shareReferenceLabel() {
    final value = widget.reference.trim();
    if (value.isEmpty) return '';

    // Current Quran call sites send "Surah Name, verse number".
    // Present that as a clean, readable reference without altering other books.
    final quranReference = RegExp(r'^(.+?)\s*,\s*(\d+)\s*$').firstMatch(value);
    if (quranReference != null) {
      return '${quranReference.group(1)} Suresi '
          '${quranReference.group(2)}. Ayet';
    }
    return value;
  }

  Widget _buildStoryCard() {
    const gold = Color(0xFFD8B56A);
    const mutedGold = Color(0xFFB99A5B);
    const quote = Color(0xFFF5F3EE);
    final displayText = widget.turkishText.trim().isNotEmpty
        ? widget.turkishText.trim()
        : widget.arabic.trim();
    final isArabicFallback = widget.turkishText.trim().isEmpty;
    final reference = _shareReferenceLabel();

    return RepaintBoundary(
      key: _repaintKey,
      child: SizedBox(
        width: _storyWidth,
        height: _storyHeight,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Container(
              width: 318,
              height: 354,
              padding: const EdgeInsets.fromLTRB(21, 20, 21, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF252525), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0B0B0B),
                          border: Border.all(
                            color: const Color(0xFF393021),
                            width: 1,
                          ),
                        ),
                        child: SvgPicture.string(_huzurShareMarkSvg),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Huzur App',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFF4F1EA),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SvgPicture.string(
                        _huzurGoldVerifiedSvg,
                        width: 17,
                        height: 17,
                      ),
                      const Spacer(),
                      SvgPicture.string(
                        _huzurShareMarkSvg,
                        width: 27,
                        height: 27,
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Directionality(
                        textDirection: isArabicFallback
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: _StoryAutoFitText(
                          text: displayText,
                          textAlign: TextAlign.start,
                          maxLines: 12,
                          maxFontSize: 20.5,
                          minFontSize: 13.5,
                          style: const TextStyle(
                            color: quote,
                            height: 1.48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 2,
                          height: 18,
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            reference,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: mutedGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              letterSpacing: 0.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
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
                      color: Color(0xFFFFA21A),
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
                    color: Color(0xFFFFA21A),
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
                                color: Color(0xFFFFA21A),
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
                                color: Color(0xFFFFA21A),
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
