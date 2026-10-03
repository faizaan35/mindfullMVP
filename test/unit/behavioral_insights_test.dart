import 'package:flutter_test/flutter_test.dart';
import 'package:mindfull/features/reflection/application/behavioral_insights_service.dart';
import 'package:mindfull/features/usage/domain/app_session.dart';

void main() {
  group('BehavioralInsightsService Unit Tests', () {
    test('Identifies peak attention window and intentionality without moralizing', () {
      final eveningTime = DateTime(2026, 10, 3, 20, 0); // 8:00 PM
      final sessions = [
        AppSession(
          id: 's1',
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
          startedAt: eveningTime,
          endedAt: eveningTime.add(const Duration(minutes: 24)),
          duration: const Duration(minutes: 24),
          dateKey: '2026-10-03',
          isIntentional: false,
        ),
        AppSession(
          id: 's2',
          packageName: 'com.google.android.apps.chrome',
          displayName: 'Chrome',
          startedAt: eveningTime.add(const Duration(minutes: 30)),
          endedAt: eveningTime.add(const Duration(minutes: 50)),
          duration: const Duration(minutes: 20),
          dateKey: '2026-10-03',
          isIntentional: true,
        ),
      ];

      final insights = BehavioralInsightsService.generateInsights(
        pastDays: [],
        recentSessions: sessions,
      );

      expect(insights.isNotEmpty, isTrue);
      expect(insights.any((i) => i.category == 'time_of_day'), isTrue);
      expect(insights.any((i) => i.category == 'intentionality'), isTrue);

      final intentionalityInsight = insights.firstWhere((i) => i.category == 'intentionality');
      expect(intentionalityInsight.description, contains('50%'));
    });
  });
}
