import 'dart:async'; import 'dart:io';
import 'package:flutter/material.dart'; import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart'; import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart'; import '../models/session_record.dart';
import '../services/database_service.dart'; import '../services/notification_service.dart';

class ExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseScreen({super.key, required this.exercise});
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with TickerProviderStateMixin {
  VideoPlayerController? _vc; bool _videoOk=false, _done=false, _full=false, _showCtrl=true;
  Timer? _ctrlHide, _countdown; late int _remain; bool _playing=false; int? _sid;
  String _catName = "";
  late AnimationController _pulse, _complete;
  late Animation<double> _compScale;

  @override
  void initState() {
    super.initState(); _remain = widget.exercise.durationSeconds;
    _pulse = AnimationController(vsync:this,duration:const Duration(milliseconds:1500));
    _complete = AnimationController(vsync:this,duration:const Duration(milliseconds:600));
    _compScale = Tween<double>(begin:1.0,end:1.08).animate(CurvedAnimation(parent:_complete,curve:Curves.easeInOut));
    _complete.repeat(reverse:true);
    _initVideo(); _recordStart(); _loadCat();
  }

  Future<void> _loadCat() async {
    try { final c = await DatabaseService.getCategory(widget.exercise.categoryId); if(mounted&&c!=null) setState(()=>_catName=c.name); } catch(_){}
  }

  Future<void> _initVideo() async {
    try {
      _vc = widget.exercise.videoSource=='asset' ? VideoPlayerController.asset('assets/videos/${widget.exercise.videoPath}') : VideoPlayerController.file(File(widget.exercise.videoPath));
      await _vc!.initialize(); _vc!.setLooping(true);
      if(mounted) setState(()=>_videoOk=true);
    } catch(_) { if(mounted) setState(()=>_videoOk=false); }
  }

  Future<void> _recordStart() async {
    final eid = widget.exercise.id;
    if (eid == null) return;
    final r = SessionRecord(exerciseId:eid,scheduledAt:DateTime.now().toIso8601String(),startedAt:DateTime.now().toIso8601String());
    _sid = await DatabaseService.createSession(r);
  }

  void _start() { setState(()=>_playing=true); _vc?.play(); _pulse.repeat(reverse:true);
    _countdown = Timer.periodic(const Duration(seconds:1),(t){ if(!mounted){t.cancel();return;} if(_remain<=1){t.cancel();_onDone();} setState(()=>_remain--); }); }

  void _toggleFull() { setState((){ _full=!_full;
    if(_full){ SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); _startCtrlHide(); }
    else{ SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); _ctrlHide?.cancel(); _showCtrl=true; }}); }

  void _startCtrlHide() { _ctrlHide?.cancel(); setState(()=>_showCtrl=true); _ctrlHide=Timer(const Duration(seconds:3),()=>{if(mounted)setState(()=>_showCtrl=false)}); }
  void _tapFull() { if(_full) _startCtrlHide(); }

  Future<void> _onDone() async {
    setState((){_done=true;_playing=false;}); _vc?.pause(); _pulse.stop(); _complete.stop(); HapticFeedback.heavyImpact();
    final eid = widget.exercise.id;
    if (_sid!=null && eid != null) await DatabaseService.updateSession(SessionRecord(id:_sid,exerciseId:eid,scheduledAt:DateTime.now().toIso8601String(),completed:true,completedAt:DateTime.now().toIso8601String(),startedAt:DateTime.now().toIso8601String()));
    final prefs = await SharedPreferences.getInstance(); await NotificationService.scheduleNextReminder(prefs.getInt('reminder_interval')??90);
    if(mounted) showDialog(context:context,barrierColor:Colors.black54,builder:(_)=>_doneDialog());
  }

  Future<void> _skip() async {
    final eid = widget.exercise.id;
    if(_sid!=null && eid != null) await DatabaseService.updateSession(SessionRecord(id:_sid,exerciseId:eid,scheduledAt:DateTime.now().toIso8601String(),skipped:true));
    if(mounted) Navigator.pop(context);
  }

  @override
  void dispose() { _countdown?.cancel(); _ctrlHide?.cancel(); _vc?.dispose(); _pulse.dispose(); _complete.dispose(); SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); super.dispose(); }

  @override
  Widget build(BuildContext context) { if(_full) return _buildFull(); return Scaffold(backgroundColor:const Color(0xFF0A0E21),body:SafeArea(child:Column(children:[_topBar(),_videoArea(),Expanded(child:_infoPanel())]))); }

  Widget _buildFull() {
    final bodyWidget = _videoOk && _vc != null
      ? Stack(fit:StackFit.expand,children:[
          FittedBox(fit:BoxFit.cover,child:SizedBox(width:_vc!.value.size.width,height:_vc!.value.size.height,child:VideoPlayer(_vc!))),
          if(_showCtrl) Positioned(top:48,left:0,right:0,child:Center(child:_floatTimer())),
          if(_showCtrl) Positioned(bottom:40,left:24,right:24,child:_fullCtrls()),
        ])
      : Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
          const Icon(Icons.videocam_off,color:Colors.white24,size:48),
          const SizedBox(height:12),
          Text('无视频',style:TextStyle(color:Colors.white.withOpacity(0.3)))]));
    return GestureDetector(onTap:_tapFull,child:Scaffold(backgroundColor:Colors.black,body:bodyWidget));
  }

  Widget _floatTimer() => Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:10),decoration:BoxDecoration(color:Colors.black.withOpacity(0.6),borderRadius:BorderRadius.circular(30)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.timer,color:const Color(0xFFFF6B35).withOpacity(0.9),size:18),const SizedBox(width:8),Text(_fmt(_remain),style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.bold))]));

  Widget _fullCtrls() => Row(mainAxisAlignment:MainAxisAlignment.center,children:[
    _ctrlBtn(_playing?Icons.pause:Icons.play_arrow,(){setState((){_playing=!_playing;_playing?_vc?.play():_vc?.pause();});}), const SizedBox(width:24), _ctrlBtn(Icons.fullscreen_exit,_toggleFull)]);

  Widget _ctrlBtn(IconData i,VoidCallback t) => GestureDetector(onTap:t,child:Container(width:48,height:48,decoration:BoxDecoration(color:Colors.black.withOpacity(0.5),shape:BoxShape.circle),child:Icon(i,color:Colors.white,size:24)));

  Widget _topBar() => Padding(padding:const EdgeInsets.fromLTRB(8,8,16,0),child:Row(children:[
    IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white,size:22),onPressed:()=>Navigator.pop(context)),
    Text(_catName,style:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:13,fontWeight:FontWeight.w500)), const Spacer(),
    if(_videoOk) GestureDetector(onTap:_toggleFull,child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration:BoxDecoration(color:Colors.white.withOpacity(0.08),borderRadius:BorderRadius.circular(20)),
      child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.fullscreen,color:Colors.white54,size:16),const SizedBox(width:4),Text('全屏',style:TextStyle(color:Colors.white.withOpacity(0.5),fontSize:12))])))
  ]));

  Widget _videoArea() => Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),child:ClipRRect(borderRadius:BorderRadius.circular(20),
    child:_videoOk&&_vc!=null?AspectRatio(aspectRatio:_vc!.value.aspectRatio,child:Stack(alignment:Alignment.center,children:[
      VideoPlayer(_vc!), Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withOpacity(0.15),Colors.transparent,Colors.black.withOpacity(0.3)])))),
      if(!_playing) GestureDetector(onTap:_start,child:AnimatedBuilder(animation:_pulse,builder:(_,c)=>Transform.scale(scale:1.0+(_pulse.value*0.05),child:c),child:Container(width:72,height:72,
        decoration:BoxDecoration(color:const Color(0xFFFF6B35).withOpacity(0.9),shape:BoxShape.circle,boxShadow:[BoxShadow(color:const Color(0xFFFF6B35).withOpacity(0.4),blurRadius:24,spreadRadius:4)]),
        child:const Icon(Icons.play_arrow,color:Colors.white,size:38))))
    ])):_videoPlaceholder()));

  Widget _videoPlaceholder() => Container(height:220,decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white.withOpacity(0.06))),
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(_catIcon(),size:56,color:Colors.white.withOpacity(0.15)),const SizedBox(height:14),
      Text('视频即将上线',style:TextStyle(color:Colors.white.withOpacity(0.35),fontSize:15,fontWeight:FontWeight.w500)),
      Text('跟随文字指导完成动作',style:TextStyle(color:Colors.white.withOpacity(0.18),fontSize:13))]));

  IconData _catIcon() { if(_catName.contains('拉伸')) return Icons.self_improvement; if(_catName.contains('力量')) return Icons.fitness_center; if(_catName.contains('灵活')) return Icons.directions_run; if(_catName.contains('放松')) return Icons.spa; return Icons.accessibility_new; }

  Widget _infoPanel() => SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,4,20,30),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(widget.exercise.name,style:const TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.bold,height:1.2))),const SizedBox(width:12),_timerChip()]),
    const SizedBox(height:12), Wrap(spacing:8,runSpacing:6,children:[
      _tag(widget.exercise.difficulty=='easy'?'简单':widget.exercise.difficulty=='medium'?'中等':'困难',widget.exercise.difficulty=='easy'?Colors.green:Colors.orange),
      _tag('${widget.exercise.durationSeconds}秒',const Color(0xFF42A5F5)), ...widget.exercise.tags.take(4).map((t)=>_tag(t,Colors.blueGrey))]),
    const SizedBox(height:20),
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white.withOpacity(0.05))),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.lightbulb_outline,color:const Color(0xFFFFD166).withOpacity(0.7),size:20),const SizedBox(width:12),
        Expanded(child:Text(widget.exercise.description,style:TextStyle(color:Colors.white.withOpacity(0.7),fontSize:14,height:1.7)))])),
    const SizedBox(height:24),
    if(!_done&&!_playing) _btn('开始运动',_start) else if(_playing) _btn('运动中...',null) else _btn('完成 ✓',()=>Navigator.pop(context)),
    if(_playing&&!_done)...[const SizedBox(height:12),_skipBtn()]]));

  Widget _timerChip() => AnimatedContainer(duration:const Duration(milliseconds:300),padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),
    decoration:BoxDecoration(color:_playing?const Color(0xFFFF6B35).withOpacity(0.15):Colors.white.withOpacity(0.06),borderRadius:BorderRadius.circular(20),border:Border.all(color:_playing?const Color(0xFFFF6B35).withOpacity(0.4):Colors.white.withOpacity(0.1))),
    child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.timer,size:18,color:_playing?const Color(0xFFFF6B35):Colors.white38),const SizedBox(width:6),
      Text(_fmt(_remain),style:TextStyle(color:_playing?const Color(0xFFFF6B35):Colors.white54,fontSize:22,fontWeight:FontWeight.bold,fontFeatures:const[FontFeature.tabularFigures()]))]));

  String _fmt(int s) { final m=s~/60,sec=s%60; return m>0?'$m:${sec.toString().padLeft(2,'0')}':'$sec'; }

  Widget _tag(String t,Color c) => Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:c.withOpacity(0.12),borderRadius:BorderRadius.circular(10),border:Border.all(color:c.withOpacity(0.25))),child:Text(t,style:TextStyle(color:c.withOpacity(0.9),fontSize:11,fontWeight:FontWeight.w500)));

  Widget _btn(String t,VoidCallback? o) => SizedBox(height:56,child:ElevatedButton(onPressed:o,style:ElevatedButton.styleFrom(backgroundColor:o!=null?const Color(0xFFFF6B35):const Color(0xFFFF6B35).withOpacity(0.3),foregroundColor:Colors.white,disabledBackgroundColor:const Color(0xFFFF6B35).withOpacity(0.3),disabledForegroundColor:Colors.white70,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),child:Text(t,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600))));

  Widget _skipBtn() => Center(child:TextButton(onPressed:_skip,style:TextButton.styleFrom(foregroundColor:Colors.white.withOpacity(0.3)),child:const Text('跳过这次',style:TextStyle(fontSize:14))));

  Widget _doneDialog() => Dialog(backgroundColor:Colors.transparent,child:Container(padding:const EdgeInsets.symmetric(vertical:32,horizontal:24),
    decoration:BoxDecoration(color:const Color(0xFF1A1F3A),borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFFF6B35).withOpacity(0.2))),
    child:Column(mainAxisSize:MainAxisSize.min,children:[Container(width:72,height:72,decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFFFF6B35),Color(0xFFFF8F65)]),shape:BoxShape.circle),child:const Icon(Icons.check,color:Colors.white,size:38)),
      const SizedBox(height:20), const Text('太棒了！',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.bold)), const SizedBox(height:8),
      Text('完成了「${widget.exercise.name}」\n${widget.exercise.durationSeconds}秒的运动',style:TextStyle(color:Colors.white.withOpacity(0.6),fontSize:15,height:1.5),textAlign:TextAlign.center),
      const SizedBox(height:24), SizedBox(width:double.infinity,height:50,child:ElevatedButton(onPressed:(){Navigator.pop(context);Navigator.pop(context);},
        style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFFF6B35),foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),child:const Text('返回首页',style:TextStyle(fontSize:16,fontWeight:FontWeight.w600))))])));
}
