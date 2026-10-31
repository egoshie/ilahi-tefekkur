import 'dart:typed_data';
import 'dart:ui'; as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../core/theme/glass_container.dart';

class StoryShareSheet extends StatefulWidget {
  final String arabic;
  final String turkishText;
  final String reference;
  const StoryShareSheet({super.key, required this.arabic, required this.turkishText, required this.reference});

  static Future<void> show(BuildContext context, {required String arabic, required String turkishText, required String reference}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoryShareSheet(arabic: arabic, turkishText: turkishText, reference: reference),
    );
  }
  @override State<StoryShareSheet> createState() => _StoryShareSheetState();
}

class _StoryShareSheetState extends State<StoryShareSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  static const MethodChannel _mediaChannel = MethodChannel('com.ilahi.tefekkur/media');
  bool _isExporting = false;
  String? _feedbackMessage;

  Future<Uint8List?> _captureStoryPng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) { return null; }
  }

  Future<void> _shareToSocial({required String target}) async {
    if (_isExporting) return;
    setState(() { _isExporting = true; _feedbackMessage = null; });
    HapticFeedback.mediumImpact();
    try {
      final pngBytes = await _captureStoryPng();
      if (pngBytes == null) { setState(() { _isExporting = false; _feedbackMessage = "Görsel oluşturulamadı."; }); return; }
      if (target == "Instagram Hikâye") {
        final ok = await _mediaChannel.invokeMethod<bool>("shareToInstagramStory", {"bytes": pngBytes}) ?? false;
        setState(() { _isExporting = false; _feedbackMessage = ok ? "Instagram Hikâye ekranı açıldı." : "Instagram bulunamadı."; });
      } else if (target == "WhatsApp Durum") {
        await _mediaChannel.invokeMethod<bool>("saveImageToGallery", {"bytes": pngBytes});
        final caption = "${widget.turkishText}\n— ${widget.reference} (Huzur)";
        final ok = await _mediaChannel.invokeMethod<bool>("shareToWhatsAppDirect", {"bytes": pngBytes, "text": caption}) ?? false;
        setState(() { _isExporting = false; _feedbackMessage = ok ? "WhatsApp yönlendirmesi yapıldı." : "WhatsApp bulunamadı."; });
      }
    } catch (_) { setState(() { _isExporting = false; _feedbackMessage = "Hata oluştu."; }); }
  }

  Future<void> _saveDirectlyToGallery() async {
    if (_isExporting) return;
    setState(() { _isExporting = true; _feedbackMessage = null; });
    HapticFeedback.mediumImpact();
    try {
      final pngBytes = await _captureStoryPng();
      if (pngBytes == null) { setState(() => _isExporting = false); return; }
      final saved = await _mediaChannel.invokeMethod<bool>("saveImageToGallery", {"bytes": pngBytes}) ?? false;
      setState(() { _isExporting = false; _feedbackMessage = saved ? "Fotoğraflar galerisine kaydedildi." : "Galeri izni reddedildi."; });
    } catch (_) { setState(() { _isExporting = false; _feedbackMessage = "Hata oluştu."; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF030B18), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Paylaşım Stüdyosu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              width: 320, height: 440,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF030B18), Color(0xFF0E3842)])),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.arabic, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, color: Color(0xFF64FFDA))),
                  const SizedBox(height: 16),
                  Text(widget.turkishText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
                  const SizedBox(height: 12),
                  Text("— " + widget.reference, style: const TextStyle(fontSize: 12, color: Color(0xFFFFE082), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (_feedbackMessage != null) ...[
            const SizedBox(height: 12),
            Text(_feedbackMessage!, style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 16, emeraldGlow: true, padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: () => _shareToSocial(target: "Instagram Hikâye"),
                  child: const Center(child: Text("Instagram Hikâye", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64FFDA)))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  borderRadius: 16, goldAccentBorder: true, padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: () => _shareToSocial(target: "WhatsApp Durum"),
                  child: const Center(child: Text("WhatsApp'ta Paylaş", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFFE082)))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: 16, padding: const EdgeInsets.symmetric(vertical: 12), onTap: _saveDirectlyToGallery,
            child: Center(
              child: _isExporting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Sadece Galeriye Kaydet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
