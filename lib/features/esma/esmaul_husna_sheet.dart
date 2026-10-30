import 'package:flutter/material.dart';
import '../../core/models/v42_models.dart';
import '../../core/services/offline_sacred_repository.dart';
import '../../core/services/tasbih_session_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/story_share_sheet.dart';

class EsmaulHusnaSheet extends StatefulWidget {
  const EsmaulHusnaSheet({super.key});
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const EsmaulHusnaSheet(),
    );
  }
  @override
  State<EsmaulHusnaSheet> createState() => _EsmaulHusnaSheetState();
}

class _EsmaulHusnaSheetState extends State<EsmaulHusnaSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _normalize(String value) {
    const map = {'İ':'i','I':'i','ı':'i','Ş':'s','ş':'s','Ğ':'g','ğ':'g','Ü':'u','ü':'u','Ö':'o','ö':'o','Ç':'c','ç':'c','Â':'a','â':'a','Î':'i','î':'i','Û':'u','û':'u','Ê':'e','ê':'e'};
    var result = value;
    map.forEach((from, to) { result = result.replaceAll(from, to); });
    return result.toLowerCase();
  }

  List<EsmaItem> get _items => OfflineSacredRepository.esma.cast<dynamic>().where((dynamic item) {
    final value = _normalize((item as dynamic).transliteration + ' ' + (item as dynamic).meaning + ' ' + (item as dynamic).arabic);
    return value.contains(_normalize(_query));
  }).toList(growable: false);

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88, minChildSize: 0.62, maxChildSize: 0.96,
      builder: (context, controller) => GlassContainer(
        borderRadius: 30, enableBlur: true, padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(children: [
          Container(width: 44,height: 4,decoration: BoxDecoration(color: Colors.white30,borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 14),
          const Text('99 Esmaül Hüsna',style: TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:Color(0xFFFFE082))),
          const SizedBox(height: 5),
          const Text('İsimleri ara, anlamını oku ve zikir hedefini Zikirmatik’e aktar.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:Colors.white70)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: 'Esma adı veya anlamı ara...', prefixIcon: const Icon(Icons.search,color:Color(0xFF64FFDA)),
              suffixIcon: _query.isEmpty ? null : IconButton(icon:const Icon(Icons.close),onPressed:(){_search.clear();setState(()=>_query='');}),
              filled:true,fillColor:Colors.white.withOpacity(0.07),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: ListView.builder(
            controller: controller, itemCount: _items.length,
            itemBuilder: (context,index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 18, padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Container(width:28,height:28,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFF64FFDA).withOpacity(0.12),borderRadius:BorderRadius.circular(9)),child:Text(item.number.toString(),style:const TextStyle(fontSize:11,color:Color(0xFF64FFDA),fontWeight:FontWeight.bold))),
                      const SizedBox(width:9),
                      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Text(item.transliteration,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:14,color:Color(0xFFFFE082))),
                        const SizedBox(height:3),Text((item as dynamic).meaning,style:const TextStyle(fontSize:12,color:Colors.white70)),
                      ])),
                      Text((item as dynamic).arabic,textDirection:TextDirection.rtl,style:const TextStyle(fontSize:23,color:Color(0xFFFFF8E1))),
                    ]),
                    const SizedBox(height:9),
                    Row(children:[
                      Expanded(child:Text('Ebced değeri: ' + item.abjadValue.toString(),style:const TextStyle(fontSize:11,color:Color(0xFF64FFDA)))),
                      TextButton.icon(onPressed:() async {
                        await TasbihSession.instance.setTarget(value:item.abjadValue,name:item.transliteration);
                        if (context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context).pop();
                          messenger.showSnackBar(SnackBar(content:Text(item.transliteration + ' hedefi Zikirmatik’e aktarıldı.')));
                        }
                      },icon:const Icon(Icons.toll,size:15),label:const Text('Zikirmatik hedefi')),
                      IconButton(tooltip:'Hikâye kartı paylaş',onPressed:()=>HuzurStoryShareSheet.show(context,arabic:(item as dynamic).arabic,turkish:item.transliteration + ' — ' + (item as dynamic).meaning,reference:'Esmaül Hüsna • ' + item.number.toString(),category:'99 Esmaül Hüsna'),icon:const Icon(Icons.ios_share,color:Color(0xFFFFE082),size:19)),
                    ]),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}
