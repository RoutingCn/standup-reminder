import 'dart:math';
import '../models/exercise.dart';
import '../models/session_record.dart';
import 'database_service.dart';

class ExerciseService {
  final Random _random = Random();
  int? _lastCategoryId;

  Future<Exercise?> recommend({int? preferredCategoryId, int? maxDurationSeconds}) async {
    final all = await DatabaseService.getAllExercises();
    if (all.isEmpty) return null;
    final recent = await DatabaseService.getRecentCompletedSessions(limit: 10);
    final recentIds = recent.map((s) => s.exerciseId).toSet();
    var candidates = all.where((e) => !recentIds.contains(e.id) || recentIds.length >= all.length).toList();
    if (candidates.isEmpty) candidates = all;
    if (preferredCategoryId != null) {
      final f = candidates.where((e) => e.categoryId == preferredCategoryId).toList();
      if (f.isNotEmpty) candidates = f;
    }
    if (maxDurationSeconds != null) {
      final f = candidates.where((e) => e.durationSeconds <= maxDurationSeconds).toList();
      if (f.isNotEmpty) candidates = f;
    }
    return _weightedPick(candidates, recent);
  }

  Future<Exercise?> recommendWithRotation({int? maxDurationSeconds}) async {
    final cats = await DatabaseService.getAllCategories();
    if (cats.isEmpty) return recommend(maxDurationSeconds: maxDurationSeconds);
    int? targetId;
    if (_lastCategoryId != null) {
      final idx = cats.indexWhere((c) => c.id == _lastCategoryId);
      if (idx >= 0) targetId = cats[(idx + 1) % cats.length].id;
    }
    final e = await recommend(preferredCategoryId: targetId, maxDurationSeconds: maxDurationSeconds);
    if (e != null) _lastCategoryId = e.categoryId;
    return e;
  }

  Exercise _weightedPick(List<Exercise> candidates, List<SessionRecord> recent) {
    final lastDone = <int, DateTime>{};
    for (final s in recent) {
      if (!lastDone.containsKey(s.exerciseId) && s.completedAt != null) {
        lastDone[s.exerciseId] = DateTime.parse(s.completedAt!);
      }
    }
    final now = DateTime.now();
    final weights = candidates.map((e) {
      if (e.id == null) return 1.0;
      final t = lastDone[e.id];
      if (t == null) return 10.0;
      return 1.0 + (now.difference(t).inHours / 24.0).clamp(0, 7);
    }).toList();
    final total = weights.reduce((a, b) => a + b);
    var roll = _random.nextDouble() * total;
    for (int i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return candidates[i];
    }
    return candidates.last;
  }
}
