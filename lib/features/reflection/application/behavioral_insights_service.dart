import '../../usage/domain/app_session.dart';
import '../../usage/domain/daily_usage_stats.dart';
import '../domain/attention_insight.dart';

class BehavioralInsightsService {
  /// Analyzes sessions and daily stats to generate mindful attention insights.
  static List<AttentionInsight> generateInsights({
    required List<DailyUsageStats> pastDays,
    required List<AppSession> recentSessions,
  }) {
    final List<AttentionInsight> insights = [];

    if (recentSessions.isEmpty && pastDays.isEmpty) {
      insights.add(
        const AttentionInsight(
          title: 'Collecting Attention Baseline',
          description:
              'Mindfull is quietly observing your app interactions to surface gentle patterns over time.',
          category: 'focus',
          highlightStat: 'Day 1',
          isPositive: true,
        ),
      );
      return insights;
    }

    // 1. Time of Day Pattern Analysis
    final Map<String, int> timeOfDayMinutes = {
      'Morning (6am-12pm)': 0,
      'Afternoon (12pm-6pm)': 0,
      'Evening (6pm-10pm)': 0,
      'Night (10pm-6am)': 0,
    };

    for (final session in recentSessions) {
      final hour = session.startedAt.hour;
      final mins = session.duration.inMinutes;

      if (hour >= 6 && hour < 12) {
        timeOfDayMinutes['Morning (6am-12pm)'] =
            (timeOfDayMinutes['Morning (6am-12pm)'] ?? 0) + mins;
      } else if (hour >= 12 && hour < 18) {
        timeOfDayMinutes['Afternoon (12pm-6pm)'] =
            (timeOfDayMinutes['Afternoon (12pm-6pm)'] ?? 0) + mins;
      } else if (hour >= 18 && hour < 22) {
        timeOfDayMinutes['Evening (6pm-10pm)'] =
            (timeOfDayMinutes['Evening (6pm-10pm)'] ?? 0) + mins;
      } else {
        timeOfDayMinutes['Night (10pm-6am)'] =
            (timeOfDayMinutes['Night (10pm-6am)'] ?? 0) + mins;
      }
    }

    String peakPeriod = 'Evening (6pm-10pm)';
    int maxMins = 0;
    timeOfDayMinutes.forEach((period, mins) {
      if (mins > maxMins) {
        maxMins = mins;
        peakPeriod = period;
      }
    });

    if (maxMins > 0) {
      insights.add(
        AttentionInsight(
          title: 'Peak Attention Window',
          description:
              'You interact with your device most during $peakPeriod ($maxMins min total).',
          category: 'time_of_day',
          highlightStat: peakPeriod.split(' ')[0],
          isPositive: false,
        ),
      );
    }

    // 2. Intentional vs Unintentional Session Analysis
    final unclassified = recentSessions.where((s) => s.isIntentional == null).length;
    final intentional = recentSessions.where((s) => s.isIntentional == true).toList();
    final unintentional = recentSessions.where((s) => s.isIntentional == false).toList();

    if (intentional.isNotEmpty || unintentional.isNotEmpty) {
      final totalClassified = intentional.length + unintentional.length;
      final intRatio = intentional.length / totalClassified;
      final intPct = (intRatio * 100).round();

      final avgUnintentionalMins = unintentional.isNotEmpty
          ? (unintentional.fold(0, (sum, s) => sum + s.duration.inMinutes) /
                  unintentional.length)
              .round()
          : 0;

      insights.add(
        AttentionInsight(
          title: 'Intentional Awareness',
          description:
              '$intPct% of classified sessions were intentional. Your average unintentional session is $avgUnintentionalMins minutes.',
          category: 'intentionality',
          highlightStat: '$intPct%',
          isPositive: intRatio >= 0.5,
        ),
      );
    } else if (unclassified > 0) {
      insights.add(
        AttentionInsight(
          title: 'Mindful Session Tagging',
          description:
              'You have $unclassified sessions ready to be tagged as intentional or unintentional from the Notch or timeline.',
          category: 'intentionality',
          highlightStat: '$unclassified untagged',
          isPositive: true,
        ),
      );
    }

    // 3. Sustained Focus Analysis
    final longestSession = recentSessions.isNotEmpty
        ? recentSessions
            .map((s) => s.duration.inMinutes)
            .reduce((a, b) => a > b ? a : b)
        : 0;

    if (longestSession > 0) {
      insights.add(
        AttentionInsight(
          title: 'Sustained Immersion',
          description:
              'Your longest single session was $longestSession minutes. Consider taking mindful eye breaks every 20 minutes.',
          category: 'focus',
          highlightStat: '${longestSession}m',
          isPositive: longestSession < 45,
        ),
      );
    }

    return insights;
  }
}
