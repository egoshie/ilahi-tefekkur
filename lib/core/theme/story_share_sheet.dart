import 'dart:typed_data';
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
                      Color(0xFF061522),
                      Color(0xFF0B3540),
                      Color(0xFF07121F),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -100,
                right: -90,
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64FFDA).withValues(alpha: 0.15),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -110,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE082).withValues(alpha: 0.07),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFE082).withValues(alpha: 0.12),
                        blurRadius: 100,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 25),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF64FFDA)
                                  .withValues(alpha: 0.7),
                            ),
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFFE082),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HUZUR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  letterSpacing: 3.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'KALBE DOKUNAN BİR MOLA',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 8,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFF64FFDA),
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              const Color(0xFF64FFDA).withValues(alpha: 0.45),
                        ),
                        color: const Color(0xFF64FFDA).withValues(alpha: 0.08),
                      ),
                      child: const Text(
                        'KUR’ÂN-I KERÎM  •  TEFEKKÜR',
                        style: TextStyle(
                          color: Color(0xFF64FFDA),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 300,
                              child: Text(
                                widget.arabic,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 35,
                                  height: 1.9,
                                  color: Color(0xFFFFF5DC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                            Color(0xFFFFE082),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 300,
                            child: Text(
                              widget.turkishText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                height: 1.65,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      widget.reference,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              const Color(0xFF64FFDA).withValues(alpha: 0.65),
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF15534F),
                            Color(0xFF0D343D),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF64FFDA).withValues(alpha: 0.13),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'UYGULAMAYI AÇ',
                            style: TextStyle(
                              color: Color(0xFF9BFFE8),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFFFE082),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'HUZUR  •  MANEVİYATIN SADE HÂLİ',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                        letterSpacing: 1.8,
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
