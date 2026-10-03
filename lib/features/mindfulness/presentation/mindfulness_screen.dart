import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../ai_companion/presentation/assistant_sheet.dart';
import '../../overlay/application/overlay_controller.dart';
import '../../overlay/domain/notch_state.dart';
import '../application/mindfulness_controller.dart';
import 'habit_dialog.dart';
import 'intention_sheet.dart';
import 'task_dialog.dart';

class MindfulnessScreen extends ConsumerWidget {
  const MindfulnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mindfulnessState = ref.watch(mindfulnessControllerProvider);
    final mindfulnessNotifier = ref.read(mindfulnessControllerProvider.notifier);
    final overlayNotifier = ref.read(overlayControllerProvider.notifier);

    final completedTasks = mindfulnessState.tasks.where((t) => t.isCompleted).length;
    final totalTasks = mindfulnessState.tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindfulness & Intent'),
        actions: [
          IconButton(
            tooltip: 'Natural Language AI Input',
            onPressed: () => AssistantSheet.show(context),
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.oliveGreen),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Daily Intention Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TODAY’S INTENTION',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          IntentionSheet.show(
                            context,
                            initialText: mindfulnessState.todayIntention?.intentionText,
                            onSave: (text) => mindfulnessNotifier.setDailyIntention(text),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (mindfulnessState.todayIntention != null)
                    Row(
                      children: [
                        Checkbox(
                          value: mindfulnessState.todayIntention!.isAccomplished,
                          activeColor: AppColors.oliveGreen,
                          onChanged: (_) => mindfulnessNotifier.toggleIntentionAccomplished(),
                        ),
                        Expanded(
                          child: Text(
                            mindfulnessState.todayIntention!.intentionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: mindfulnessState.todayIntention!.isAccomplished
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    TextButton.icon(
                      onPressed: () {
                        IntentionSheet.show(
                          context,
                          onSave: (text) => mindfulnessNotifier.setDailyIntention(text),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, color: AppColors.oliveGreen),
                      label: const Text(
                        'Set an intention for today',
                        style: TextStyle(color: AppColors.oliveGreen),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Contextual Nudge Test Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.oliveGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contextual Nudges Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Triggers gently when scrolling in tracked apps to recall your priority.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      overlayNotifier.setNotchState(
                        NotchState.contextualNudge,
                        activeTaskTitle: mindfulnessState.primaryPendingTask?.title ??
                            mindfulnessState.todayIntention?.intentionText,
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.oliveGreen),
                    child: const Text('Test Nudge'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Tasks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY TASKS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '$completedTasks of $totalTasks completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    TaskDialog.show(
                      context,
                      onSave: ({required title, deadline, description, priority = 1}) {
                        mindfulnessNotifier.addTask(
                          title: title,
                          description: description,
                          deadline: deadline,
                          priority: priority,
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Task'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.oliveGreen.withValues(alpha: 0.15),
                    foregroundColor: AppColors.oliveGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (mindfulnessState.tasks.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No tasks set for today. Tap "+ Add Task" or use the AI Assistant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mindfulnessState.tasks.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = mindfulnessState.tasks[index];
                  return Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => mindfulnessNotifier.deleteTask(task.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 18),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: task.isCompleted,
                            activeColor: AppColors.oliveGreen,
                            onChanged: (val) {
                              if (val != null) {
                                mindfulnessNotifier.toggleTask(task.id, val);
                              }
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted
                                        ? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                                if (task.deadline != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: AppColors.warmOchre,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        task.deadline!,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.warmOchre,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (task.priority > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.oliveGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Focus',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.oliveGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),

            // 4. Habits Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MINDFUL HABITS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    HabitDialog.show(
                      context,
                      onSave: (title, freq) => mindfulnessNotifier.addHabit(title, frequency: freq),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Habit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warmOchre.withValues(alpha: 0.15),
                    foregroundColor: AppColors.warmOchre,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (mindfulnessState.habits.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No habits defined. Tap "+ New Habit" to create daily focus rhythms.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mindfulnessState.habits.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final habit = mindfulnessState.habits[index];
                  return Dismissible(
                    key: Key(habit.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => mindfulnessNotifier.deleteHabit(habit.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 18),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => mindfulnessNotifier.toggleHabitToday(habit.id),
                            icon: Icon(
                              habit.isCompletedToday
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: habit.isCompletedToday
                                  ? AppColors.oliveGreen
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${habit.streak} day streak · ${habit.frequency}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warmOchre.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 15,
                                  color: AppColors.warmOchre,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${habit.streak}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warmOchre,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
