class Exercise {
  final int? id;
  final String name;
  final String description;
  final int categoryId;
  final int durationSeconds;
  final String videoPath;
  final String videoSource;
  final String difficulty;
  final List<String> tags;
  final String equipment;
  final bool isBuiltin;

  const Exercise({
    this.id, required this.name, required this.description,
    required this.categoryId, required this.durationSeconds,
    required this.videoPath, this.videoSource = 'asset',
    required this.difficulty, required this.tags,
    this.equipment = 'none', this.isBuiltin = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name, 'description': description,
    'category_id': categoryId, 'duration_seconds': durationSeconds,
    'video_path': videoPath, 'video_source': videoSource,
    'difficulty': difficulty, 'tags': tags.join(','),
    'equipment': equipment, 'is_builtin': isBuiltin ? 1 : 0,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as int?, name: map['name'] as String,
    description: map['description'] as String,
    categoryId: map['category_id'] as int? ?? 1,
    durationSeconds: map['duration_seconds'] as int,
    videoPath: map['video_path'] as String,
    videoSource: map['video_source'] as String? ?? 'asset',
    difficulty: map['difficulty'] as String,
    tags: (map['tags'] as String).split(',').where((t) => t.isNotEmpty).toList(),
    equipment: map['equipment'] as String? ?? 'none',
    isBuiltin: (map['is_builtin'] as int?) == 1,
  );

  Exercise copyWith({
    int? id, String? name, String? description, int? categoryId,
    int? durationSeconds, String? videoPath, String? videoSource,
    String? difficulty, List<String>? tags, String? equipment, bool? isBuiltin,
  }) => Exercise(
    id: id ?? this.id, name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    videoPath: videoPath ?? this.videoPath,
    videoSource: videoSource ?? this.videoSource,
    difficulty: difficulty ?? this.difficulty,
    tags: tags ?? this.tags,
    equipment: equipment ?? this.equipment,
    isBuiltin: isBuiltin ?? this.isBuiltin,
  );
}
