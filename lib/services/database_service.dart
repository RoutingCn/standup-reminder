import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/exercise.dart';
import '../models/exercise_category.dart';
import '../models/exercise_plan.dart';
import '../models/session_record.dart';

class DatabaseService {
  static Database? _database;
  static const _dbName = 'standup.db';
  static const _dbVersion = 7;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(join(dbPath, _dbName),
        version: _dbVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
      icon_name TEXT NOT NULL DEFAULT 'fitness_center',
      color_value INTEGER NOT NULL DEFAULT 0xFFFF6B35,
      sort_order INTEGER NOT NULL DEFAULT 0, is_builtin INTEGER NOT NULL DEFAULT 0)''');
    await db.execute('''CREATE TABLE exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      description TEXT NOT NULL, category_id INTEGER NOT NULL DEFAULT 0,
      duration_seconds INTEGER NOT NULL, video_path TEXT NOT NULL,
      video_source TEXT NOT NULL DEFAULT 'asset', difficulty TEXT NOT NULL,
      tags TEXT NOT NULL DEFAULT '', equipment TEXT NOT NULL DEFAULT 'none',
      is_builtin INTEGER NOT NULL DEFAULT 0)''');
    await db.execute('''CREATE TABLE session_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT, exercise_id INTEGER NOT NULL,
      scheduled_at TEXT NOT NULL, started_at TEXT, completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT, skipped INTEGER NOT NULL DEFAULT 0)''');
    await _createPlanTables(db);
    await _seedCategories(db);
    await _seedExercises(db);
    await _seedDefaultPlan(db);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Helper: safely add a column if it doesn't exist yet
    Future<bool> _ensureColumn(
        String table, String colName, String colDef) async {
      final cols = await db.rawQuery("PRAGMA table_info($table)");
      if (cols.any((c) => c['name'] == colName)) return false;
      await db.execute("ALTER TABLE $table ADD COLUMN $colDef");
      return true;
    }

    // v1 → v2: add video_source, is_builtin
    if (oldVersion < 2) {
      await _ensureColumn('exercises', 'video_source',
          "video_source TEXT NOT NULL DEFAULT 'asset'");
      if (await _ensureColumn(
          'exercises', 'is_builtin', "is_builtin INTEGER NOT NULL DEFAULT 0")) {
        await db.update('exercises', {'is_builtin': 1});
      }
    }

    // v2 → v3: add categories table, category_id column
    if (oldVersion < 3) {
      await db.execute('''CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
        icon_name TEXT NOT NULL DEFAULT 'fitness_center',
        color_value INTEGER NOT NULL DEFAULT 0xFFFF6B35,
        sort_order INTEGER NOT NULL DEFAULT 0, is_builtin INTEGER NOT NULL DEFAULT 0)''');
      if (await _ensureColumn('exercises', 'category_id',
          "category_id INTEGER NOT NULL DEFAULT 1")) {
        await _seedCategories(db);
        // Migrate old category string values to new category_id
        final cats = await db.query('categories');
        final nameMap = {
          '拉伸': 'stretch',
          '力量': 'strength',
          '灵活度': 'mobility',
          '放松': 'relaxation'
        };
        // Also handle old 'category' column if it existed
        try {
          final oldCols = await db.rawQuery("PRAGMA table_info(exercises)");
          if (oldCols.any((c) => c['name'] == 'category')) {
            for (final cat in cats) {
              final eng = nameMap[cat['name'] as String];
              if (eng != null) {
                await db.update('exercises', {'category_id': cat['id']},
                    where: 'category = ?', whereArgs: [eng]);
              }
            }
            // Drop the old text category column
            await db.execute('ALTER TABLE exercises DROP COLUMN category');
          }
        } catch (_) {/* old 'category' column may not exist */}
      }
    }

    // v3 → v4 (future-proofing): ensure ALL expected columns exist
    // This handles cases where previous migrations were partially applied
    await _ensureColumn('exercises', 'video_source',
        "video_source TEXT NOT NULL DEFAULT 'asset'");
    await _ensureColumn(
        'exercises', 'is_builtin', "is_builtin INTEGER NOT NULL DEFAULT 0");
    await _ensureColumn(
        'exercises', 'category_id', "category_id INTEGER NOT NULL DEFAULT 1");
    // Drop old 'category' column if it still exists (from very first schema)
    try {
      final allCols = await db.rawQuery("PRAGMA table_info(exercises)");
      if (allCols.any((c) => c['name'] == 'category')) {
        await db.execute('ALTER TABLE exercises DROP COLUMN category');
      }
    } catch (_) {/* column may not be droppable in some SQLite versions */}

    if (oldVersion < 6) {
      await _createPlanTables(db);
      await _seedDefaultPlan(db);
    }

    if (oldVersion < 7) {
      await _deleteBuiltinExercise(db, '椅式深蹲', 'chair_squat.mp4');
    }
  }

  static Future<void> _deleteBuiltinExercise(
      Database db, String name, String videoPath) async {
    final rows = await db.query('exercises',
        columns: ['id'],
        where: 'name = ? AND video_path = ? AND is_builtin = 1',
        whereArgs: [name, videoPath],
        limit: 1);
    if (rows.isEmpty) return;
    final id = rows.first['id'] as int;
    await db.delete('exercise_plan_items',
        where: 'exercise_id = ?', whereArgs: [id]);
    await db
        .delete('session_records', where: 'exercise_id = ?', whereArgs: [id]);
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> _createPlanTables(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS exercise_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS exercise_plan_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      plan_id INTEGER NOT NULL,
      exercise_id INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      UNIQUE(plan_id, exercise_id))''');
  }

  static Future<void> _seedDefaultPlan(Database db) async {
    final existing = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT id FROM exercise_plans WHERE is_default = 1 LIMIT 1'));
    final planId = existing ??
        await db.insert('exercise_plans', {
          'name': '默认运动计划',
          'is_default': 1,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
    await db.update('exercise_plans', {'is_active': 0},
        where: 'id <> ?', whereArgs: [planId]);
    await db.update('exercise_plans', {'is_active': 1},
        where: 'id = ?', whereArgs: [planId]);

    final itemCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM exercise_plan_items WHERE plan_id = ?',
            [planId])) ??
        0;
    if (itemCount > 0) return;
    final exercises = await db.rawQuery('''SELECT e.id
      FROM exercises e LEFT JOIN categories c ON e.category_id = c.id
      ORDER BY c.sort_order ASC, e.is_builtin DESC, e.id ASC''');
    for (var i = 0; i < exercises.length; i++) {
      final id = exercises[i]['id'] as int?;
      if (id == null) continue;
      await db.insert(
          'exercise_plan_items',
          {
            'plan_id': planId,
            'exercise_id': id,
            'sort_order': i,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _seedCategories(Database db) async {
    final c = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM categories'));
    if (c != null && c > 0) return;
    final cats = [
      {
        'name': '拉伸',
        'icon_name': 'self_improvement',
        'color_value': 0xFF42A5F5,
        'sort_order': 0
      },
      {
        'name': '力量',
        'icon_name': 'fitness_center',
        'color_value': 0xFFEF5350,
        'sort_order': 1
      },
      {
        'name': '灵活度',
        'icon_name': 'directions_run',
        'color_value': 0xFF66BB6A,
        'sort_order': 2
      },
      {
        'name': '放松',
        'icon_name': 'spa',
        'color_value': 0xFFAB47BC,
        'sort_order': 3
      },
    ];
    for (final c in cats) {
      await db.insert('categories', {...c, 'is_builtin': 1});
    }
  }

  static Future<void> _seedExercises(Database db) async {
    final c = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM exercises'));
    if (c != null && c > 0) return;
    final cats = await db.query('categories', orderBy: 'sort_order');
    final cm = <String, int>{};
    final nm = {
      '拉伸': 'stretch',
      '力量': 'strength',
      '灵活度': 'mobility',
      '放松': 'relaxation'
    };
    for (final c in cats) {
      final e = nm[c['name']];
      if (e != null) cm[e] = c['id'] as int;
    }
    int cid(String k) => cm[k] ?? 1;
    final exes = [
      _e('颈部侧拉伸', '坐直，右手轻拉头部向右侧倾斜，保持15秒后换边。缓解颈部僵硬。', cid('stretch'), 30,
          'neck_stretch.mp4', 'asset', 'easy', 'neck,desk,seated'),
      _e('肩部环绕', '双肩同时向前画圈10次，再向后画圈10次。幅度尽量大。', cid('stretch'), 40,
          'shoulder_rolls.mp4', 'asset', 'easy', 'shoulder,desk,seated'),
      _e('手腕拉伸', '手臂前伸掌心朝前，另一只手轻拉手指向后，保持15秒换手。', cid('stretch'), 30,
          'wrist_stretch.mp4', 'asset', 'easy', 'wrist,desk,seated'),
      _e(
          '坐姿脊柱扭转',
          '坐直，左手放右膝外侧，右手放椅背，缓缓向右扭转。保持15秒换边。',
          cid('stretch'),
          30,
          'spine_twist.mp4',
          'asset',
          'easy',
          'back,spine,desk,seated',
          'chair'),
      _e('胸部伸展', '双手在背后交握，手臂伸直向后抬，感受胸部和肩前的拉伸。', cid('stretch'), 30,
          'chest_opener.mp4', 'asset', 'easy', 'chest,shoulder,standing'),
      _e('站立前屈', '站立，缓慢弯腰让上半身自然下垂。放松颈部和下背部。', cid('stretch'), 30,
          'forward_fold.mp4', 'asset', 'easy', 'back,hamstring,standing'),
      _e('髋屈肌拉伸', '弓箭步姿势，后腿膝盖着地，臀部前推。每侧20秒。', cid('stretch'), 45,
          'hip_flexor.mp4', 'asset', 'medium', 'hip,standing'),
      _e('靠墙静蹲', '背靠墙半蹲，大腿与地面平行，保持30秒。', cid('strength'), 45, 'wall_sit.mp4',
          'asset', 'medium', 'legs,core,standing'),
      _e('桌面俯卧撑', '双手撑在办公桌边缘，身体倾斜做俯卧撑10-12次。', cid('strength'), 40,
          'desk_pushup.mp4', 'asset', 'easy', 'chest,arms,standing'),
      _e('提踵运动', '站立缓慢踮起脚尖至最高点，保持2秒放下。做15次。', cid('strength'), 35,
          'calf_raise.mp4', 'asset', 'easy', 'legs,standing'),
      _e('坐姿抬腿', '坐直，单腿伸直抬起与地面平行保持5秒。每条腿8次。', cid('strength'), 50,
          'leg_raise.mp4', 'asset', 'easy', 'legs,core,seated', 'chair'),
      _e('手臂大回环', '站立，双臂大幅度前后各画圈10次。', cid('mobility'), 35, 'arm_circles.mp4',
          'asset', 'easy', 'shoulder,arms,standing'),
      _e('髋部画圈', '手扶桌子，单腿站立，另一条腿向外画圈8次，换腿。', cid('mobility'), 40,
          'hip_circles.mp4', 'asset', 'medium', 'hip,standing'),
      _e('猫牛式', '手撑桌面交替弓背和塌腰，配合呼吸8轮。', cid('mobility'), 40, 'cat_cow.mp4',
          'asset', 'easy', 'back,spine,standing'),
      _e('踝关节环绕', '坐姿抬脚，脚踝顺/逆时针各转10圈，换脚。', cid('mobility'), 35,
          'ankle_circles.mp4', 'asset', 'easy', 'ankle,seated', 'chair'),
      _e('腹式深呼吸', '闭眼，鼻子深吸4秒屏息2秒嘴慢呼6秒。重复5轮。', cid('relaxation'), 60,
          'deep_breathing.mp4', 'asset', 'easy', 'breathing,relax,seated'),
      _e('20-20-20护眼', '看向6米外物体保持20秒，眨眼保持湿润。', cid('relaxation'), 30,
          'eye_rest.mp4', 'asset', 'easy', 'eyes,relax,seated'),
    ];
    for (final e in exes) {
      await db.insert('exercises', e);
    }
  }

  static Map<String, dynamic> _e(String n, String d, int ci, int dr, String v,
          String vs, String diff, String t,
          [String eq = 'none']) =>
      {
        'name': n,
        'description': d,
        'category_id': ci,
        'duration_seconds': dr,
        'video_path': v,
        'video_source': vs,
        'difficulty': diff,
        'tags': t,
        'equipment': eq,
        'is_builtin': 1
      };

  // Categories CRUD
  static Future<List<ExerciseCategory>> getAllCategories() async {
    final db = await database;
    final m = await db.query('categories', orderBy: 'sort_order ASC, id ASC');
    return m.map((x) => ExerciseCategory.fromMap(x)).toList();
  }

  static Future<ExerciseCategory?> getCategory(int id) async {
    final db = await database;
    final m = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    return m.isEmpty ? null : ExerciseCategory.fromMap(m.first);
  }

  static Future<int> insertCategory(ExerciseCategory cat) async {
    final db = await database;
    return db.insert('categories', cat.toMap());
  }

  static Future<void> updateCategory(ExerciseCategory cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  static Future<bool> deleteCategory(int id) async {
    final db = await database;
    final cat = await getCategory(id);
    if (cat == null || cat.isBuiltin) return false;
    final first = Sqflite.firstIntValue(await db
        .rawQuery('SELECT id FROM categories ORDER BY sort_order LIMIT 1'));
    await db.update('exercises', {'category_id': first ?? 1},
        where: 'category_id = ?', whereArgs: [id]);
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // Exercises CRUD
  static Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final m = await db.query('exercises', orderBy: 'is_builtin DESC, id ASC');
    return m.map((x) => Exercise.fromMap(x)).toList();
  }

  static Future<Exercise?> getExercise(int id) async {
    final db = await database;
    final m = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    return m.isEmpty ? null : Exercise.fromMap(m.first);
  }

  static Future<List<Exercise>> getExercisesByCategory(int categoryId) async {
    final db = await database;
    final m = await db.query('exercises',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'is_builtin DESC, id ASC');
    return m.map((x) => Exercise.fromMap(x)).toList();
  }

  static Future<int> insertExercise(Exercise e) async {
    final db = await database;
    return db.insert('exercises', e.toMap());
  }

  static Future<void> updateExercise(Exercise e) async {
    final db = await database;
    await db.update('exercises', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  static Future<bool> deleteExercise(int id) async {
    final db = await database;
    final e = await getExercise(id);
    if (e == null || e.isBuiltin) return false;
    await db
        .delete('session_records', where: 'exercise_id = ?', whereArgs: [id]);
    await db.delete('exercise_plan_items',
        where: 'exercise_id = ?', whereArgs: [id]);
    await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // Exercise plans
  static Future<ExercisePlan> ensureDefaultPlan() async {
    final db = await database;
    await _createPlanTables(db);
    await _seedDefaultPlan(db);
    final plans =
        await db.query('exercise_plans', where: 'is_default = 1', limit: 1);
    return ExercisePlan.fromMap(plans.first);
  }

  static Future<ExercisePlan> getActivePlan() async {
    final db = await database;
    await ensureDefaultPlan();
    final plans =
        await db.query('exercise_plans', where: 'is_active = 1', limit: 1);
    if (plans.isEmpty) return ensureDefaultPlan();
    return ExercisePlan.fromMap(plans.first);
  }

  static Future<List<int>> getPlanExerciseIds(int planId) async {
    final db = await database;
    final rows = await db.query('exercise_plan_items',
        columns: ['exercise_id'],
        where: 'plan_id = ?',
        whereArgs: [planId],
        orderBy: 'sort_order ASC, id ASC');
    return rows.map((r) => r['exercise_id'] as int).toList();
  }

  static Future<List<Exercise>> getPlanExercises(int planId) async {
    final db = await database;
    final rows = await db.rawQuery('''SELECT e.*
      FROM exercise_plan_items pi JOIN exercises e ON pi.exercise_id = e.id
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE pi.plan_id = ?
      ORDER BY c.sort_order ASC, pi.sort_order ASC, e.id ASC''', [planId]);
    return rows.map((x) => Exercise.fromMap(x)).toList();
  }

  static Future<List<Exercise>> getAllExercisesByCategoryOrder() async {
    final db = await database;
    final rows = await db.rawQuery('''SELECT e.*
      FROM exercises e LEFT JOIN categories c ON e.category_id = c.id
      ORDER BY c.sort_order ASC, e.is_builtin DESC, e.id ASC''');
    return rows.map((x) => Exercise.fromMap(x)).toList();
  }

  static Future<void> replacePlanExercises(
      int planId, List<int> exerciseIds) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('exercise_plan_items',
          where: 'plan_id = ?', whereArgs: [planId]);
      for (var i = 0; i < exerciseIds.length; i++) {
        await txn.insert(
            'exercise_plan_items',
            {
              'plan_id': planId,
              'exercise_id': exerciseIds[i],
              'sort_order': i,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Sessions
  static Future<int> createSession(SessionRecord r) async {
    final db = await database;
    return db.insert('session_records', r.toMap());
  }

  static Future<void> updateSession(SessionRecord r) async {
    final db = await database;
    await db.update('session_records', r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  static Future<List<SessionRecord>> getRecentCompletedSessions(
      {int limit = 30}) async {
    final db = await database;
    final m = await db.query('session_records',
        where: 'completed = 1', orderBy: 'completed_at DESC', limit: limit);
    return m.map((x) => SessionRecord.fromMap(x)).toList();
  }

  static Future<List<Map<String, dynamic>>> getHistoryWithExercises(
      {int limit = 50}) async {
    final db = await database;
    return db.rawQuery(
        '''SELECT sr.*, e.name as exercise_name, c.name as category_name, c.color_value as category_color
      FROM session_records sr JOIN exercises e ON sr.exercise_id = e.id
      LEFT JOIN categories c ON e.category_id = c.id ORDER BY sr.scheduled_at DESC LIMIT ?''',
        [limit]);
  }

  static Future<int> getTodayCompletedCount() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final r = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM session_records WHERE completed = 1 AND scheduled_at LIKE ?",
        ['$today%']);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  static Future<Map<String, int>> getDailyStats(int days) async {
    final db = await database;
    final result = <String, int>{};
    for (int i = 0; i < days; i++) {
      final d = DateTime.now()
          .subtract(Duration(days: i))
          .toIso8601String()
          .substring(0, 10);
      final c = await db.rawQuery(
          "SELECT COUNT(*) as cnt FROM session_records WHERE completed = 1 AND scheduled_at LIKE ?",
          ['$d%']);
      result[d] = Sqflite.firstIntValue(c) ?? 0;
    }
    return result;
  }
}
