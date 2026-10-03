import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/android/android_usage_service.dart';
import '../../../platform/android/platform_channel.dart';
import '../../overlay/application/overlay_controller.dart';
import '../../overlay/domain/notch_state.dart';
import '../../usage/application/usage_controller.dart';
import '../data/reflection_repository.dart';
import '../domain/attention_insight.dart';
import '../domain/check_in_entry.dart';
import '../domain/journal_entry.dart';
import 'behavioral_insights_service.dart';

class ReflectionState {
  final List<CheckInEntry> todayCheckIns;
  final List<JournalEntry> journalEntries;
  final List<AttentionInsight> insights;
  final Map<String, dynamic> shortFormStats;
  final bool isLoading;

  const ReflectionState({
    this.todayCheckIns = const [],
    this.journalEntries = const [],
    this.insights = const [],
    this.shortFormStats = const {'isEnabled': false, 'reelCount': 0, 'estimatedReelMs': 0},
    this.isLoading = false,
  });

  ReflectionState copyWith({
    List<CheckInEntry>? todayCheckIns,
    List<JournalEntry>? journalEntries,
    List<AttentionInsight>? insights,
    Map<String, dynamic>? shortFormStats,
    bool? isLoading,
  }) {
    return ReflectionState(
      todayCheckIns: todayCheckIns ?? this.todayCheckIns,
      journalEntries: journalEntries ?? this.journalEntries,
      insights: insights ?? this.insights,
      shortFormStats: shortFormStats ?? this.shortFormStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReflectionController extends StateNotifier<ReflectionState> {
  final ReflectionRepository _repository;
  final AndroidUsageService _usageService;
  final OverlayController overlayController;
  final UsageController usageController;
  StreamSubscription? _eventSubscription;

  ReflectionController({
    ReflectionRepository? repository,
    AndroidUsageService? usageService,
    required this.overlayController,
    required this.usageController,
  })  : _repository = repository ?? ReflectionRepository(),
        _usageService = usageService ?? AndroidUsageService(),
        super(const ReflectionState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    await refresh();
    _listenToPlatformEvents();
    state = state.copyWith(isLoading: false);
  }

  Future<void> refresh() async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    final checkIns = await _repository.getCheckInsForDate(todayKey);
    final journals = await _repository.getJournalEntries();
    final shortStats = await _usageService.getShortFormStats();

    final sessions = usageController.state.dailyStats.rawSessions;
    final insights = BehavioralInsightsService.generateInsights(
      pastDays: [usageController.state.dailyStats],
      recentSessions: sessions,
    );

    state = state.copyWith(
      todayCheckIns: checkIns,
      journalEntries: journals,
      insights: insights,
      shortFormStats: shortStats,
    );
  }

  void _listenToPlatformEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = PlatformChannel.eventsStream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'check_in_response') {
        final mood = event['mood'] as String? ?? 'focused';
        final score = event['score'] as int? ?? 5;
        recordCheckIn(mood: mood, score: score);
      } else if (type == 'short_form_detected') {
        refreshShortFormStats();
      }
    });
  }

  Future<void> recordCheckIn({
    required String mood,
    required int score,
    String? note,
  }) async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    await _repository.recordCheckIn(
      dateKey: todayKey,
      mood: mood,
      score: score,
      note: note,
    );
    await refresh();
  }

  Future<void> addJournal({
    required String title,
    required String content,
    String? promptType,
  }) async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    await _repository.addJournalEntry(
      dateKey: todayKey,
      title: title,
      content: content,
      promptType: promptType,
    );
    await refresh();
  }

  Future<void> deleteJournal(String id) async {
    await _repository.deleteJournalEntry(id);
    await refresh();
  }

  Future<void> triggerNotchCheckIn() async {
    await overlayController.setNotchState(NotchState.checkIn);
  }

  Future<void> triggerNotchReflection([String? quote]) async {
    await overlayController.setNotchState(
      NotchState.reflection,
      reflectionQuote: quote ?? 'Attention is your most sacred non-renewable resource.',
    );
  }

  Future<void> refreshShortFormStats() async {
    final shortStats = await _usageService.getShortFormStats();
    state = state.copyWith(shortFormStats: shortStats);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

final reflectionControllerProvider =
    StateNotifierProvider<ReflectionController, ReflectionState>((ref) {
  return ReflectionController(
    overlayController: ref.watch(overlayControllerProvider.notifier),
    usageController: ref.watch(usageControllerProvider.notifier),
  );
});
