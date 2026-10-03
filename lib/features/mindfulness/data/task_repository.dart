import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/daily_intention.dart';
import '../domain/daily_task.dart';

class TaskRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TaskRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  // --- Intentions ---
  Future<DailyIntention?> getIntentionForDate(String dateKey) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_intentions',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyIntention.fromMap(rows.first);
  }

  Future<DailyIntention> saveIntention(String dateKey, String text) async {
    final db = await _db.database;
    final existing = await getIntentionForDate(dateKey);

    if (existing != null) {
      final updated = existing.copyWith(intentionText: text);
      await db.update(
        'daily_intentions',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return updated;
    } else {
      final intention = DailyIntention(
        id: _uuid.v4(),
        dateKey: dateKey,
        intentionText: text,
        createdAt: DateTime.now(),
        isAccomplished: false,
      );
      await db.insert(
        'daily_intentions',
        intention.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return intention;
    }
  }

  Future<void> toggleIntentionAccomplished(String id, bool isAccomplished) async {
    final db = await _db.database;
    await db.update(
      'daily_intentions',
      {'is_accomplished': isAccomplished ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Tasks ---
  Future<List<DailyTask>> getTasks() async {
    final db = await _db.database;
    final rows = await db.query(
      'tasks',
      orderBy: 'is_completed ASC, priority DESC, created_at DESC',
    );
    return rows.map((r) => DailyTask.fromMap(r)).toList();
  }

  Future<DailyTask?> getTopPendingTask() async {
    final db = await _db.database;
    final rows = await db.query(
      'tasks',
      where: 'is_completed = 0',
      orderBy: 'priority DESC, created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyTask.fromMap(rows.first);
  }

  Future<DailyTask> addTask({
    required String title,
    String? description,
    String? deadline,
    int priority = 1,
  }) async {
    final db = await _db.database;
    final task = DailyTask(
      id: _uuid.v4(),
      title: title,
      description: description,
      deadline: deadline,
      createdAt: DateTime.now(),
      priority: priority,
    );
    await db.insert('tasks', task.toMap());
    return task;
  }

  Future<void> toggleTaskComplete(String id, bool isCompleted) async {
    final db = await _db.database;
    await db.update(
      'tasks',
      {
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await _db.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
