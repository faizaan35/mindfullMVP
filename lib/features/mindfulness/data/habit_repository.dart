import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/habit.dart';

class HabitRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  HabitRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<List<Habit>> getHabits(String todayDateKey) async {
    final db = await _db.database;
    final rows = await db.query('habits', orderBy: 'created_at DESC');
    return rows.map((r) => Habit.fromMap(r, todayDateKey: todayDateKey)).toList();
  }

  Future<Habit> addHabit(String title, {String frequency = 'daily'}) async {
    final db = await _db.database;
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      frequency: frequency,
      streak: 0,
      createdAt: DateTime.now(),
      isCompletedToday: false,
    );
    await db.insert('habits', habit.toMap());
    return habit;
  }

  Future<void> toggleHabitToday(String habitId, String todayDateKey) async {
    final db = await _db.database;
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    if (rows.isEmpty) return;

    final habit = Habit.fromMap(rows.first, todayDateKey: todayDateKey);
    final isDone = habit.isCompletedToday;

    if (isDone) {
      // Uncomplete
      final newStreak = (habit.streak > 0) ? habit.streak - 1 : 0;
      await db.update(
        'habits',
        {
          'streak': newStreak,
          'last_completed_date': null,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );
      await db.delete(
        'habit_logs',
        where: 'habit_id = ? AND date_key = ?',
        whereArgs: [habitId, todayDateKey],
      );
    } else {
      // Complete
      final newStreak = habit.streak + 1;
      await db.update(
        'habits',
        {
          'streak': newStreak,
          'last_completed_date': todayDateKey,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );
      await db.insert(
        'habit_logs',
        {
          'id': _uuid.v4(),
          'habit_id': habitId,
          'date_key': todayDateKey,
          'completed_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await _db.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }
}
