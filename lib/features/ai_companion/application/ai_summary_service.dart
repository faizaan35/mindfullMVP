import '../../usage/domain/daily_usage_stats.dart';
import '../domain/daily_reflection_summary.dart';

class AiSummaryService {
  /// Generates a mindful, neutral reflection summary from daily usage data.
  static DailyReflectionSummary generateDailySummary({
    required DailyUsageStats stats,
    int completedTasks = 0,
    int pendingTasks = 0,
    String? intentionText,
  }) {
    final totalHours = stats.totalScreenTime.inHours;
    final totalMinutes = stats.totalScreenTime.inMinutes.remainder(60);

    String headline;
    if (stats.totalScreenTime.inMinutes < 60) {
      headline = 'A gentle, low-screen day';
    } else if (stats.totalScreenTime.inMinutes < 180) {
      headline = 'Balanced flow of attention';
    } else {
      headline = 'Active engagement across digital spaces';
    }

    final List<String> observations = [];

    // App observations
    if (stats.appStats.isNotEmpty) {
      final topApp = stats.appStats.first;
      final topTimeMins = topApp.totalDuration.inMinutes;
      observations.add(
        '${topApp.displayName} received the most focus today (${topTimeMins}m across ${topApp.sessionCount} sessions).',
      );
    }

    // Sessions observation
    if (stats.totalSessions > 0) {
      final avgMins = (stats.totalScreenTime.inMinutes / stats.totalSessions).round();
      observations.add(
        'You visited your phone ${stats.totalSessions} times, averaging $avgMins minutes per session.',
      );
    }

    // Longest session observation
    if (stats.longestSession.inMinutes > 0) {
      observations.add(
        'Your longest sustained period on screen was ${stats.longestSession.inMinutes}m.',
      );
    }

    // Tasks observation
    if (completedTasks > 0) {
      observations.add(
        'You completed $completedTasks intended ${completedTasks == 1 ? "task" : "tasks"} today.',
      );
    }

    // Narrative construction
    final screenTimeStr = totalHours > 0 ? '${totalHours}h ${totalMinutes}m' : '${totalMinutes}m';
    final narrative = StringBuffer();
    narrative.write('Today, you spent $screenTimeStr of your digital attention. ');
    if (intentionText != null && intentionText.isNotEmpty) {
      narrative.write('Your stated intention was "$intentionText". ');
    }
    if (stats.intentionalRatio >= 0.6) {
      narrative.write(
        'A significant portion (${(stats.intentionalRatio * 100).round()}%) of your classified time felt intentional and aligned.',
      );
    } else {
      narrative.write(
        'Take a quiet breath and notice which moments felt enriching versus automatic.',
      );
    }

    // Reflection prompt
    final reflectionPrompt = _pickReflectionPrompt(stats);

    return DailyReflectionSummary(
      dateKey: stats.dateKey,
      headline: headline,
      narrative: narrative.toString(),
      reflectionPrompt: reflectionPrompt,
      observations: observations,
      generatedAt: DateTime.now(),
    );
  }

  static String _pickReflectionPrompt(DailyUsageStats stats) {
    if (stats.totalSessions > 25) {
      return 'What usually triggers the urge to reach for your phone when you are between tasks?';
    } else if (stats.longestSession.inMinutes > 40) {
      return 'During your longest session today, what did you discover, and did it leave you energized?';
    } else {
      return 'What is one moment from offline life today that you are grateful to remember?';
    }
  }
}
