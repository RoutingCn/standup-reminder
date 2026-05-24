import 'package:flutter/material.dart'; import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  int _iv=90,_md=300; bool _enabled=false;
  late AnimationController _fc; late Animation<double> _fa;

  @override
  void initState() { super.initState(); _fc=AnimationController(vsync:this,duration:const Duration(milliseconds:500)); _fa=CurvedAnimation(parent:_fc,curve:Curves.easeOut); _fc.forward(); _load(); }
  @override
  void dispose() { _fc.dispose(); super.dispose(); }

  Future<void> _load() async { final p=await SharedPreferences.getInstance(); setState((){_iv=p.getInt('reminder_interval')??90;_md=p.getInt('max_duration')??300;_enabled=p.getBool('reminder_enabled')??false;}); }

  Future<void> _svi(int v) async { setState(()=>_iv=v); final p=await SharedPreferences.getInstance(); await p.setInt('reminder_interval',v); if(_enabled) await NotificationService.scheduleNextReminder(v); }
  Future<void> _svd(int v) async { setState(()=>_md=v); final p=await SharedPreferences.getInstance(); await p.setInt('max_duration',v); }

  @override
  Widget build(BuildContext c) => Scaffold(backgroundColor:const Color(0xFF0A0E21),
    appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:const Text('设置',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),centerTitle:true,leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white,size:22),onPressed:()=>Navigator.pop(c))),
    body:FadeTransition(opacity:_fa,child:ListView(physics:const BouncingScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,8,20,40),children:[
      _sec('提醒设置'),S(10),_intervalSel(),S(28),
      _sec('运动偏好'),S(10),_durSel(),S(28),
      _sec('通知'),S(10),_remindCard(),S(36),
      _sec('关于'),S(10),_about()])));

  Widget S(double h)=>SizedBox(height:h);
  Widget _sec(String t)=>Text(t,style:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:12,fontWeight:FontWeight.w600,letterSpacing:1.2));

  Widget _intervalSel() { 
    final o=[_o2('30分钟','频繁提醒',30),_o2('60分钟','每小时',60),_o2('90分钟','推荐',90),_o2('2小时','减少打扰',120)];
    final items = o.map((x){final s=_iv==x['v'];
      return Expanded(child:GestureDetector(onTap:()=>_svi(x['v'] as int),child:AnimatedContainer(duration:const Duration(milliseconds:250),padding:const EdgeInsets.symmetric(vertical:14),decoration:BoxDecoration(color:s?const Color(0xFFFF6B35).withOpacity(0.15):Colors.transparent,borderRadius:BorderRadius.circular(14),border:s?Border.all(color:const Color(0xFFFF6B35).withOpacity(0.3)):null),child:Column(children:[Text(x['l']as String,style:TextStyle(color:s?const Color(0xFFFF6B35):Colors.white.withOpacity(0.5),fontSize:14,fontWeight:s?FontWeight.w600:FontWeight.normal)),S(2),Text(x['d']as String,style:TextStyle(color:s?const Color(0xFFFF6B35).withOpacity(0.6):Colors.white.withOpacity(0.2),fontSize:10))]))));
    }).toList();
    return Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white.withOpacity(0.05))),child:Row(children:items));
  }
  Map<String,dynamic> _o2(String l,String d,int v)=> {'l':l,'d':d,'v':v};

  Widget _durSel() { 
    final o=[_o('30秒',30),_o('60秒',60),_o('90秒',90),_o('不限',300)];
    final items = o.map((x){final s=_md==x['v'];
      return Expanded(child:GestureDetector(onTap:()=>_svd(x['v'] as int),child:AnimatedContainer(duration:const Duration(milliseconds:250),padding:const EdgeInsets.symmetric(vertical:14),decoration:BoxDecoration(color:s?const Color(0xFF7C5CFC).withOpacity(0.12):Colors.transparent,borderRadius:BorderRadius.circular(14),border:s?Border.all(color:const Color(0xFF7C5CFC).withOpacity(0.3)):null),child:Center(child:Text(x['l']as String,style:TextStyle(color:s?const Color(0xFF7C5CFC):Colors.white.withOpacity(0.5),fontSize:14,fontWeight:s?FontWeight.w600:FontWeight.normal))))));
    }).toList();
    return Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white.withOpacity(0.05))),child:Row(children:items));
  }
  Map<String,dynamic> _o(String l,int v)=> {'l':l,'v':v};

  Widget _remindCard()=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(18),border:Border.all(color:_enabled?const Color(0xFF00D68F).withOpacity(0.15):Colors.white.withOpacity(0.05))),child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:_enabled?const Color(0xFF00D68F).withOpacity(0.12):Colors.white.withOpacity(0.06),borderRadius:BorderRadius.circular(14)),child:Icon(_enabled?Icons.notifications_active:Icons.notifications_off,color:_enabled?const Color(0xFF00D68F):Colors.white38,size:22)),S(12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_enabled?'提醒已开启':'提醒已关闭',style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w600)),S(2),Text(_enabled?'每 $_iv 分钟提醒你起身':'开启后会定时提醒你运动',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:12))])),Switch(value:_enabled,onChanged:(v)async{if(v){final g=await NotificationService.requestPermission();if(!g)return;}setState(()=>_enabled=v);try{if(v){await NotificationService.setReminderEnabled(true);await NotificationService.scheduleNextReminder(_iv);}else{await NotificationService.setReminderEnabled(false);await NotificationService.cancelAll();}}catch(_){setState(()=>_enabled=!v);}},activeColor:const Color(0xFF00D68F),activeTrackColor:const Color(0xFF00D68F).withOpacity(0.25))]));

  Widget _about()=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white.withOpacity(0.05))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:40,height:40,decoration:BoxDecoration(gradient:LinearGradient(colors:[const Color(0xFFFF6B35),const Color(0xFFFF8F65)]),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.accessibility_new,color:Colors.white,size:22)),S(12),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('起身 StandUp',style:TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w600)),Text('v1.1.0',style:TextStyle(color:Colors.white24,fontSize:12))])]),S(14),Text('一个简单直接的久坐提醒工具。\n精选动作 + 随机抽取 + 视频陪练 + 全屏跟练。\n可以手动添加自己的运动视频和分类。',style:TextStyle(color:Colors.white.withOpacity(0.35),fontSize:13,height:1.6))]));
}
