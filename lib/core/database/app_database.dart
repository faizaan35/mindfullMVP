import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'mindfull_core.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. App Sessions (Granular attention sessions)
    await db.execute('''
      CREATE TABLE app_sessions (
        id TEXT PRIMARY KEY,
        package_name TEXT NOT NULL,
        display_name TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        is_intentional INTEGER,
        date_key TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_sessions_date ON app_sessions(date_key)');
    await db.execute('CREATE INDEX idx_sessions_pkg ON app_sessions(package_name)');

    // 2. Daily Intentions
    await db.execute('''
      CREATE TABLE daily_intentions (
        id TEXT PRIMARY KEY,
        date_key TEXT NOT NULL UNIQUE,
        intention_text TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_accomplished INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Tasks
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        priority INTEGER DEFAULT 1
      )
    ''');

    // 4. Habits
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 5. Habit Logs
    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date_key TEXT NOT NULL,
        completed_at INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // 6. Mindful Check-ins
    await db.execute('''
      CREATE TABLE check_ins (
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        date_key TEXT NOT NULL,
        mood TEXT NOT NULL,
        score INTEGER NOT NULL,
        note TEXT
      )
    ''');

    // 7. Journal Entries
    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        date_key TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        prompt_type TEXT
      )
    ''');

    // 8. Key-Value Settings Cache
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
