class ExercisePlan {
  final int? id;
  final String name;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;

  const ExercisePlan({
    this.id,
    required this.name,
    this.isDefault = false,
    this.isActive = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'is_default': isDefault ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory ExercisePlan.fromMap(Map<String, dynamic> map) => ExercisePlan(
        id: map['id'] as int?,
        name: map['name'] as String,
        isDefault: (map['is_default'] as int?) == 1,
        isActive: (map['is_active'] as int?) == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
