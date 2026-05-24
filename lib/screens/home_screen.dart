import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/exercise_category.dart';
import '../services/database_service.dart';
import '../services/exercise_service.dart';
import '../services/notification_service.dart';
import 'exercise_screen.dart';
import 'history_screen.dart';
import 'exercise_manager_screen.dart';
import 'category_manager_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  int _todayCount = 0;
  DateTime? _nextReminder;
  bool _reminderEnabled = false;
  List<ExerciseCategory> _categories = [];
  Timer? _refreshTimer;
  late AnimationController _greetingCtrl;
  late Animation<double> _fadeAnim;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _greetingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _greetingCtrl, curve: Curves.easeOut);
    _greetingCtrl.forward();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() { _refreshTimer?.cancel(); _greetingCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final count = await DatabaseService.getTodayCompletedCount();
      final next = await NotificationService.getNextReminder();
      final enabled = await NotificationService.isReminderEnabled();
      final cats = await DatabaseService.getAllCategories();
      if (mounted) setState(() { _todayCount = count; _nextReminder = next; _reminderEnabled = enabled; _categories = cats; });
    } catch (_) {}
  }

  Future<void> _startRandom() async {
    HapticFeedback.mediumImpact();
    final e = await _exerciseService.recommendWithRotation();
    if (e == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('运动库为空，请先添加运动'), backgroundColor: Colors.orange));
      return;
    }
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(exercise: e))).then((_) => _loadData());
  }

  Future<void> _startCategory(int catId) async {
    HapticFeedback.lightImpact();
    final e = await _exerciseService.recommend(preferredCategoryId: catId);
    if (e != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(exercise: e))).then((_) => _loadData());
  }

  Future<void> _toggleReminder() async {
    if (_isToggling) return;
    _isToggling = true;
    try {
      final ns = !_reminderEnabled;
      if (ns) {
        // Request permission FIRST (may show system dialog that suspends Flutter rendering).
        // Once dialog closes, UI updates immediately.
        final granted = await NotificationService.requestPermission();
        if (!granted) { _isToggling = false; return; }
      }
      // Optimistic UI update — responds immediately with no pending dialogs
      setState(() => _reminderEnabled = ns);
      if (ns) {
        await NotificationService.setReminderEnabled(true);
        final prefs = await SharedPreferences.getInstance();
        await NotificationService.scheduleNextReminder(prefs.getInt('reminder_interval') ?? 90);
      } else {
        await NotificationService.setReminderEnabled(false);
        await NotificationService.cancelAll();
      }
    } catch (_) {
      // Scheduling failed — revert the toggle
      setState(() => _reminderEnabled = !_reminderEnabled);
    } finally {
      _isToggling = false;
    }
    _loadData();
  }

  IconData _iconFor(String n) { try { return IconData(int.tryParse(n)??0, fontFamily:'MaterialIcons'); } catch(_) { return Icons.fitness_center; } }

  @override
  Widget build(BuildContext context) {
    final scrollChild = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _header(), const SizedBox(height:24), _reminderCard(), const SizedBox(height:20),
      _quickActions(), const SizedBox(height:24), _statsRow(), const SizedBox(height:28), _categorySection()]);
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20,24,20,32), child: scrollChild);
    final refresher = RefreshIndicator(color: const Color(0xFFFF6B35), onRefresh: _loadData, child: scrollView);
    final fadeTrans = FadeTransition(opacity: _fadeAnim, child: refresher);
    final bodyContent = SafeArea(child: fadeTrans);
    return Scaffold(backgroundColor: const Color(0xFF0A0E21), body: bodyContent, bottomNavigationBar: _bottomNav());
  }
  Widget _header() {
    final h = DateTime.now().hour;
    final g = h < 12 ? '早上好 ☀️' : h < 18 ? '下午好 🌤' : '晚上好 🌙';
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height:4), const Text('今天动了吗？', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]),
      GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())).then((_) => _loadData()),
        child: Container(width:44,height:44, decoration: BoxDecoration(color: const Color(0xFF151932), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))), child: const Icon(Icons.settings_outlined, color: Colors.white38, size:20)))]);
  }

  Widget _reminderCard() {
    final has = _reminderEnabled && _nextReminder != null;
    final until = has ? _nextReminder!.difference(DateTime.now()) : null;
    final overdue = until != null && until.isNegative;
    return GestureDetector(onTap: _toggleReminder, child: AnimatedContainer(duration: const Duration(milliseconds:400), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: _reminderEnabled?[const Color(0xFF1A3A2A),const Color(0xFF0E2618)]:[const Color(0xFF1A1F3A),const Color(0xFF151932)],begin:Alignment.topLeft,end:Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24), border: Border.all(color: _reminderEnabled?const Color(0xFF00D68F).withOpacity(0.2):Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(_reminderEnabled?Icons.notifications_active:Icons.notifications_off, color: _reminderEnabled?const Color(0xFF00D68F):Colors.white38, size:20), const SizedBox(width:8),
            Text(_reminderEnabled?'定时提醒已开启':'提醒已关闭', style: TextStyle(color: _reminderEnabled?const Color(0xFF00D68F):Colors.white.withOpacity(0.5), fontSize:14, fontWeight:FontWeight.w600))]),
          Switch(value:_reminderEnabled, onChanged:(_)=>_toggleReminder(), activeColor:const Color(0xFF00D68F), activeTrackColor:const Color(0xFF00D68F).withOpacity(0.3))]),
        const SizedBox(height:16),
        if (has && !overdue) ...[Text(_fmt(until!), style: const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.bold)), const SizedBox(height:4),
          Text('下次提醒大约 ${_nextReminder!.hour}:${_nextReminder!.minute.toString().padLeft(2,'0')}', style: TextStyle(color:Colors.white.withOpacity(0.35),fontSize:13))]
        else if (overdue) const Text('现在该运动了！', style: TextStyle(color:Color(0xFFFF6B35),fontSize:22,fontWeight:FontWeight.bold))
        else Text('开启提醒，准时起身', style: TextStyle(color:Colors.white.withOpacity(0.4),fontSize:17))])));
  }

  Widget _quickActions() => Row(children: [
    Expanded(child: _actCard('随机抽一个', Icons.shuffle, const Color(0xFFFF6B35), _startRandom)),
    const SizedBox(width:12), Expanded(child: _actCard('管理运动库', Icons.video_library_outlined, const Color(0xFF7C5CFC),
      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseManagerScreen())).then((_) => _loadData())))]);

  Widget _actCard(String l, IconData i, Color c, VoidCallback t) => GestureDetector(onTap:t, child:Container(
    padding: const EdgeInsets.symmetric(vertical:20), decoration: BoxDecoration(color:const Color(0xFF151932), borderRadius:BorderRadius.circular(20), border:Border.all(color:c.withOpacity(0.15))),
    child: Column(children: [Container(width:48,height:48,decoration:BoxDecoration(color:c.withOpacity(0.12),borderRadius:BorderRadius.circular(14)),child:Icon(i,color:c,size:24)), const SizedBox(height:10),
      Text(l, style: TextStyle(color:Colors.white.withOpacity(0.75),fontSize:13,fontWeight:FontWeight.w500))])));

  Widget _statsRow() => Row(children: [
    Expanded(child:_stat('今日完成','$_todayCount','次',const Color(0xFF00D68F),Icons.check_circle)), const SizedBox(width:12),
    Expanded(child:_stat('累计时长','${(_todayCount*45)~/60}','分钟',const Color(0xFFFF6B35),Icons.timer)), const SizedBox(width:12),
    Expanded(child:_stat('连续天数','1','天',const Color(0xFF7C5CFC),Icons.local_fire_department))]);

  Widget _stat(String l, String v, String u, Color c, IconData i) => Container(padding:const EdgeInsets.all(16),
    decoration: BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white.withOpacity(0.05))),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:c.withOpacity(0.6),size:18),const SizedBox(height:10),
      Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(v,style:TextStyle(color:c,fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(width:3),
        Padding(padding:const EdgeInsets.only(bottom:3),child:Text(u,style:TextStyle(color:c.withOpacity(0.5),fontSize:12)))]),
      const SizedBox(height:3), Text(l,style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:11))]));

  Widget _categorySection() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      const Text('按类型开始',style:TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w600)),
      Row(children:[
        GestureDetector(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CategoryManagerScreen())).then((_)=>_loadData()),
          child:Text('管理分类',style:TextStyle(color:Colors.white.withOpacity(0.25),fontSize:13))),
        const SizedBox(width:12),
        GestureDetector(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen())),
          child:Row(children:[Text('历史',style:TextStyle(color:Colors.white.withOpacity(0.35),fontSize:13)),const SizedBox(width:4),Icon(Icons.arrow_forward_ios,size:12,color:Colors.white.withOpacity(0.3))]))])]),
    const SizedBox(height:14),
    GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.7,
      children:_categories.map((c)=>_catCard(c)).toList())]);

  Widget _catCard(ExerciseCategory c) => GestureDetector(onTap:()=>_startCategory(c.id!),child:Container(padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(20),border:Border.all(color:c.color.withOpacity(0.12))),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
      Container(width:40,height:40,decoration:BoxDecoration(color:c.color.withOpacity(0.12),borderRadius:BorderRadius.circular(12)),child:Icon(_iconFor(c.iconName),color:c.color,size:20)),
      const Spacer(), Text(c.name,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w600)),
      const SizedBox(height:2), Text('${c.name}训练',style:TextStyle(color:Colors.white.withOpacity(0.3),fontSize:11))])));

  Widget _bottomNav() => Container(margin:const EdgeInsets.fromLTRB(20,0,20,8),decoration:BoxDecoration(color:const Color(0xFF151932),borderRadius:BorderRadius.circular(20)),
    child:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),child:Row(children:[
      _nav(Icons.home_rounded,'首页',true,null), _nav(Icons.video_library_outlined,'运动库',false,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ExerciseManagerScreen())).then((_)=>_loadData())),
      _nav(Icons.category_outlined,'分类',false,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CategoryManagerScreen())).then((_)=>_loadData())),
      _nav(Icons.settings_outlined,'设置',false,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen())).then((_)=>_loadData()))]))));

  Widget _nav(IconData i,String l,bool a,VoidCallback? t)=>Expanded(child:GestureDetector(onTap:t,child:Container(
    padding:const EdgeInsets.symmetric(vertical:10),decoration:BoxDecoration(color:a?const Color(0xFFFF6B35).withOpacity(0.12):Colors.transparent,borderRadius:BorderRadius.circular(14)),
    child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(i,size:22,color:a?const Color(0xFFFF6B35):Colors.white38),const SizedBox(height:2),
      Text(l,style:TextStyle(color:a?const Color(0xFFFF6B35):Colors.white.withOpacity(0.3),fontSize:10,fontWeight:a?FontWeight.w600:FontWeight.normal))]))));

  String _fmt(Duration d) { if(d.inHours>0) return '${d.inHours}小时${d.inMinutes%60}分钟'; if(d.inMinutes>0) return '${d.inMinutes}分钟'; return '${d.inSeconds}秒'; }
}
