class ExercisePlanItem {
  final int? id;
  final int planId;
  final int exerciseId;
  final int sortOrder;

  const ExercisePlanItem({
    this.id,
    required this.planId,
    required this.exerciseId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'plan_id': planId,
        'exercise_id': exerciseId,
        'sort_order': sortOrder,
      };

  factory ExercisePlanItem.fromMap(Map<String, dynamic> map) =>
      ExercisePlanItem(
        id: map['id'] as int?,
        planId: map['plan_id'] as int,
        exerciseId: map['exercise_id'] as int,
        sortOrder: map['sort_order'] as int? ?? 0,
      );
}
