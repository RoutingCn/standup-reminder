import 'package:flutter/material.dart'; import 'package:intl/intl.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<Map<String,dynamic>> _recs=[]; Map<String,int> _ws={}; bool _loading=true;
  late AnimationController _fc; late Animation<double> _fa;

  @override
  void initState() { super.initState(); _fc=AnimationController(vsync:this,duration:const Duration(milliseconds:500)); _fa=CurvedAnimation(parent:_fc,curve:Curves.easeOut); _fc.forward(); _load(); }
  @override
  void dispose() { _fc.dispose(); super.dispose(); }

  Future<void> _load() async {
    try { final r=await DatabaseService.getHistoryWithExercises(limit:50); final s=await DatabaseService.getDailyStats(7); if(mounted) setState((){_recs=r;_ws=s;_loading=false;}); }
    catch(_) { if(mounted) setState(()=>_loading=false); }
  }

  @override
  Widget build(BuildContext c) => Scaffold(backgroundColor:const Color(0xFF0A0E21),
    appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:const Text('运动记录',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),centerTitle:true,
      leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white,size:22),onPressed:()=>Navigator.pop(c))),
    body:_loading?const Center(child:CircularProgressIndicator(color:Color(0xFFFF6B35))):FadeTransition(opacity:_fa,child:_recs.isEmpty?_empty():_content()));

  Widget _empty()=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Container(width:80,height:80,decoration:BoxDecoration(color:Colors.white.withOpacity(0.04),shape:BoxShape.circle),child:Icon(Icons.fitness_center,size:36,color:Colors.white.withOpacity(0.12))),const SizedBox(height:16),Text('还没有运动记录',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:16)),const SizedBox(height:6),Text('完成一次运动后这里就会出现记录',style:TextStyle(color:Colors.white.withOpacity(0.15),fontSize:13))]));

  Widget _content()=>SingleChildScrollView(physics:const BouncingScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,8,20,32),child:Column(children:[_weekChart(),const SizedBox(height:24),_groups()]));

  Widget _weekChart() {
    final today=DateTime.now(); final days=List.generate(7,(i)=>today.subtract(Duration(days:6-i))); final mx=_ws.values.fold<int>(0,(a,b)=>a>b?a:b);
    return Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(24),border:Border.all(color:Colors.white.withOpacity(0.05))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('过去 7 天',style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w600)),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),decoration:BoxDecoration(color:const Color(0xFFFF6B35).withOpacity(0.12),borderRadius:BorderRadius.circular(12)),child:Text('${_ws.values.fold<int>(0,(a,b)=>a+b)} 次',style:const TextStyle(color:Color(0xFFFF6B35),fontSize:12,fontWeight:FontWeight.w600)))]),
      const SizedBox(height:20),
      Row(crossAxisAlignment:CrossAxisAlignment.end,children:days.map((d){final dk=DateFormat('yyyy-MM-dd').format(d);final cnt=_ws[dk]??0;final isT=d.day==today.day&&d.month==today.month&&d.year==today.year;final bh=mx>0?(cnt/mx*100).clamp(4.0,100.0):4.0;
        return Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:Column(children:[Text('$cnt',style:TextStyle(color:cnt>0?const Color(0xFFFF6B35):Colors.white.withOpacity(0.15),fontSize:12,fontWeight:FontWeight.w600)),const SizedBox(height:8),AnimatedContainer(duration:const Duration(milliseconds:600),curve:Curves.easeOutCubic,height:bh,decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:isT?[const Color(0xFFFF6B35),const Color(0xFFFF8F65)]:cnt>0?[const Color(0xFFFF6B35).withOpacity(0.5),const Color(0xFFFF8F65).withOpacity(0.2)]:[Colors.white.withOpacity(0.06),Colors.white.withOpacity(0.03)]),borderRadius:BorderRadius.circular(8))),const SizedBox(height:8),Text(DateFormat('E','zh_CN').format(d).replaceAll('星期','周'),style:TextStyle(color:isT?Colors.white.withOpacity(0.6):Colors.white.withOpacity(0.2),fontSize:10,fontWeight:isT?FontWeight.w600:FontWeight.normal))])));}).toList())]));
  }

  Widget _groups() {
    final g=<String,List<Map<String,dynamic>>>{};
    for(final r in _recs){ final d=(r['scheduled_at'] as String).substring(0,10); g.putIfAbsent(d,()=>[]).add(r); }
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:g.entries.map((e){final done=e.value.where((r)=>r['completed']==1).length;
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[Text(_fmtDate(e.key),style:const TextStyle(color:Colors.white70,fontSize:15,fontWeight:FontWeight.w600)),const SizedBox(width:8),Text('$done/${e.value.length} 完成',style:TextStyle(color:Colors.white.withOpacity(0.25),fontSize:12))])),...e.value.map((r)=>_recItem(r)),const SizedBox(height:8)]);}).toList());
  }

  Widget _recItem(Map<String,dynamic> r) {
    final done=r['completed']==1, skip=r['skipped']==1;
    final nm=r['exercise_name']as String? ??'未知', cat=r['category_name']as String? ??'';
    final cl=Color(r['category_color']as int? ??0xFFFF6B35);
    final tm=(r['scheduled_at']as String).substring(11,16);
    IconData i; Color ic; if(done){i=Icons.check_circle;ic=const Color(0xFF00D68F);}else if(skip){i=Icons.cancel;ic=Colors.red.withOpacity(0.3);}else{i=Icons.remove_circle;ic=Colors.white24;}
    return Padding(padding:const EdgeInsets.only(bottom:6),child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:14),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(0.04))),child:Row(children:[Icon(i,color:ic,size:18),const SizedBox(width:12),Expanded(child:Text(nm,style:TextStyle(color:Colors.white.withOpacity(done?0.9:0.4),fontSize:14,fontWeight:FontWeight.w500))),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),decoration:BoxDecoration(color:cl.withOpacity(0.1),borderRadius:BorderRadius.circular(6)),child:Text(cat,style:TextStyle(color:cl.withOpacity(0.7),fontSize:10))),const SizedBox(width:10),Text(tm,style:TextStyle(color:Colors.white.withOpacity(0.2),fontSize:12,fontFeatures:const[FontFeature.tabularFigures()]))])));
  }

  String _fmtDate(String s){final d=DateTime.tryParse(s);if(d==null)return s;final td=DateTime.now();final diff=DateTime(td.year,td.month,td.day).difference(DateTime(d.year,d.month,d.day)).inDays;if(diff==0)return'今天';if(diff==1)return'昨天';if(diff==2)return'前天';return'${d.month}月${d.day}日';}
}
