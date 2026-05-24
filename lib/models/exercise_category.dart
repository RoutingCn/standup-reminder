import 'package:flutter/material.dart';

class ExerciseCategory {
  final int? id;
  final String name;
  final String iconName;
  final int colorValue;
  final int sortOrder;
  final bool isBuiltin;

  const ExerciseCategory({
    this.id, required this.name, required this.iconName,
    required this.colorValue, this.sortOrder = 0, this.isBuiltin = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'name': name, 'icon_name': iconName,
    'color_value': colorValue, 'sort_order': sortOrder,
    'is_builtin': isBuiltin ? 1 : 0,
  };

  factory ExerciseCategory.fromMap(Map<String, dynamic> map) => ExerciseCategory(
    id: map['id'] as int?, name: map['name'] as String,
    iconName: map['icon_name'] as String,
    colorValue: map['color_value'] as int,
    sortOrder: map['sort_order'] as int? ?? 0,
    isBuiltin: (map['is_builtin'] as int?) == 1,
  );

  Color get color => Color(colorValue);

  static const iconPool = {
    'self_improvement': '拉伸/放松', 'fitness_center': '力量训练',
    'directions_run': '有氧/灵活', 'spa': '冥想/放松',
    'accessibility_new': '通用运动', 'sports_gymnastics': '体操',
    'pool': '游泳', 'directions_bike': '骑行', 'hiking': '徒步',
    'monitor_heart': '心肺', 'psychology': '心理健康',
    'air': '呼吸', 'whatshot': '高强度', 'ac_unit': '冷身',
    'wb_sunny': '热身', 'nightlight': '睡前放松',
    'local_fire_department': '燃脂', 'bolt': '爆发力',
  };

  static const colorPool = [
    0xFF42A5F5, 0xFFEF5350, 0xFF66BB6A, 0xFFAB47BC,
    0xFFFF6B35, 0xFFFFD166, 0xFF26C6DA, 0xFFEC407A,
    0xFF7C5CFC, 0xFF8D6E63, 0xFF78909C, 0xFF00D68F,
  ];

  static String colorName(int v) => switch (v) {
    0xFF42A5F5 => '蓝', 0xFFEF5350 => '红', 0xFF66BB6A => '绿',
    0xFFAB47BC => '紫', 0xFFFF6B35 => '橙', 0xFFFFD166 => '黄',
    0xFF26C6DA => '青', 0xFFEC407A => '粉', 0xFF7C5CFC => '靛',
    0xFF8D6E63 => '棕', 0xFF78909C => '灰蓝', 0xFF00D68F => '翠绿',
    _ => '自定义'
  };
}
