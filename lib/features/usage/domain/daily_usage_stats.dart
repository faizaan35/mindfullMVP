import 'app_session.dart';

class SingleAppUsage {
  final String packageName;
  final String displayName;
  final Duration totalDuration;
  final int sessionCount;
  final Duration longestSession;
  final String? iconBase64;
  final double intentionalPercentage;

  const SingleAppUsage({
    required this.packageName,
    required this.displayName,
    required this.totalDuration,
    required this.sessionCount,
    this.longestSession = Duration.zero,
    this.iconBase64,
    this.intentionalPercentage = 0.5,
  });
}

class DailyUsageStats {
  final String dateKey;
  final Duration totalScreenTime;
  final List<SingleAppUsage> appStats;
  final int totalSessions;
  final Duration longestSession;
  final DateTime? firstSessionTime;
  final DateTime? lastSessionTime;
  final List<AppSession> rawSessions;
  final double intentionalRatio;

  const DailyUsageStats({
    required this.dateKey,
    required this.totalScreenTime,
    required this.appStats,
    required this.totalSessions,
    required this.longestSession,
    this.firstSessionTime,
    this.lastSessionTime,
    this.rawSessions = const [],
    this.intentionalRatio = 0.5,
  });

  factory DailyUsageStats.empty(String dateKey) {
    return DailyUsageStats(
      dateKey: dateKey,
      totalScreenTime: Duration.zero,
      appStats: const [],
      totalSessions: 0,
      longestSession: Duration.zero,
      rawSessions: const [],
      intentionalRatio: 0.5,
    );
  }
}
