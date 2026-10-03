import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../domain/app_session.dart';
import '../domain/daily_usage_stats.dart';

class UsageRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  UsageRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<void> recordSession(AppSession session) async {
    final db = await _db.database;

    // Check if session crosses midnight
    final startDateKey = Formatters.formatDateKey(session.startedAt);
    final endDateKey = Formatters.formatDateKey(session.endedAt);

    if (startDateKey != endDateKey) {
      // Midnight rollover! Split the session cleanly at midnight
      final midnight = DateTime(
        session.endedAt.year,
        session.endedAt.month,
        session.endedAt.day,
      );
      final firstPartDuration = midnight.difference(session.startedAt);
      final secondPartDuration = session.endedAt.difference(midnight);

      final session1 = session.copyWith(
        id: _uuid.v4(),
        endedAt: midnight,
        duration: firstPartDuration,
        dateKey: startDateKey,
      );
      final session2 = session.copyWith(
        id: _uuid.v4(),
        startedAt: midnight,
        duration: secondPartDuration,
        dateKey: endDateKey,
      );

      await db.insert(
        'app_sessions',
        session1.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        'app_sessions',
        session2.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.insert(
        'app_sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateSessionIntentionality(String sessionId, bool isIntentional) async {
    final db = await _db.database;
    await db.update(
      'app_sessions',
      {'is_intentional': isIntentional ? 1 : 0},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> tagLatestSessionForPackage(String packageName, bool isIntentional) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_sessions',
      where: 'package_name = ?',
      whereArgs: [packageName],
      orderBy: 'ended_at DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      final id = results.first['id'] as String;
      await updateSessionIntentionality(id, isIntentional);
    }
  }

  Future<List<AppSession>> getSessionsForDate(String dateKey) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'app_sessions',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'started_at ASC',
    );
    return rows.map((r) => AppSession.fromMap(r)).toList();
  }

  Future<DailyUsageStats> getDailyStats(
    String dateKey, {
    Map<String, dynamic>? systemUsageData,
  }) async {
    final sessions = await getSessionsForDate(dateKey);

    // If SQLite has granular sessions, compute aggregates
    if (sessions.isNotEmpty) {
      int totalMs = 0;
      int intentionalMs = 0;
      int classifiedMs = 0;
      final Map<String, List<AppSession>> grouped = {};
      DateTime? firstTime;
      DateTime? lastTime;
      Duration longest = Duration.zero;

      for (final s in sessions) {
        totalMs += s.duration.inMilliseconds;
        if (s.isIntentional != null) {
          classifiedMs += s.duration.inMilliseconds;
          if (s.isIntentional!) {
            intentionalMs += s.duration.inMilliseconds;
          }
        }
        if (s.duration > longest) {
          longest = s.duration;
        }
        if (firstTime == null || s.startedAt.isBefore(firstTime)) {
          firstTime = s.startedAt;
        }
        if (lastTime == null || s.endedAt.isAfter(lastTime)) {
          lastTime = s.endedAt;
        }
        grouped.putIfAbsent(s.packageName, () => []).add(s);
      }

      final List<SingleAppUsage> appList = [];
      grouped.forEach((pkg, appSessions) {
        int appTotalMs = 0;
        int appIntentionalMs = 0;
        int appClassifiedMs = 0;
        Duration appLongest = Duration.zero;

        for (final s in appSessions) {
          appTotalMs += s.duration.inMilliseconds;
          if (s.duration > appLongest) appLongest = s.duration;
          if (s.isIntentional != null) {
            appClassifiedMs += s.duration.inMilliseconds;
            if (s.isIntentional!) appIntentionalMs += s.duration.inMilliseconds;
          }
        }

        final double intRatio = appClassifiedMs > 0
            ? appIntentionalMs / appClassifiedMs
            : 0.5;

        appList.add(SingleAppUsage(
          packageName: pkg,
          displayName: appSessions.first.displayName,
          totalDuration: Duration(milliseconds: appTotalMs),
          sessionCount: appSessions.length,
          longestSession: appLongest,
          intentionalPercentage: intRatio,
        ));
      });

      appList.sort((a, b) => b.totalDuration.compareTo(a.totalDuration));

      final double overallIntentional = classifiedMs > 0
          ? intentionalMs / classifiedMs
          : 0.5;

      return DailyUsageStats(
        dateKey: dateKey,
        totalScreenTime: Duration(milliseconds: totalMs),
        appStats: appList,
        totalSessions: sessions.length,
        longestSession: longest,
        firstSessionTime: firstTime,
        lastSessionTime: lastTime,
        rawSessions: sessions,
        intentionalRatio: overallIntentional,
      );
    }

    // If no SQLite sessions yet, synthesize from real system UsageStatsManager
    if (systemUsageData != null) {
      final int totalMs = (systemUsageData['totalTimeMs'] as num?)?.toInt() ?? 0;
      final rawList = (systemUsageData['appStats'] as List?) ?? [];
      final List<SingleAppUsage> appList = [];

      for (final item in rawList) {
        if (item is Map) {
          final pkg = (item['packageName'] ?? '') as String;
          final name = (item['appName'] ?? pkg) as String;
          final timeMs = (item['totalTimeMs'] as num?)?.toInt() ?? 0;
          if (timeMs > 0) {
            appList.add(SingleAppUsage(
              packageName: pkg,
              displayName: name,
              totalDuration: Duration(milliseconds: timeMs),
              sessionCount: max(1, (timeMs / (10 * 60 * 1000)).ceil()),
              longestSession: Duration(milliseconds: (timeMs * 0.4).toInt()),
            ));
          }
        }
      }

      return DailyUsageStats(
        dateKey: dateKey,
        totalScreenTime: Duration(milliseconds: totalMs),
        appStats: appList,
        totalSessions: appList.fold(0, (sum, a) => sum + a.sessionCount),
        longestSession: appList.isNotEmpty ? appList.first.longestSession : Duration.zero,
        rawSessions: const [],
        intentionalRatio: 0.5,
      );
    }

    return DailyUsageStats.empty(dateKey);
  }

  Future<List<Map<String, dynamic>>> getPast7DaysWeeklySummary() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> days = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = Formatters.formatDateKey(day);
      final stats = await getDailyStats(dateKey);
      days.add({
        'dateKey': dateKey,
        'date': day,
        'dayLabel': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
        'totalMinutes': stats.totalScreenTime.inMinutes,
        'intentionalRatio': stats.intentionalRatio,
        'sessionCount': stats.totalSessions,
      });
    }

    return days;
  }
}
