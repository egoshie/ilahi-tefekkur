import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/v42_models.dart';
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

  static Future< void > show(
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
  State< HuzurStoryShareSheet > createState() => _HuzurStoryShareSheetState();
}

class _HuzurStoryShareSheetState extends State< HuzurStoryShareSheet > {
  static const MethodChannel _mediaChannel =
      MethodChannel('com.ilahi.tefekkur/media');

  final GlobalKey _storyCanvasKey = GlobalKey();
  int _selectedThemeIndex = 0;
  bool _isExporting = false;
  String _statusMessage = "";

  StoryThemePreset get _activeTheme =>
      StoryThemePreset.presets[_selectedThemeIndex % StoryThemePreset.presets.length];

  String get _formattedCaption =>
      "\"${widget.turkishText}\"\n— ${widget.reference}\n\nHuzur";

  Future< Uint8List? > _captureStoryPngBytes() async {
    try {
      if (mounted) {
        setState(() {
          _isExporting = true;
          _statusMessage = "Yüksek çözünürlüklü hikâye kartı hazırlanıyor...";
        });
      }

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 45));

      final boundary = _storyCanvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.75);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Rect _computeShareOrigin(BuildContext ctx) {
    final size = MediaQuery.of(ctx).size;
    final w = size.width > 0 ? size.width : 390.0;
    final h = size.height > 0 ? size.height : 844.0;
    return Rect.fromCenter(
      center: Offset(w / 2.0, h * 0.65),
      width: 120.0,
      height: 60.0,
    );
  }

  Future< void > _shareStory({required bool includeText}) async {
    if (_isExporting) return;
    HapticFeedback.mediumImpact();
    final originRect = _computeShareOrigin(context);
    final pngBytes = await _captureStoryPngBytes();

    if (pngBytes == null) {
      if (mounted) {
        setState(() {
          _statusMessage = "Görsel oluşturulamadı, lütfen tekrar deneyin.";
        });
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/huzur_story_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await Clipboard.setData(ClipboardData(text: _formattedCaption));

      await // Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'huzur_story.png')],
        text: includeText ? _formattedCaption : null,
        subject: "Huzur • ${widget.reference}",
        sharePositionOrigin: originRect,
      );

      if (mounted) {
        setState(() {
          _statusMessage = "Paylaşım menüsü açıldı ve metin panoya kopyalandı.";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = "Paylaşım işlemi tamamlanamadı.";
        });
      }
    }
  }

  Future< void > _saveToPhotosGallery() async {
    if (_isExporting) return;
    HapticFeedback.mediumImpact();
    final originRect = _computeShareOrigin(context);
    final pngBytes = await _captureStoryPngBytes();

    if (pngBytes == null) {
      if (mounted) {
        setState(() {
          _statusMessage = "Görsel oluşturulamadı.";
        });
      }
      return;
    }

    await Clipboard.setData(ClipboardData(text: _formattedCaption));

    try {
      final bool? saved = await _mediaChannel.invokeMethod< bool >(
        'saveImageToGallery',
        {'bytes': pngBytes},
      );

      if (saved == true) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _statusMessage =
                "Kart Fotoğraflar galerisine kaydedildi ve metin kopyalandı.";
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/huzur_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await // Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'huzur_card.png')],
        text: _formattedCaption,
        sharePositionOrigin: originRect,
      );

      if (mounted) {
        setState(() {
          _statusMessage = "Görsel hazırlandı ve metin panoya kopyalandı.";
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = _activeTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.72,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 34,
          enableBlur: true,
          blurSigma: 26,
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
              const SizedBox(height: 12),
              const Text(
                "Paylaşım Stüdyosu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tema seçin, Instagram Hikâyesi olarak paylaşın veya Fotoğraflar'a kaydedin",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List< Widget >.generate(
                    StoryThemePreset.presets.length,
                    (idx) {
                      final item = StoryThemePreset.presets[idx];
                      final isSelected = idx == _selectedThemeIndex;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedThemeIndex = idx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? item.accentColor.withOpacity(0.20)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? item.accentColor
                                    : Colors.white24,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: item.backgroundColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: item.accentColor,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? item.accentColor
                                        : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 310),
                  child: RepaintBoundary(
                    key: _storyCanvasKey,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(24),
                          gradient: RadialGradient(
                            center: const Alignment(0.0, -0.25),
                            radius: 1.15,
                            colors: [
                              theme.cardColor,
                              theme.backgroundColor,
                              const Color(0xFF030305),
                            ],
                            stops: const [0.0, 0.62, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.borderColor,
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.60),
                                  blurRadius: 28,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.06),
                                        border: Border.all(
                                          color: theme.accentColor.withOpacity(0.60),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: BespokeVectorIcon(
                                          type: BespokeIconType.crescentOrb,
                                          color: theme.accentColor,
                                          size: 18,
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
                                              BespokeVectorIcon(
                                                type: BespokeIconType.verifiedSeal,
                                                color: theme.accentColor,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            "@huzur • ${widget.bookCategory}",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withOpacity(0.55),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    BespokeVectorIcon(
                                      type: BespokeIconType.qiblaStar,
                                      color: theme.accentColor.withOpacity(0.45),
                                      size: 17,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                if (widget.arabicText.trim().isNotEmpty) ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      widget.arabicText,
                                      textAlign: TextAlign.right,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        height: 1.50,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFFF8E1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                Text(
                                  widget.turkishText,
                                  maxLines: 7,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  "— ${widget.reference}",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.accentColor,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Divider(
                                  color: Colors.white.withOpacity(0.10),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),

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
                                        color: Colors.white.withOpacity(0.45),
                                      ),
                                    ),
                                    Text(
                                      "Günün İlhamı",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.white.withOpacity(0.42),
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
              ),
              const SizedBox(height: 14),

              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ),

              GlassContainer(
                borderRadius: 18,
                goldAccentBorder: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () => _shareStory(includeText: false),
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
                      "Instagram Hikâyesi Olarak Paylaş",
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
                      onTap: () => _shareStory(includeText: true),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.whatsappShare,
                            color: Color(0xFF64FFDA),
                            size: 17,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              "WhatsApp'ta Paylaş",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64FFDA),
                              ),
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
                      onTap: _saveToPhotosGallery,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BespokeVectorIcon(
                            type: BespokeIconType.downloadCard,
                            color: Colors.white,
                            size: 17,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              "Galeriye Kaydet",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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