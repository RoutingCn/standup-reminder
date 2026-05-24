import 'package:flutter/material.dart';
import '../models/exercise.dart'; import '../models/exercise_category.dart';
import '../services/database_service.dart'; import '../services/video_service.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise;
  const ExerciseFormScreen({super.key, this.exercise});
  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _fk = GlobalKey<FormState>(); late TextEditingController _nc,_dc,_duc;
  List<ExerciseCategory> _cats=[]; int _cid=1; String _diff='easy',_equip='none'; List<String> _tags=[];
  String? _vp; String _vs='asset'; VideoValidationResult? _vr; bool _saving=false,_validating=false,_loading=true;
  bool get _edit => widget.exercise!=null;

  @override
  void initState() {
    super.initState(); final e=widget.exercise;
    _nc=TextEditingController(text:e?.name??''); _dc=TextEditingController(text:e?.description??'');
    _duc=TextEditingController(text:e!=null?e.durationSeconds.toString():'45');
    _diff=e?.difficulty??'easy'; _equip=e?.equipment??'none'; _tags=e!=null?List.from(e.tags):[];
    _vp=e?.videoPath; _vs=e?.videoSource??'asset'; _cid=e?.categoryId??1;
    _loadCats();
  }

  Future<void> _loadCats() async {
    try { final c=await DatabaseService.getAllCategories(); if(mounted) setState((){_cats=c;_loading=false;}); }
    catch(_) { if(mounted) setState(()=>_loading=false); }
  }

  @override
  void dispose() { _nc.dispose(); _dc.dispose(); _duc.dispose(); super.dispose(); }

  Future<void> _pick() async {
    final p=await VideoService.pickVideo(); if(p==null||!mounted) return;
    setState(()=>_validating=true); final r=await VideoService.validateVideo(p);
    if(!mounted) return;
    setState((){_validating=false; if(r.isValid){_vr=r;_vp=p;_vs='file';}else{_vr=r;}});
  }

  Future<void> _save() async {
    if(!_fk.currentState!.validate()) return; setState(()=>_saving=true);
    String fp=_vp??'';
    if(_vs=='file'&&_vp!=null&&_vp!.isNotEmpty) { try{final fn=_vp!.split('/').last; fp=await VideoService.copyToAppStorage(_vp!,fn); }catch(_){fp=_vp!;} }
    final ex=Exercise(id:widget.exercise?.id,name:_nc.text.trim(),description:_dc.text.trim(),categoryId:_cid,durationSeconds:int.tryParse(_duc.text)??45,videoPath:fp,videoSource:_vs,difficulty:_diff,tags:_tags,equipment:_equip,isBuiltin:widget.exercise?.isBuiltin??false);
    try { _edit?await DatabaseService.updateExercise(ex):await DatabaseService.insertExercise(ex); if(mounted) Navigator.pop(context,true); }
    catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('保存失败:$e'),backgroundColor:Colors.red)); }
    finally { if(mounted) setState(()=>_saving=false); }
  }

  void _addTag(String t) { final tg=t.trim(); if(tg.isNotEmpty&&!_tags.contains(tg)) setState(()=>_tags.add(tg)); }

  @override
  Widget build(BuildContext c) {
    if(_loading) return const Scaffold(backgroundColor:Color(0xFF0A0E21),body:Center(child:CircularProgressIndicator(color:Color(0xFFFF6B35))));
    return Scaffold(backgroundColor:const Color(0xFF0A0E21),
      appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:Text(_edit?'编辑动作':'新增动作',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
        leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white,size:22),onPressed:()=>Navigator.pop(c))),
      body:Form(key:_fk,child:ListView(padding:const EdgeInsets.fromLTRB(20,8,20,40),children:[
        _sec('基本信息'),S(12),_tf(_nc,'动作名称',Icons.fitness_center,'例如"颈部侧拉伸"'),S(14),
        _tf(_dc,'动作描述',Icons.description,'描述动作要领',mx:3),S(14),
        Row(children:[Expanded(child:_tf(_duc,'时长(秒)',Icons.timer,'45',nm:true)),S(12),
          Expanded(child:_dd('难度',_diff,[_o('🎯 简单','easy'),_o('🔥 中等','medium'),_o('💪 困难','hard')],(v)=>_diff=v!))]),
        S(26),_sec('分类'),S(12),_catSel(),S(14),
        _dd('器材',_equip,[_o('🆓 无需器材','none'),_o('🪑 椅子','chair'),_o('🧘 瑜伽垫','mat')],(v)=>_equip=v!),S(14),_tagsInput(),
        S(26),_sec('视频文件（可选，可稍后补充）'),S(12),_videoPick(),S(36),_saveBtn(),S(12),
        Center(child:TextButton(onPressed:()=>Navigator.pop(c),child:Text('取消',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:14))))])));
  }

  Widget S(double h) => SizedBox(height:h);
  Widget _sec(String t)=>Text(t,style:TextStyle(color:Colors.white.withOpacity(0.5),fontSize:12,fontWeight:FontWeight.w600,letterSpacing:1.5));
  Widget _tf(TextEditingController c,String l,IconData i,String h,{int mx=1,bool nm=false})=>Container(decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(0.06))),child:TextFormField(controller:c,maxLines:mx,keyboardType:nm?TextInputType.number:TextInputType.text,style:const TextStyle(color:Colors.white,fontSize:15),decoration:InputDecoration(labelText:l,labelStyle:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:13),hintText:h,hintStyle:TextStyle(color:Colors.white.withOpacity(0.15),fontSize:14),prefixIcon:Icon(i,color:Colors.white.withOpacity(0.35),size:20),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14)),validator:(v)=>(v==null||v.trim().isEmpty)?'请填写$l':null));
  Widget _dd(String l,String v,List<Map<String,String>> it,Function(String?) o)=>Container(padding:const EdgeInsets.symmetric(horizontal:14),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(0.06))),child:DropdownButtonHideUnderline(child:DropdownButtonFormField<String>(value:v,dropdownColor:const Color(0xFF1A1F3A),style:const TextStyle(color:Colors.white,fontSize:15),decoration:InputDecoration(labelText:l,labelStyle:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:13),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(vertical:6)),icon:const Icon(Icons.expand_more,color:Colors.white38),items:it.map((x)=>DropdownMenuItem(value:x['v'],child:Text(x['l']!,style:const TextStyle(fontSize:14)))).toList(),onChanged:o)));
  Map<String,String> _o(String l,String v)=> {'l':l,'v':v};

  Widget _catSel()=>Wrap(spacing:8,runSpacing:8,children:_cats.map((c){final s=_cid==c.id;return GestureDetector(onTap:()=>setState(()=>_cid=c.id!),child:AnimatedContainer(duration:const Duration(milliseconds:200),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:s?c.color.withOpacity(0.15):const Color(0xFF151932),borderRadius:BorderRadius.circular(14),border:Border.all(color:s?c.color.withOpacity(0.5):Colors.white.withOpacity(0.06),width:s?1.5:1)),child:Text(c.name,style:TextStyle(color:s?c.color:Colors.white.withOpacity(0.5),fontSize:13,fontWeight:s?FontWeight.w600:FontWeight.normal))));}).toList());

  Widget _tagsInput() { final tc=TextEditingController(); return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(height:44,decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(0.06))),child:TextField(controller:tc,style:const TextStyle(color:Colors.white,fontSize:14),decoration:InputDecoration(hintText:'输入标签后回车',hintStyle:TextStyle(color:Colors.white.withOpacity(0.2),fontSize:13),prefixIcon:Icon(Icons.local_offer,color:Colors.white.withOpacity(0.35),size:18),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:12)),onSubmitted:(v){_addTag(v);tc.clear();})),if(_tags.isNotEmpty)...[S(10),Wrap(spacing:8,runSpacing:6,children:_tags.map((t)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:const Color(0xFFFF6B35).withOpacity(0.15),borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFFF6B35).withOpacity(0.3))),child:Row(mainAxisSize:MainAxisSize.min,children:[Text(t,style:const TextStyle(color:Color(0xFFFF6B35),fontSize:12)),S(6),GestureDetector(onTap:()=>setState(()=>_tags.remove(t)),child:const Icon(Icons.close,size:14,color:Color(0xFFFF6B35)))]))).toList())]]);}

  Widget _videoPick()=>GestureDetector(onTap:_pick,child:AnimatedContainer(duration:const Duration(milliseconds:200),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_vr!=null?VideoService.resultColor(_vr!).withOpacity(0.08):const Color(0xFF151932),borderRadius:BorderRadius.circular(16),border:Border.all(color:_vr!=null?VideoService.resultColor(_vr!).withOpacity(0.4):const Color(0xFFFF6B35).withOpacity(0.3),width:(_vp!=null&&_vp!.isNotEmpty)?1.5:1)),child:Column(children:[
    Icon((_vp!=null&&_vp!.isNotEmpty)?Icons.videocam:Icons.video_library_outlined,color:(_vp!=null&&_vp!.isNotEmpty)?const Color(0xFFFF6B35):Colors.white38,size:36),S(10),
    if(_validating) const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Color(0xFFFF6B35)))
    else if(_vr!=null&&_vr!.isValid) Text(VideoService.formatInfo(_vr!),textAlign:TextAlign.center,style:TextStyle(color:const Color(0xFF00D68F).withOpacity(0.9),fontSize:13,fontWeight:FontWeight.w500))
    else if(_vr!=null&&!_vr!.isValid) Text(_vr!.errorMessage!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.red,fontSize:12))
    else Text((_vp!=null&&_vp!.isNotEmpty)?'已选择视频，点击更换':'点击选择视频（可选）\n支持 MP4 / MOV，最大 80MB',textAlign:TextAlign.center,style:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:13)),
    if(_vp==null||_vp!.isEmpty) Padding(padding:const EdgeInsets.only(top:6),child:Text('没有视频也可以保存，后续可编辑补充',style:TextStyle(color:Colors.white.withOpacity(0.18),fontSize:11)))])));

  Widget _saveBtn()=>SizedBox(height:56,child:ElevatedButton(onPressed:_saving?null:_save,style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFFF6B35),disabledBackgroundColor:const Color(0xFFFF6B35).withOpacity(0.4),foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),elevation:0),child:_saving?const SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(_edit?'保存修改':'添加动作',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600))));
}
