import 'package:flutter/material.dart';
import '../models/exercise_category.dart'; import '../services/database_service.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});
  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  List<ExerciseCategory> _cats=[]; bool _loading=true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { try{final c=await DatabaseService.getAllCategories();if(mounted)setState((){_cats=c;_loading=false;});}catch(_){if(mounted)setState(()=>_loading=false);}}
  Future<void> _add()=>_editor(null);
  Future<void> _edit(ExerciseCategory c)=>_editor(c);

  Future<void> _editor(ExerciseCategory? ex) async {
    final r=await showDialog<ExerciseCategory>(context:context,barrierDismissible:false,builder:(_)=>_CatEditor(category:ex));
    if(r!=null){ if(ex!=null){await DatabaseService.updateCategory(r);}else{await DatabaseService.insertCategory(r);} _load(); }
  }

  Future<void> _del(ExerciseCategory c) async {
    final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(backgroundColor:const Color(0xFF1A1F3A),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),title:const Text('删除分类',style:TextStyle(color:Colors.white)),content:Text('确定删除「${c.name}」吗？\\n该分类下的运动会移到默认分类。',style:const TextStyle(color:Colors.white60)),actions:[TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('取消',style:TextStyle(color:Colors.white38))),TextButton(onPressed:()=>Navigator.pop(x,true),child:const Text('删除',style:TextStyle(color:Colors.red)))]));
    if(ok==true){ await DatabaseService.deleteCategory(c.id!); _load(); }
  }

  IconData _icon(String n) { try{return IconData(int.tryParse(n)??0,fontFamily:'MaterialIcons');}catch(_){return Icons.fitness_center;} }

  @override
  Widget build(BuildContext c) => Scaffold(backgroundColor:const Color(0xFF0A0E21),
    appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:const Text('分类管理',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,color:Colors.white,size:22),onPressed:()=>Navigator.pop(c))),
    floatingActionButton:FloatingActionButton(onPressed:_add,backgroundColor:const Color(0xFFFF6B35),child:const Icon(Icons.add,color:Colors.white)),
    body:_loading?const Center(child:CircularProgressIndicator(color:Color(0xFFFF6B35))):ListView.builder(padding:const EdgeInsets.fromLTRB(16,8,16,100),itemCount:_cats.length,itemBuilder:(_,i){final ct=_cats[i];
      return Dismissible(
        key: Key('cat_${ct.id}'),
        direction: ct.isBuiltin ? DismissDirection.horizontal : DismissDirection.endToStart,
        confirmDismiss: (_) async { await _del(ct); return false; },
        background: Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:Colors.red.withOpacity(0.15),borderRadius:BorderRadius.circular(16)),alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),child:const Icon(Icons.delete_outline,color:Colors.red)),
        child:GestureDetector(onTap:()=>_edit(ct),child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white.withOpacity(0.05))),child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:ct.color.withOpacity(0.15),borderRadius:BorderRadius.circular(12)),child:Icon(_icon(ct.iconName),color:ct.color,size:22)),const SizedBox(width:14),Expanded(child:Text(ct.name,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w600))),if(ct.isBuiltin)Padding(padding:const EdgeInsets.only(right:8),child:Text('内置',style:TextStyle(color:Colors.white.withOpacity(0.2),fontSize:11))),Icon(Icons.chevron_right,color:Colors.white.withOpacity(0.15),size:18)]))));
    }));
}

// Category editor dialog
class _CatEditor extends StatefulWidget {
  final ExerciseCategory? category;
  const _CatEditor({this.category});
  @override
  State<_CatEditor> createState() => __CatEditorState();
}

class __CatEditorState extends State<_CatEditor> {
  late TextEditingController _nc; String _in='fitness_center'; int _cv=0xFFFF6B35;
  bool get _edit => widget.category!=null;
  @override
  void initState() { super.initState(); final c=widget.category; _nc=TextEditingController(text:c?.name??''); _in=c?.iconName??'fitness_center'; _cv=c?.colorValue??0xFFFF6B35; }
  @override
  void dispose() { _nc.dispose(); super.dispose(); }
  IconData _icon(String n) { try{return IconData(int.tryParse(n)??0,fontFamily:'MaterialIcons');}catch(_){return Icons.fitness_center;} }

  @override
  Widget build(BuildContext c) => Dialog(backgroundColor:const Color(0xFF1A1F3A),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(24)),insetPadding:const EdgeInsets.symmetric(horizontal:24,vertical:40),child:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(_edit?'编辑分类':'新建分类',style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold),textAlign:TextAlign.center),const SizedBox(height:24),
    Container(decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(0.06))),child:TextField(controller:_nc,style:const TextStyle(color:Colors.white,fontSize:15),decoration:InputDecoration(labelText:'分类名称',labelStyle:TextStyle(color:Colors.white.withOpacity(0.4),fontSize:13),prefixIcon:Icon(Icons.label,color:Colors.white.withOpacity(0.35),size:20),border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14)))),
    const SizedBox(height:20),
    Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:10),decoration:BoxDecoration(color:Color(_cv).withOpacity(0.12),borderRadius:BorderRadius.circular(20),border:Border.all(color:Color(_cv).withOpacity(0.3))),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(_icon(_in),color:Color(_cv),size:20),const SizedBox(width:8),Text(_nc.text.isEmpty?'预览':_nc.text,style:TextStyle(color:Color(_cv),fontSize:14,fontWeight:FontWeight.w600))]))),const SizedBox(height:20),
    const Text('选择图标',style:TextStyle(color:Colors.white54,fontSize:13)),const SizedBox(height:10),
    Wrap(spacing:8,runSpacing:8,children:ExerciseCategory.iconPool.entries.map((e){final ic=_icon(e.key);final s=_in==e.key;return GestureDetector(onTap:()=>setState(()=>_in=e.key),child:Container(width:48,height:48,decoration:BoxDecoration(color:s?Color(_cv).withOpacity(0.15):const Color(0xFF151932),borderRadius:BorderRadius.circular(12),border:s?Border.all(color:Color(_cv).withOpacity(0.4),width:1.5):Border.all(color:Colors.white.withOpacity(0.06))),child:Icon(ic,size:22,color:s?Color(_cv):Colors.white38)));}).toList()),const SizedBox(height:18),
    const Text('选择颜色',style:TextStyle(color:Colors.white54,fontSize:13)),const SizedBox(height:10),
    Wrap(spacing:8,runSpacing:8,children:ExerciseCategory.colorPool.map((x){final s=_cv==x;return GestureDetector(onTap:()=>setState(()=>_cv=x),child:AnimatedContainer(duration:const Duration(milliseconds:200),width:36,height:36,decoration:BoxDecoration(color:Color(x),shape:BoxShape.circle,border:s?Border.all(color:Colors.white,width:2.5):null,boxShadow:s?[BoxShadow(color:Color(x).withOpacity(0.5),blurRadius:8)]:[])));}).toList()),const SizedBox(height:28),
    Row(children:[Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(c),style:OutlinedButton.styleFrom(foregroundColor:Colors.white38,side:BorderSide(color:Colors.white.withOpacity(0.1)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(vertical:14)),child:const Text('取消'))),const SizedBox(width:12),Expanded(child:ElevatedButton(onPressed:(){final n=_nc.text.trim();if(n.isEmpty){ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('请输入分类名称'),backgroundColor:Colors.red));return;}final cat=ExerciseCategory(id:widget.category?.id,name:n,iconName:_in,colorValue:_cv,sortOrder:widget.category?.sortOrder??999,isBuiltin:widget.category?.isBuiltin??false);Navigator.pop(c,cat);},style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFFFF6B35),foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(vertical:14)),child:Text(_edit?'保存':'创建')))])]))));
}
