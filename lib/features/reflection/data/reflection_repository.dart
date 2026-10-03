import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/check_in_entry.dart';
import '../domain/journal_entry.dart';

class ReflectionRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ReflectionRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  // --- Check-ins ---
  Future<CheckInEntry> recordCheckIn({
    required String dateKey,
    required String mood,
    required int score,
    String? note,
  }) async {
    final db = await _db.database;
    final entry = CheckInEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      dateKey: dateKey,
      mood: mood,
      score: score,
      note: note,
    );
    await db.insert('check_ins', entry.toMap());
    return entry;
  }

  Future<List<CheckInEntry>> getCheckInsForDate(String dateKey) async {
    final db = await _db.database;
    final rows = await db.query(
      'check_ins',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => CheckInEntry.fromMap(r)).toList();
  }

  Future<List<CheckInEntry>> getAllCheckIns() async {
    final db = await _db.database;
    final rows = await db.query('check_ins', orderBy: 'timestamp DESC');
    return rows.map((r) => CheckInEntry.fromMap(r)).toList();
  }

  // --- Journal ---
  Future<JournalEntry> addJournalEntry({
    required String dateKey,
    required String title,
    required String content,
    String? promptType,
  }) async {
    final db = await _db.database;
    final entry = JournalEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      dateKey: dateKey,
      title: title,
      content: content,
      promptType: promptType,
    );
    await db.insert('journal_entries', entry.toMap());
    return entry;
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final db = await _db.database;
    final rows = await db.query('journal_entries', orderBy: 'timestamp DESC');
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  Future<void> deleteJournalEntry(String id) async {
    final db = await _db.database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}
