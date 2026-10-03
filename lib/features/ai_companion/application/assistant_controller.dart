import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import '../../mindfulness/application/mindfulness_controller.dart';
import '../../overlay/application/overlay_controller.dart';
import '../../overlay/domain/notch_state.dart';
import '../../usage/application/usage_controller.dart';
import '../domain/daily_reflection_summary.dart';
import '../domain/parsed_task_result.dart';
import 'ai_summary_service.dart';
import 'task_nlp_parser.dart';

enum AssistantMode { idle, listening, processing, responding }

class AssistantState {
  final AssistantMode mode;
  final String? lastSpokenText;
  final String? responseMessage;
  final ParsedTaskResult? lastParsedResult;
  final DailyReflectionSummary? dailySummary;
  final bool isSpeaking;

  const AssistantState({
    this.mode = AssistantMode.idle,
    this.lastSpokenText,
    this.responseMessage,
    this.lastParsedResult,
    this.dailySummary,
    this.isSpeaking = false,
  });

  AssistantState copyWith({
    AssistantMode? mode,
    String? lastSpokenText,
    String? responseMessage,
    ParsedTaskResult? lastParsedResult,
    DailyReflectionSummary? dailySummary,
    bool? isSpeaking,
  }) {
    return AssistantState(
      mode: mode ?? this.mode,
      lastSpokenText: lastSpokenText ?? this.lastSpokenText,
      responseMessage: responseMessage ?? this.responseMessage,
      lastParsedResult: lastParsedResult ?? this.lastParsedResult,
      dailySummary: dailySummary ?? this.dailySummary,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

class AssistantController extends StateNotifier<AssistantState> {
  final MindfulnessController mindfulnessController;
  final OverlayController overlayController;
  final UsageController usageController;

  AssistantController({
    required this.mindfulnessController,
    required this.overlayController,
    required this.usageController,
  }) : super(const AssistantState());

  /// Starts tap-to-listen simulation or audio listening session
  Future<void> startListening() async {
    state = state.copyWith(
      mode: AssistantMode.listening,
      responseMessage: null,
    );
    await overlayController.setNotchState(NotchState.assistantListening);
  }

  /// Processes spoken or typed natural language input
  Future<void> processNaturalLanguageInput(String input) async {
    state = state.copyWith(
      mode: AssistantMode.processing,
      lastSpokenText: input,
    );
    await overlayController.setNotchState(NotchState.assistantProcessing);

    // Give a brief realistic micro-delay for smooth animation feedback
    await Future.delayed(const Duration(milliseconds: 600));

    final parsedResult = TaskNlpParser.parse(input);

    if (parsedResult.isValid && parsedResult.tasks.isNotEmpty) {
      // Deterministically add tasks
      for (final t in parsedResult.tasks) {
        await mindfulnessController.addTask(
          title: t.title,
          deadline: t.deadline,
          priority: t.priority,
        );
      }

      final taskTitles = parsedResult.tasks.map((t) => '"${t.title}"').join(', ');
      final responseMsg = parsedResult.tasks.length == 1
          ? 'Added: $taskTitles'
          : 'Added ${parsedResult.tasks.length} tasks: $taskTitles';

      state = state.copyWith(
        mode: AssistantMode.responding,
        responseMessage: responseMsg,
        lastParsedResult: parsedResult,
      );

      await overlayController.setNotchState(
        NotchState.assistantResponding,
        assistantMessage: responseMsg,
      );
    } else {
      const responseMsg = 'Could not detect tasks. Try: "Finish DB assignment before 10pm".';
      state = state.copyWith(
        mode: AssistantMode.responding,
        responseMessage: responseMsg,
        lastParsedResult: parsedResult,
      );

      await overlayController.setNotchState(
        NotchState.assistantResponding,
        assistantMessage: responseMsg,
      );
    }

    // Auto-return to idle after 4.5 seconds
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (state.mode == AssistantMode.responding) {
        state = state.copyWith(mode: AssistantMode.idle);
      }
    });
  }

  /// Generates the mindful daily reflection summary from real usage stats
  void generateDailyReflectionSummary() {
    final usageStats = usageController.state.dailyStats;
    final completedTasks =
        mindfulnessController.state.tasks.where((t) => t.isCompleted).length;
    final pendingTasks =
        mindfulnessController.state.tasks.where((t) => !t.isCompleted).length;
    final intentionText =
        mindfulnessController.state.todayIntention?.intentionText;

    final summary = AiSummaryService.generateDailySummary(
      stats: usageStats,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      intentionText: intentionText,
    );

    state = state.copyWith(dailySummary: summary);
  }
}

final assistantControllerProvider =
    StateNotifierProvider<AssistantController, AssistantState>((ref) {
  return AssistantController(
    mindfulnessController: ref.watch(mindfulnessControllerProvider.notifier),
    overlayController: ref.watch(overlayControllerProvider.notifier),
    usageController: ref.watch(usageControllerProvider.notifier),
  );
});
