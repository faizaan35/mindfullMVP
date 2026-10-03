import 'package:flutter_riverpod/legacy.dart';
import '../../../core/utils/formatters.dart';
import '../../../platform/android/android_overlay_service.dart';
import '../data/habit_repository.dart';
import '../data/task_repository.dart';
import '../domain/daily_intention.dart';
import '../domain/daily_task.dart';
import '../domain/habit.dart';

class MindfulnessState {
  final DailyIntention? todayIntention;
  final List<DailyTask> tasks;
  final List<Habit> habits;
  final bool isLoading;

  const MindfulnessState({
    this.todayIntention,
    this.tasks = const [],
    this.habits = const [],
    this.isLoading = false,
  });

  MindfulnessState copyWith({
    DailyIntention? todayIntention,
    List<DailyTask>? tasks,
    List<Habit>? habits,
    bool? isLoading,
  }) {
    return MindfulnessState(
      todayIntention: todayIntention ?? this.todayIntention,
      tasks: tasks ?? this.tasks,
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  DailyTask? get primaryPendingTask {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => b.priority.compareTo(a.priority));
    return pending.first;
  }
}

class MindfulnessController extends StateNotifier<MindfulnessState> {
  final TaskRepository _taskRepository;
  final HabitRepository _habitRepository;
  final AndroidOverlayService _overlayService;

  MindfulnessController({
    TaskRepository? taskRepository,
    HabitRepository? habitRepository,
    AndroidOverlayService? overlayService,
  })  : _taskRepository = taskRepository ?? TaskRepository(),
        _habitRepository = habitRepository ?? HabitRepository(),
        _overlayService = overlayService ?? AndroidOverlayService(),
        super(const MindfulnessState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    await refresh();
    state = state.copyWith(isLoading: false);
  }

  Future<void> refresh() async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    final intention = await _taskRepository.getIntentionForDate(todayKey);
    final tasks = await _taskRepository.getTasks();
    final habits = await _habitRepository.getHabits(todayKey);

    state = state.copyWith(
      todayIntention: intention,
      tasks: tasks,
      habits: habits,
    );

    // Sync primary pending task, task list, and reflection quote to native overlay settings
    final topTask = state.primaryPendingTask;
    final pendingTitles = state.tasks
        .where((t) => !t.isCompleted)
        .take(4)
        .map((t) => t.title)
        .toList();
    await _overlayService.updateNotchSettings(
      overlayEnabled: true,
      trackedPackages: const [],
      nudgeThreshold: 20,
      currentPrimaryTask: topTask?.title ?? (intention?.intentionText ?? ''),
      tasks: pendingTitles,
      reflectionQuote: 'The attention you give something is the life you give it.',
    );
  }

  Future<void> setDailyIntention(String text) async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    final saved = await _taskRepository.saveIntention(todayKey, text);
    state = state.copyWith(todayIntention: saved);
    await refresh();
  }

  Future<void> toggleIntentionAccomplished() async {
    final cur = state.todayIntention;
    if (cur == null) return;
    final next = !cur.isAccomplished;
    await _taskRepository.toggleIntentionAccomplished(cur.id, next);
    state = state.copyWith(todayIntention: cur.copyWith(isAccomplished: next));
  }

  Future<void> addTask({
    required String title,
    String? description,
    String? deadline,
    int priority = 1,
  }) async {
    await _taskRepository.addTask(
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
    );
    await refresh();
  }

  Future<void> toggleTask(String id, bool isCompleted) async {
    await _taskRepository.toggleTaskComplete(id, isCompleted);
    await refresh();
  }

  Future<void> deleteTask(String id) async {
    await _taskRepository.deleteTask(id);
    await refresh();
  }

  Future<void> addHabit(String title, {String frequency = 'daily'}) async {
    await _habitRepository.addHabit(title, frequency: frequency);
    await refresh();
  }

  Future<void> toggleHabitToday(String habitId) async {
    final todayKey = Formatters.formatDateKey(DateTime.now());
    await _habitRepository.toggleHabitToday(habitId, todayKey);
    await refresh();
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitRepository.deleteHabit(habitId);
    await refresh();
  }
}

final mindfulnessControllerProvider =
    StateNotifierProvider<MindfulnessController, MindfulnessState>((ref) {
  return MindfulnessController();
});
