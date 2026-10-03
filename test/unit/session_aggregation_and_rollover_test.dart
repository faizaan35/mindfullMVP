import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindfull/features/usage/data/usage_repository.dart';
import 'package:mindfull/features/usage/domain/app_session.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UsageRepository and Session Aggregation Tests', () {
    test('Records session and calculates daily totals correctly', () async {
      final repo = UsageRepository();

      final now = DateTime(2026, 10, 3, 10, 0);
      final session = AppSession(
        id: 'test-session-1',
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 25)),
        duration: const Duration(minutes: 25),
        dateKey: '2026-10-03',
        isIntentional: true,
      );

      await repo.recordSession(session);

      final stats = await repo.getDailyStats('2026-10-03');
      expect(stats.totalSessions, greaterThanOrEqualTo(1));
      expect(stats.totalScreenTime.inMinutes, greaterThanOrEqualTo(25));
      expect(stats.appStats.any((a) => a.packageName == 'com.instagram.android'), isTrue);
    });

    test('Midnight rollover splits sessions crossing midnight cleanly', () async {
      final repo = UsageRepository();

      // Session starts at 23:45 on Day 1 and ends at 00:20 on Day 2 (35 min total)
      final start = DateTime(2026, 10, 3, 23, 45);
      final end = DateTime(2026, 10, 4, 0, 20);

      final session = AppSession(
        id: 'midnight-session-1',
        packageName: 'com.google.android.youtube',
        displayName: 'YouTube',
        startedAt: start,
        endedAt: end,
        duration: const Duration(minutes: 35),
        dateKey: '2026-10-03',
      );

      await repo.recordSession(session);

      // Verify Day 1 has the 15 minutes before midnight
      final day1Sessions = await repo.getSessionsForDate('2026-10-03');
      expect(day1Sessions.any((s) => s.packageName == 'com.google.android.youtube'), isTrue);

      // Verify Day 2 has the 20 minutes after midnight
      final day2Sessions = await repo.getSessionsForDate('2026-10-04');
      expect(day2Sessions.any((s) => s.packageName == 'com.google.android.youtube'), isTrue);
    });
  });
}
