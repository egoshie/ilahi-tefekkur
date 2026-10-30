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
  const HuzurStoryShareSheet({super.key,required this.arabicText,required this.turkishText,required this.reference,this.bookCategory="Kur'ân-ı Kerîm"});

  static Future<void> show(BuildContext context,{required String arabic,required String turkish,required String reference,String category="Kur'ân-ı Kerîm"}) async {
    await showModalBottomSheet<void>(
      context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
      builder:(_)=>HuzurStoryShareSheet(arabicText:arabic,turkishText:turkish,reference:reference,bookCategory:category),
    );
  }

  @override
  State<HuzurStoryShareSheet> createState()=>_HuzurStoryShareSheetState();
}

class _HuzurStoryShareSheetState extends State<HuzurStoryShareSheet> {
  static const MethodChannel _mediaChannel=MethodChannel('com.ilahi.tefekkur/media');
  final GlobalKey _storyCanvasKey=GlobalKey();
  bool _isGenerating=false;
  String _statusMessage='';
  int _selectedTheme=0;
  static const List<Color> _themes=[Color(0xFF050507),Color(0xFF041E1B),Color(0xFF061326),Color(0xFF1F1605)];
  static const List<String> _themeNames=['Gece Siyahı','Zümrüt Kristal','Safir Gece','Kehribar Altın'];

  Future<Uint8List?> _capturePngBytes() async {
    if (!mounted || _isGenerating) return null;
    setState(()=>_isGenerating=true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds:120));
      final renderObject=_storyCanvasKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) throw StateError('Hikâye tuvali henüz hazır değil.');
      final ui.Image image=await renderObject.toImage(pixelRatio:2.5);
      try {
        final data=await image.toByteData(format:ui.ImageByteFormat.png);
        if(data==null) throw StateError('PNG verisi oluşturulamadı.');
        return data.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (error) {
      if(mounted) setState(()=>_statusMessage='Kart hazırlanamadı: ' + error.toString());
      return null;
    } finally {
      if(mounted) setState(()=>_isGenerating=false);
    }
  }

  String get _caption => '“' + widget.turkishText + '”\n— ' + widget.reference + '\n\nHuzur';

  Future<void> _shareCard({required bool storyMode}) async {
    HapticFeedback.mediumImpact();
    final bytes=await _capturePngBytes();
    if(bytes==null || !mounted) return;
    try {
      final temp=await getTemporaryDirectory();
      final file=File(temp.path + '/huzur_story_' + DateTime.now().millisecondsSinceEpoch.toString() + '.png');
      await file.writeAsBytes(bytes,flush:true);
      final render=context.findRenderObject();
      final box=render is RenderBox && render.hasSize ? render : null;
      final fallback=MediaQuery.of(context).size;
      final origin=box!=null ? box.localToGlobal(Offset.zero) & box.size : Rect.fromLTWH(0,0,fallback.width,fallback.height/2);
      await Share.shareXFiles(
        [XFile(file.path,mimeType:'image/png')],
        text:storyMode ? null : _caption,
        subject:'Huzur • ' + widget.reference,
        sharePositionOrigin:origin,
      );
      if(mounted) setState(()=>_statusMessage='Paylaşım menüsü açıldı.');
    } catch(error) {
      if(mounted) setState(()=>_statusMessage='Paylaşım açılamadı: ' + error.toString());
    }
  }

  Future<void> _saveToGalleryAndCopy() async {
    HapticFeedback.mediumImpact();
    final bytes=await _capturePngBytes();
    if(bytes==null || !mounted) return;
    try {
      await _mediaChannel.invokeMethod<bool>('saveImageToGallery',bytes);
      await Clipboard.setData(ClipboardData(text:_caption));
      if(mounted) setState(()=>_statusMessage="Hikaye kartı Fotoğraflar'a kaydedildi ve metin kopyalandı!");
    } on PlatformException catch(error) {
      if(mounted) setState(()=>_statusMessage='Galeriye kaydedilemedi: ' + (error.message ?? 'iOS izinlerini kontrol edin.'));
    } on MissingPluginException {
      if(mounted) setState(()=>_statusMessage='iOS galeri köprüsü bulunamadı. ADIM 3/3 kurulumu gerekli.');
    } catch(error) {
      if(mounted) setState(()=>_statusMessage='Kaydetme başarısız: ' + error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize:0.92,minChildSize:0.72,maxChildSize:0.97,
      builder:(context,scrollController)=>GlassContainer(
        borderRadius:30,enableBlur:true,blurSigma:24,goldAccentBorder:true,
        padding:const EdgeInsets.fromLTRB(18,14,18,22),
        child:ListView(controller:scrollController,children:[
          Center(child:Container(width:44,height:4,decoration:BoxDecoration(color:Colors.white30,borderRadius:BorderRadius.circular(8)))),
          const SizedBox(height:12),
          const Text('Ayet Paylaşım Stüdyosu',textAlign:TextAlign.center,style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Colors.white)),
          const SizedBox(height:4),
          const Text('Instagram Hikâyesi veya WhatsApp için kartını kişiselleştir.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:Colors.white60)),
          const SizedBox(height:12),
          SizedBox(height:40,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:_themes.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(context,index)=>GestureDetector(
            onTap:()=>setState(()=>_selectedTheme=index),
            child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:_themes[index],borderRadius:BorderRadius.circular(13),border:Border.all(color:_selectedTheme==index?const Color(0xFF64FFDA):Colors.white24,width:_selectedTheme==index?2:1)),child:Text(_themeNames[index],style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Colors.white))),
          ))),
          const SizedBox(height:12),
          Center(child: RepaintBoundary(
            key:_storyCanvasKey,
            child:AspectRatio(aspectRatio:9/16,child:Container(
              width:double.infinity,padding:const EdgeInsets.all(18),
              decoration:BoxDecoration(color:_themes[_selectedTheme],borderRadius:BorderRadius.circular(25),gradient:RadialGradient(center:Alignment.topCenter,radius:1.25,colors:[Color.lerp(_themes[_selectedTheme],const Color(0xFF16443D),0.35)!,_themes[_selectedTheme]])),
              child:Center(child: Container(width:double.infinity,padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Colors.white.withOpacity(0.055),borderRadius:BorderRadius.circular(19),border:Border.all(color:Colors.white.withOpacity(0.18))),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[Container(width:34,height:34,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF0D3030)),child:const Icon(Icons.nightlight_round,color:Color(0xFFFFE082),size:19)),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Huzur',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:Colors.white)),Text(widget.bookCategory,style:const TextStyle(fontSize:9,color:Colors.white60))])),const Icon(Icons.verified,color:Color(0xFF64FFDA),size:16)]),
                const SizedBox(height:17),
                if(widget.arabicText.trim().isNotEmpty) ...[Align(alignment:Alignment.centerRight,child:Text(widget.arabicText,textAlign:TextAlign.right,style:const TextStyle(fontSize:20,height:1.55,fontWeight:FontWeight.w700,color:Color(0xFFFFF8E1)))),const SizedBox(height:12)],
                Text(widget.turkishText,style:const TextStyle(fontSize:14,height:1.45,fontWeight:FontWeight.w500,color:Colors.white),maxLines:9,overflow:TextOverflow.fade),
                const SizedBox(height:12),Text('— ' + widget.reference,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Color(0xFF64FFDA))),
                const SizedBox(height:12),const Divider(color:Colors.white12,height:1),const SizedBox(height:8),
                const Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('huzur.app',style:TextStyle(fontSize:10,color:Colors.white54,fontWeight:FontWeight.w600)),Text('Günün İlhamı',style:TextStyle(fontSize:9,color:Colors.white38))]),
              ])))),
            )),
          ))),
          const SizedBox(height:14),
          if(_isGenerating) const Padding(padding:EdgeInsets.only(bottom:10),child:Center(child:Text('Yüksek çözünürlüklü hikâye kartı hazırlanıyor...',style:TextStyle(color:Color(0xFF64FFDA),fontSize:11)))),
          GlassContainer(borderRadius:16,goldAccentBorder:true,padding:const EdgeInsets.symmetric(vertical:13),onTap:()=>_shareCard(storyMode:true),child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.camera_alt,color:Color(0xFFFFE082),size:18),SizedBox(width:9),Text('Instagram Hikâyesi Olarak Paylaş',style:TextStyle(fontWeight:FontWeight.bold,fontSize:13))])),
          const SizedBox(height:9),
          GlassContainer(borderRadius:16,emeraldGlow:true,padding:const EdgeInsets.symmetric(vertical:13),onTap:()=>_shareCard(storyMode:false),child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.chat_bubble_outline,color:Color(0xFF64FFDA),size:18),SizedBox(width:9),Text("WhatsApp'ta Paylaş",style:TextStyle(fontWeight:FontWeight.bold,fontSize:13))])),
          const SizedBox(height:9),
          GlassContainer(borderRadius:16,padding:const EdgeInsets.symmetric(vertical:13),onTap:_saveToGalleryAndCopy,child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.download_rounded,color:Color(0xFF64FFDA),size:18),SizedBox(width:9),Text('Kartı İndir / Kopyala',style:TextStyle(fontWeight:FontWeight.bold,fontSize:13))])),
          if(_statusMessage.isNotEmpty) Padding(padding:const EdgeInsets.only(top:12),child:Text(_statusMessage,textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:_statusMessage.contains('kaydedildi')?const Color(0xFF64FFDA):Colors.white70))),
        ]),
      ),
    );
  }
}
