import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/session_record.dart';
import 'database_service.dart';

class PlanService {
  static const _lastCategoryKey = 'plan_last_category_id';
  final Random _random = Random();

  Future<Exercise?> recommendFromActivePlan({int? maxDurationSeconds}) async {
    final plan = await DatabaseService.getActivePlan();
    var exercises = await DatabaseService.getPlanExercises(plan.id!);
    exercises = await _withFallback(exercises);
    if (exercises.isEmpty) return null;
    if (maxDurationSeconds != null) {
      final f = exercises
          .where((e) => e.durationSeconds <= maxDurationSeconds)
          .toList();
      if (f.isNotEmpty) exercises = f;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastCategoryId = prefs.getInt(_lastCategoryKey);
    final categories = await DatabaseService.getAllCategories();
    final categoryIds = categories.map((c) => c.id).whereType<int>().toList();
    int? targetCategoryId;
    if (categoryIds.isNotEmpty) {
      final available = exercises.map((e) => e.categoryId).toSet();
      if (lastCategoryId != null && categoryIds.contains(lastCategoryId)) {
        final start = categoryIds.indexOf(lastCategoryId);
        for (var i = 1; i <= categoryIds.length; i++) {
          final id = categoryIds[(start + i) % categoryIds.length];
          if (available.contains(id)) {
            targetCategoryId = id;
            break;
          }
        }
      }
      targetCategoryId ??= categoryIds.firstWhere(
        available.contains,
        orElse: () => exercises.first.categoryId,
      );
    }

    var candidates = exercises;
    if (targetCategoryId != null) {
      final f =
          exercises.where((e) => e.categoryId == targetCategoryId).toList();
      if (f.isNotEmpty) candidates = f;
    }

    final recent = await DatabaseService.getRecentCompletedSessions(limit: 10);
    final recentIds = recent.map((s) => s.exerciseId).toSet();
    final fresh = candidates
        .where((e) => e.id == null || !recentIds.contains(e.id))
        .toList();
    if (fresh.isNotEmpty || recentIds.length < exercises.length) {
      candidates = fresh.isEmpty ? candidates : fresh;
    }

    final videoCandidates = candidates.where(_hasUserVideo).toList();
    if (videoCandidates.isNotEmpty) candidates = videoCandidates;

    final picked = _weightedPick(candidates, recent);
    await prefs.setInt(_lastCategoryKey, picked.categoryId);
    return picked;
  }

  Future<List<Exercise>> _withFallback(List<Exercise> exercises) async {
    if (exercises.isNotEmpty) return exercises;
    return DatabaseService.getAllExercisesByCategoryOrder();
  }

  bool _hasUserVideo(Exercise e) =>
      e.videoSource == 'file' && e.videoPath.trim().isNotEmpty;

  Exercise _weightedPick(
      List<Exercise> candidates, List<SessionRecord> recent) {
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
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return candidates[i];
    }
    return candidates.last;
  }
}
