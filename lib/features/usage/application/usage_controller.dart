import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/android/android_usage_service.dart';
import '../../../platform/android/platform_channel.dart';
import '../data/usage_repository.dart';
import '../domain/app_session.dart';
import '../domain/daily_usage_stats.dart';
import '../domain/tracked_app.dart';

class UsageState {
  final DailyUsageStats dailyStats;
  final List<Map<String, dynamic>> weeklySummary;
  final List<TrackedApp> installedApps;
  final String? activePackage;
  final String? activeAppName;
  final Duration activeSessionDuration;
  final bool isLoading;

  const UsageState({
    required this.dailyStats,
    this.weeklySummary = const [],
    this.installedApps = const [],
    this.activePackage,
    this.activeAppName,
    this.activeSessionDuration = Duration.zero,
    this.isLoading = false,
  });

  UsageState copyWith({
    DailyUsageStats? dailyStats,
    List<Map<String, dynamic>>? weeklySummary,
    List<TrackedApp>? installedApps,
    String? activePackage,
    String? activeAppName,
    Duration? activeSessionDuration,
    bool? isLoading,
  }) {
    return UsageState(
      dailyStats: dailyStats ?? this.dailyStats,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      installedApps: installedApps ?? this.installedApps,
      activePackage: activePackage ?? this.activePackage,
      activeAppName: activeAppName ?? this.activeAppName,
      activeSessionDuration: activeSessionDuration ?? this.activeSessionDuration,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UsageController extends StateNotifier<UsageState> {
  final UsageRepository _repository;
  final AndroidUsageService _usageService;
  final _uuid = const Uuid();

  StreamSubscription? _eventSubscription;
  Timer? _activeSessionTimer;
  DateTime? _currentSessionStartTime;

  UsageController({
    UsageRepository? repository,
    AndroidUsageService? usageService,
  })  : _repository = repository ?? UsageRepository(),
        _usageService = usageService ?? AndroidUsageService(),
        super(UsageState(dailyStats: DailyUsageStats.empty(Formatters.formatDateKey(DateTime.now())))) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    await refreshStats();
    await loadInstalledApps();
    _listenToPlatformEvents();
    state = state.copyWith(isLoading: false);
  }

  Future<void> refreshStats() async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    final systemData = await _usageService.getTodayUsageStats();
    final stats = await _repository.getDailyStats(todayKey, systemUsageData: systemData);
    final weekly = await _repository.getPast7DaysWeeklySummary();

    state = state.copyWith(
      dailyStats: stats,
      weeklySummary: weekly,
    );
  }

  Future<void> loadInstalledApps() async {
    final rawApps = await _usageService.getInstalledApps(includeIcons: true);
    final apps = rawApps.map((a) => TrackedApp.fromMap(a)).toList();
    state = state.copyWith(installedApps: apps);
  }

  void _listenToPlatformEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = PlatformChannel.eventsStream.listen((event) {
      final type = event['type'] as String?;
      if (type == null) return;

      switch (type) {
        case 'app_resumed':
          final pkg = event['packageName'] as String?;
          final name = event['appName'] as String?;
          if (pkg != null) {
            _onAppEntered(pkg, name ?? pkg);
          }
          break;

        case 'session_completed':
          final pkg = event['packageName'] as String?;
          final startedAtMs = event['startedAt'] as int?;
          final endedAtMs = event['endedAt'] as int?;
          final durationMs = event['durationMs'] as int?;
          if (pkg != null && startedAtMs != null && endedAtMs != null && durationMs != null) {
            _onSessionCompleted(pkg, startedAtMs, endedAtMs, durationMs);
          }
          break;

        case 'classify_session':
          final pkg = event['package'] as String?;
          final intentional = event['intentional'] as bool?;
          if (pkg != null && intentional != null) {
            classifyCurrentApp(pkg, intentional);
          }
          break;
      }
    });
  }

  void _onAppEntered(String packageName, String appName) {
    _activeSessionTimer?.cancel();
    _currentSessionStartTime = DateTime.now();

    state = state.copyWith(
      activePackage: packageName,
      activeAppName: appName,
      activeSessionDuration: Duration.zero,
    );

    _activeSessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSessionStartTime != null) {
        final elapsed = DateTime.now().difference(_currentSessionStartTime!);
        state = state.copyWith(activeSessionDuration: elapsed);
      }
    });
  }

  Future<void> _onSessionCompleted(
    String packageName,
    int startedAtMs,
    int endedAtMs,
    int durationMs,
  ) async {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMs);
    final endedAt = DateTime.fromMillisecondsSinceEpoch(endedAtMs);
    final duration = Duration(milliseconds: durationMs);

    final appName = state.installedApps
            .firstOrNullWhere((a) => a.packageName == packageName)
            ?.displayName ??
        packageName;

    final session = AppSession(
      id: _uuid.v4(),
      packageName: packageName,
      displayName: appName,
      startedAt: startedAt,
      endedAt: endedAt,
      duration: duration,
      dateKey: Formatters.formatDateKey(startedAt),
      source: 'native_events',
    );

    await _repository.recordSession(session);
    await refreshStats();
  }

  Future<void> classifySession(String sessionId, bool isIntentional) async {
    await _repository.updateSessionIntentionality(sessionId, isIntentional);
    await refreshStats();
  }

  Future<void> classifyCurrentApp(String packageName, bool isIntentional) async {
    await _repository.tagLatestSessionForPackage(packageName, isIntentional);
    await refreshStats();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _activeSessionTimer?.cancel();
    super.dispose();
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstOrNullWhere(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

final usageControllerProvider =
    StateNotifierProvider<UsageController, UsageState>((ref) {
  return UsageController();
});
