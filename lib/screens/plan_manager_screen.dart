import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/exercise_category.dart';
import '../models/exercise_plan.dart';
import '../services/database_service.dart';

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({super.key});

  @override
  State<PlanManagerScreen> createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  ExercisePlan? _plan;
  List<Exercise> _exercises = [];
  List<ExerciseCategory> _categories = [];
  Set<int> _selected = {};
  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plan = await DatabaseService.getActivePlan();
      final exercises = await DatabaseService.getAllExercisesByCategoryOrder();
      final categories = await DatabaseService.getAllCategories();
      final ids = await DatabaseService.getPlanExerciseIds(plan.id!);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _exercises = exercises;
        _categories = categories;
        _selected = ids.toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('计划里至少保留一个动作'), backgroundColor: Colors.orange));
      return;
    }
    final ordered = _exercises
        .where((e) => e.id != null && _selected.contains(e.id))
        .map((e) => e.id!)
        .toList();
    await DatabaseService.replacePlanExercises(plan.id!, ordered);
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('运动计划已保存'), backgroundColor: Color(0xFF00A86B)));
    Navigator.pop(context, true);
  }

  ExerciseCategory? _cat(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  IconData _icon(String n) {
    return switch (n) {
      'self_improvement' => Icons.self_improvement,
      'fitness_center' => Icons.fitness_center,
      'directions_run' => Icons.directions_run,
      'spa' => Icons.spa,
      'accessibility_new' => Icons.accessibility_new,
      'sports_gymnastics' => Icons.sports_gymnastics,
      'pool' => Icons.pool,
      'directions_bike' => Icons.directions_bike,
      'hiking' => Icons.hiking,
      'monitor_heart' => Icons.monitor_heart,
      'psychology' => Icons.psychology,
      'air' => Icons.air,
      'whatshot' => Icons.whatshot,
      'ac_unit' => Icons.ac_unit,
      'wb_sunny' => Icons.wb_sunny,
      'nightlight' => Icons.nightlight,
      'local_fire_department' => Icons.local_fire_department,
      'bolt' => Icons.bolt,
      _ => Icons.fitness_center,
    };
  }

  void _toggle(Exercise e) {
    final id = e.id;
    if (id == null) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _dirty = true;
    });
  }

  void _selectAll() {
    setState(() {
      _selected = _exercises.map((e) => e.id).whereType<int>().toSet();
      _dirty = true;
    });
  }

  void _clear() {
    setState(() {
      _selected.clear();
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('运动计划',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context, _dirty)),
          actions: [
            TextButton(
                onPressed: _dirty ? _save : null,
                child: Text('保存',
                    style: TextStyle(
                        color:
                            _dirty ? const Color(0xFFFF6B35) : Colors.white24,
                        fontWeight: FontWeight.w600)))
          ]),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : _body());

  Widget _body() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 36), children: [
        _summary(),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
              child:
                  _smallButton('全部加入', Icons.playlist_add_check, _selectAll)),
          const SizedBox(width: 10),
          Expanded(child: _smallButton('清空选择', Icons.remove_done, _clear)),
        ]),
        const SizedBox(height: 22),
        ..._categoryGroups(),
      ]);

  Widget _summary() => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF151932),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(children: [
        Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.14),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.event_note,
                color: Color(0xFFFF6B35), size: 24)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_plan?.name ?? '默认运动计划',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              '已选择 ${_selected.length}/${_exercises.length} 个动作，提醒和随机抽取都会从这里选择',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.36),
                  fontSize: 12,
                  height: 1.4))
        ]))
      ]));

  Widget _smallButton(String text, IconData icon, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF151932),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.06))),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, color: Colors.white54, size: 18),
                const SizedBox(width: 6),
                Text(text,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500))
              ])));

  List<Widget> _categoryGroups() {
    final widgets = <Widget>[];
    for (final cat in _categories) {
      final list = _exercises.where((e) => e.categoryId == cat.id).toList();
      if (list.isEmpty) continue;
      widgets.add(_section(cat, list.length));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(list.map(_exerciseTile));
      widgets.add(const SizedBox(height: 14));
    }
    final uncategorized =
        _exercises.where((e) => _cat(e.categoryId) == null).toList();
    if (uncategorized.isNotEmpty) {
      widgets.add(_plainSection('未分类', uncategorized.length));
      widgets.add(const SizedBox(height: 8));
      widgets.addAll(uncategorized.map(_exerciseTile));
    }
    return widgets;
  }

  Widget _section(ExerciseCategory cat, int count) => Row(children: [
        Icon(_icon(cat.iconName), color: cat.color.withOpacity(0.8), size: 18),
        const SizedBox(width: 8),
        Text(cat.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        _count(count),
      ]);

  Widget _plainSection(String name, int count) => Row(children: [
        const Icon(Icons.fitness_center, color: Colors.white38, size: 18),
        const SizedBox(width: 8),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        _count(count),
      ]);

  Widget _count(int count) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style:
              TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)));

  Widget _exerciseTile(Exercise e) {
    final id = e.id;
    final selected = id != null && _selected.contains(id);
    final cat = _cat(e.categoryId);
    final color = cat?.color ?? const Color(0xFFFF6B35);
    final hasVideo = e.videoSource == 'file' && e.videoPath.trim().isNotEmpty;
    return GestureDetector(
        onTap: () => _toggle(e),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF151932),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected
                        ? const Color(0xFFFF6B35).withOpacity(0.55)
                        : Colors.white.withOpacity(0.05))),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(_icon(cat?.iconName ?? ''),
                      color: color.withOpacity(0.9), size: 21)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(e.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600))),
                      if (hasVideo) _chip('有视频', const Color(0xFF00D68F)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                        '${cat?.name ?? "未分类"} · ${e.durationSeconds}秒 · ${e.difficulty == "easy" ? "简单" : e.difficulty == "medium" ? "中等" : "困难"}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.34),
                            fontSize: 12))
                  ])),
              const SizedBox(width: 10),
              Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xFFFF6B35) : Colors.white24,
                  size: 24)
            ])));
  }

  Widget _chip(String text, Color color) => Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)));
}
