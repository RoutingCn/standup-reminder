class SessionRecord {
  final int? id;
  final int exerciseId;
  final String scheduledAt;
  final String? startedAt;
  final bool completed;
  final String? completedAt;
  final bool skipped;

  const SessionRecord({
    this.id, required this.exerciseId, required this.scheduledAt,
    this.startedAt, this.completed = false, this.completedAt, this.skipped = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'exercise_id': exerciseId,
    'scheduled_at': scheduledAt, 'started_at': startedAt,
    'completed': completed ? 1 : 0, 'completed_at': completedAt,
    'skipped': skipped ? 1 : 0,
  };

  factory SessionRecord.fromMap(Map<String, dynamic> map) => SessionRecord(
    id: map['id'] as int?, exerciseId: map['exercise_id'] as int,
    scheduledAt: map['scheduled_at'] as String,
    startedAt: map['started_at'] as String?,
    completed: (map['completed'] as int) == 1,
    completedAt: map['completed_at'] as String?,
    skipped: (map['skipped'] as int) == 1,
  );
}
