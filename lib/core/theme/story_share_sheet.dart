import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'glass_container.dart';
import 'liquid_glass_theme.dart';

class HuzurStoryShareSheet extends StatefulWidget {
  final String arabicText;
  final String turkishText;
  final String reference;
  final String bookCategory;

  const HuzurStoryShareSheet({
    super.key,
    required this.arabicText,
    required this.turkishText,
    required this.reference,
    this.bookCategory = "Kur'ân-ı Kerîm",
  });

  static Future<void> show(
    BuildContext context, {
    required String arabic,
    required String turkish,
    required String reference,
    String category = "Kur'ân-ı Kerîm",
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HuzurStoryShareSheet(
        arabicText: arabic,
        turkishText: turkish,
        reference: reference,
        bookCategory: category,
      ),
    );
  }

  @override
  State<HuzurStoryShareSheet> createState() => _HuzurStoryShareSheetState();
}

class _HuzurStoryShareSheetState extends State<HuzurStoryShareSheet> {
  final GlobalKey _storyCanvasKey = GlobalKey();
  bool _isExporting = false;
  String _statusMessage = "";

  Future<File?> _captureStoryPng() async {
    try {
      setState(() {
        _isExporting = true;
        _statusMessage = "Yüksek çözünürlüklü hikaye kartı hazırlanıyor...";
      });

      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _storyCanvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/huzur_story_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareToInstagramOrSystem({required String mode}) async {
    HapticFeedback.mediumImpact();
    final file = await _captureStoryPng();
    if (file == null) return;

    final shareCaption =
        "\"${widget.turkishText}\"\n— ${widget.reference}\n\nHuzur";

    if (mode == 'copy') {
      await Clipboard.setData(ClipboardData(text: shareCaption));
    }

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: mode == 'story' ? null : shareCaption,
      subject: "Huzur • ${widget.reference}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.70,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 34,
          enableBlur: true,
          blurSigma: 24,
          goldAccentBorder: true,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Ayet Paylaşım Stüdyosu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Instagram Hikayesi veya WhatsApp için özel tasarım kart",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 18),

              // 9:16 DİKEY INSTAGRAM STORY / X-STYLE SİYAH TUVAL
              Center(
                child: RepaintBoundary(
                  key: _storyCanvasKey,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF050507),
                        borderRadius: BorderRadius.circular(26),
                        gradient: const RadialGradient(
                          center: Alignment(0.0, -0.2),
                          radius: 1.1,
                          colors: [
                            Color(0xFF0B1922),
                            Color(0xFF050507),
                            Color(0xFF030304),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 28,
                      ),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121316),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.65),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Üst X-Style Profil Başlığı
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF0D2E3A),
                                          Color(0xFF06151F),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF64FFDA)
                                            .withOpacity(0.55),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Center(
                                      child: BespokeVectorIcon(
                                        type: BespokeIconType.crescentOrb,
                                        color: Color(0xFFFFE082),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "Huzur",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            const BespokeVectorIcon(
                                              type: BespokeIconType.verifiedSeal,
                                              color: Color(0xFF64FFDA),
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "@huzur • ${widget.bookCategory}",
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color:
                                                Colors.white.withOpacity(0.52),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  BespokeVectorIcon(
                                    type: BespokeIconType.qiblaStar,
                                    color: Colors.white.withOpacity(0.35),
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Arapça / Orijinal Metin
                              if (widget.arabicText.trim().isNotEmpty) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    widget.arabicText,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1.55,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFF8E1),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Türkçe Meal Metni
                              Text(
                                widget.turkishText,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.48,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Sure / Bab Referansı
                              Text(
                                "— ${widget.reference}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64FFDA),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Divider(
                                color: Colors.white.withOpacity(0.08),
                                height: 1,
                              ),
                              const SizedBox(height: 10),

                              // Alt İmza
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "huzur.app",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                      color: Colors.white.withOpacity(0.42),
                                    ),
                                  ),
                                  Text(
                                    "Günün İlhamı",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.white.withOpacity(0.38),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (_isExporting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ),

              // 3 Doğrudan Paylaşım Aksiyon Butonu
              GlassContainer(
                borderRadius: 18,
                goldAccentBorder: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () => _shareToInstagramOrSystem(mode: 'story'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BespokeVectorIcon(
                      type: BespokeIconType.instagramStory,
                      color: Color(0xFFFFE082),
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Instagram Hikayesi Olarak Paylaş",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 18,
                      emeraldGlow: true,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      onTap: () => _shareToInstagramOrSystem(mode: 'whatsapp'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.whatsappShare,
                            color: Color(0xFF64FFDA),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "WhatsApp'ta Paylaş",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64FFDA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      onTap: () => _shareToInstagramOrSystem(mode: 'copy'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.downloadCard,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Kartı İndir / Kopyala",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
