import 'package:flutter/material.dart';
import '../models/exercise.dart'; import '../models/exercise_category.dart';
import '../services/database_service.dart'; import '../services/video_service.dart';
import 'exercise_form_screen.dart'; import 'category_manager_screen.dart';

class ExerciseManagerScreen extends StatefulWidget {
  const ExerciseManagerScreen({super.key});
  @override
  State<ExerciseManagerScreen> createState() => _ExerciseManagerScreenState();
}

class _ExerciseManagerScreenState extends State<ExerciseManagerScreen> {
  List<Exercise> _ex=[]; List<ExerciseCategory> _cats=[]; bool _loading=true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final e=await DatabaseService.getAllExercises(); final c=await DatabaseService.getAllCategories(); if(mounted) setState((){_ex=e;_cats=c;_loading=false;}); }
    catch(_) { if(mounted) setState(()=>_loading=false); }
  }

  ExerciseCategory? _cat(int id) { try{return _cats.firstWhere((c)=>c.id==id);}catch(_){return null;} }
  IconData _icon(String n) { try{return IconData(int.tryParse(n)??0,fontFamily:'MaterialIcons');}catch(_){return Icons.fitness_center;} }

  Future<void> _del(Exercise e) async {
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(backgroundColor:const Color(0xFF1A1F3A),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),title:const Text('删除动作',style:TextStyle(color:Colors.white)),content:Text('确定删除「${e.name}」吗？',style:const TextStyle(color:Colors.white60)),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('取消',style:TextStyle(color:Colors.white38))),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('删除',style:TextStyle(color:Colors.red)))]));
    if(ok!=true) return; if(e.videoSource=='file') await VideoService.deleteVideo(e.videoPath); await DatabaseService.deleteExercise(e.id!); _load();
  }

  Future<void> _goForm(Exercise? e) async { final r=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>ExerciseFormScreen(exercise:e))); if(r==true) _load(); }

  @override
  Widget build(BuildContext c) {
    final builtin=_ex.where((e)=>e.isBuiltin).toList(), custom=_ex.where((e)=>!e.isBuiltin).toList();
    return Scaffold(backgroundColor:const Color(0xFF0A0E21),
      appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:const Text('运动库管理',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
        leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white,size:22),onPressed:()=>Navigator.pop(c)),
        actions:[IconButton(icon:const Icon(Icons.category_outlined,color:Colors.white54),tooltip:'管理分类',onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CategoryManagerScreen())).then((_)=>_load()))]),
      floatingActionButton:FloatingActionButton(onPressed:()=>_goForm(null),backgroundColor:const Color(0xFFFF6B35),child:const Icon(Icons.add,color:Colors.white)),
      body:_loading?const Center(child:CircularProgressIndicator(color:Color(0xFFFF6B35))):_ex.isEmpty?_empty():ListView(padding:const EdgeInsets.fromLTRB(20,8,20,100),children:[
        if(custom.isNotEmpty)...[_sec('自定义动作',custom.length),S(8),...custom.map((e)=>_card(e))],
        if(builtin.isNotEmpty)...[_sec('预置动作',builtin.length),S(8),...builtin.map((e)=>_card(e))]]));
  }

  Widget S(double h)=>SizedBox(height:h);
  Widget _empty()=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.fitness_center,size:64,color:Colors.white.withOpacity(0.15)),S(16),Text('还没有动作',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:16)),S(20),TextButton.icon(onPressed:()=>_goForm(null),icon:const Icon(Icons.add,color:Color(0xFFFF6B35)),label:const Text('添加第一个动作',style:TextStyle(color:Color(0xFFFF6B35))))]));
  Widget _sec(String t,int n)=>Padding(padding:const EdgeInsets.only(top:20,bottom:4),child:Row(children:[Text(t,style:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:12,fontWeight:FontWeight.w600,letterSpacing:1.2)),S(8),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),decoration:BoxDecoration(color:Colors.white.withOpacity(0.06),borderRadius:BorderRadius.circular(10)),child:Text('$n',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:11)))]));

  Widget _card(Exercise e) { final c=_cat(e.categoryId); final cl=c?.color??const Color(0xFFFF6B35); final ic=c!=null?_icon(c.iconName):Icons.fitness_center;
    return Dismissible(
      key:Key('ex_${e.id}'),
      direction:e.isBuiltin ? DismissDirection.horizontal : DismissDirection.endToStart,
      confirmDismiss:(_) async { await _del(e); return false; },
      background:Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:Colors.red.withOpacity(0.15),borderRadius:BorderRadius.circular(16)),alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),child:const Icon(Icons.delete_outline,color:Colors.red)),
      child:GestureDetector(onTap:()=>_goForm(e),child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white.withOpacity(0.05))),
        child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:cl.withOpacity(0.15),borderRadius:BorderRadius.circular(12)),child:Icon(ic,color:cl,size:22)),S(14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(e.name,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w600))),if(e.isBuiltin)Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:Colors.white.withOpacity(0.06),borderRadius:BorderRadius.circular(6)),child:Text('内置',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:10)))]),S(4),
            Text('${c?.name??"未分类"} · ${e.durationSeconds}秒 · ${e.difficulty=="easy"?"简单":e.difficulty=="medium"?"中等":"困难"}',style:TextStyle(color:Colors.white.withOpacity(0.35),fontSize:12))])),
          Icon(e.isBuiltin?Icons.lock_outline:Icons.chevron_right,color:Colors.white.withOpacity(0.15),size:e.isBuiltin?16:20)]))));}
}
