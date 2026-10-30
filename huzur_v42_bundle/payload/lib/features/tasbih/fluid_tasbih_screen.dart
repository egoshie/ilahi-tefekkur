import 'package:flutter/material.dart';
import '../../core/services/tasbih_session_service.dart';
import '../../core/theme/glass_container.dart';

class FluidTasbihScreen extends StatefulWidget {
  const FluidTasbihScreen({super.key});
  @override
  State<FluidTasbihScreen> createState() => _FluidTasbihScreenState();
}

class _FluidTasbihScreenState extends State<FluidTasbihScreen> {
  final TasbihSession _session = TasbihSession.instance;
  @override
  void initState() { super.initState(); _session.load(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _session,
    builder: (context, _) {
      final ratio = _session.target <= 0 ? 0.0 : (_session.count / _session.target).clamp(0.0, 1.0).toDouble();
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 150),
        children: [
          const Text('Zikirmatik',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),
          const Text('Zikir hedefini Esmaül Hüsna listesinden de seçebilirsin.',style:TextStyle(fontSize:12,color:Colors.white70)),
          const SizedBox(height:18),
          GlassContainer(borderRadius:30,emeraldGlow:true,padding:const EdgeInsets.all(22),child:Column(children:[
            Text(_session.label,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:Color(0xFFFFE082))),
            const SizedBox(height:18),
            SizedBox(width:230,height:230,child:Stack(alignment:Alignment.center,children:[
              SizedBox.expand(child:CircularProgressIndicator(value:ratio,strokeWidth:8,backgroundColor:Colors.white12,valueColor:const AlwaysStoppedAnimation(Color(0xFF64FFDA)))),
              Column(mainAxisSize:MainAxisSize.min,children:[
                Text(_session.count.toString(),style:const TextStyle(fontSize:54,fontWeight:FontWeight.w800,color:Colors.white)),
                Text('Hedef ' + _session.target.toString(),style:const TextStyle(fontSize:13,color:Colors.white60)),
              ]),
            ])),
            const SizedBox(height:20),
            SizedBox(width:180,height:180,child:Material(
              color:Colors.transparent,
              child:InkWell(borderRadius:BorderRadius.circular(100),onTap:_session.increment,child:Ink(
                decoration:BoxDecoration(shape:BoxShape.circle,gradient:const LinearGradient(colors:[Color(0xFF64FFDA),Color(0xFF1C8C83)]),boxShadow:[BoxShadow(color:const Color(0xFF64FFDA).withOpacity(0.18),blurRadius:24,spreadRadius:3)]),
                child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.touch_app,color:Color(0xFF04221F),size:34),SizedBox(height:5),Text('ZİKİR',style:TextStyle(color:Color(0xFF04221F),fontWeight:FontWeight.w900,letterSpacing:1.5))])),
              )),
            )),
            const SizedBox(height:16),
            Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              OutlinedButton.icon(onPressed:_session.reset,icon:const Icon(Icons.refresh),label:const Text('Sıfırla')),
              const SizedBox(width:10),
              OutlinedButton.icon(onPressed:() async { await _session.setTarget(value:33,name:'Tesbih'); },icon:const Icon(Icons.restart_alt),label:const Text('33’e dön')),
            ]),
          ])),
          const SizedBox(height:14),
          GlassContainer(borderRadius:18,padding:const EdgeInsets.all(14),child:Text('Seçili hedef: ' + _session.label + ' • ' + _session.target.toString() + ' tekrar. Ebced değerleri harf değerlerinin toplamıdır; belirli bir dinî tekrar zorunluluğu anlamına gelmez.',style:const TextStyle(fontSize:11,color:Colors.white70,height:1.45))),
        ],
      );
    },
  );
}
