import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../ai_companion/presentation/assistant_sheet.dart';
import '../../mindfulness/application/mindfulness_controller.dart';
import '../../mindfulness/presentation/intention_sheet.dart';
import '../../overlay/application/overlay_controller.dart';
import '../../overlay/domain/notch_state.dart';
import '../../overlay/presentation/dynamic_notch_pill.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/permissions_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../usage/application/usage_controller.dart';
import 'widgets/active_intention_banner.dart';
import 'widgets/app_usage_list_item.dart';
import 'widgets/attention_hero_card.dart';
import 'widgets/session_timeline_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final usageState = ref.watch(usageControllerProvider);
    final usageNotifier = ref.read(usageControllerProvider.notifier);
    final mindfulnessState = ref.watch(mindfulnessControllerProvider);
    final mindfulnessNotifier = ref.read(mindfulnessControllerProvider.notifier);
    final overlayState = ref.watch(overlayControllerProvider);
    final overlayNotifier = ref.read(overlayControllerProvider.notifier);
    final settingsState = ref.watch(settingsControllerProvider);

    final needsPermission = !settingsState.hasUsagePermission || !settingsState.hasOverlayPermission;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              Formatters.formatDate(DateTime.now()),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Mindful Assistant',
        backgroundColor: AppColors.oliveGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => AssistantSheet.show(context),
        child: const Icon(Icons.auto_awesome_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await usageNotifier.refreshStats();
          await mindfulnessNotifier.refresh();
          await ref.read(settingsControllerProvider.notifier).refreshPermissions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Notch Interactive Sandbox / Live Preview
              Center(
                child: Column(
                  children: [
                    DynamicNotchPill(
                      state: overlayState.currentState,
                      appName: overlayState.activeAppName,
                      todayDuration: usageState.dailyStats.totalScreenTime,
                      sessionDuration: usageState.activeSessionDuration,
                      activeTaskTitle: mindfulnessState.primaryPendingTask?.title ??
                          mindfulnessState.todayIntention?.intentionText,
                      assistantMessage: overlayState.assistantMessage,
                      reflectionQuote: overlayState.reflectionQuote,
                      onStateChanged: (newState) {
                        overlayNotifier.setNotchState(newState);
                      },
                      onBackToTask: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Returning to your mindful task.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      onClassifySession: (isIntentional) {
                        usageNotifier.classifyCurrentApp(
                          overlayState.activeAppName,
                          isIntentional,
                        );
                      },
                      onCheckInResponse: (mood) {
                        ref.read(mindfulnessControllerProvider.notifier);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Noticed $mood mood. Stay gentle with yourself.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Quick Notch Test State Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStateChip(
                            label: 'Pill',
                            isSelected: overlayState.currentState == NotchState.collapsed,
                            onTap: () => overlayNotifier.setNotchState(NotchState.collapsed),
                            isDark: isDark,
                          ),
                          _buildStateChip(
                            label: 'Detected',
                            isSelected: overlayState.currentState == NotchState.appDetected,
                            onTap: () => overlayNotifier.setNotchState(NotchState.appDetected),
                            isDark: isDark,
                          ),
                          _buildStateChip(
                            label: 'Expanded',
                            isSelected: overlayState.currentState == NotchState.expanded,
                            onTap: () => overlayNotifier.setNotchState(NotchState.expanded),
                            isDark: isDark,
                          ),
                          _buildStateChip(
                            label: 'Nudge',
                            isSelected: overlayState.currentState == NotchState.contextualNudge,
                            onTap: () => overlayNotifier.setNotchState(NotchState.contextualNudge),
                            isDark: isDark,
                          ),
                          _buildStateChip(
                            label: 'Check-in',
                            isSelected: overlayState.currentState == NotchState.checkIn,
                            onTap: () => overlayNotifier.setNotchState(NotchState.checkIn),
                            isDark: isDark,
                          ),
                          _buildStateChip(
                            label: 'Reflect',
                            isSelected: overlayState.currentState == NotchState.reflection,
                            onTap: () => overlayNotifier.setNotchState(NotchState.reflection),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Permission Prompt Banner (if permissions missing)
              if (needsPermission) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.terracottaLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.terracotta.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security_update_warning_rounded,
                          color: AppColors.terracotta,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Permissions required for background awareness and overlay.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.terracotta,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Daily Intention Banner
              ActiveIntentionBanner(
                intention: mindfulnessState.todayIntention,
                onEdit: () {
                  IntentionSheet.show(
                    context,
                    initialText: mindfulnessState.todayIntention?.intentionText,
                    onSave: (text) => mindfulnessNotifier.setDailyIntention(text),
                  );
                },
                onToggleAccomplished: () {
                  mindfulnessNotifier.toggleIntentionAccomplished();
                },
              ),
              const SizedBox(height: 16),

              // 4. Attention Hero Card
              AttentionHeroCard(stats: usageState.dailyStats),
              const SizedBox(height: 24),

              // 5. Top Applications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ATTENTION BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${usageState.dailyStats.appStats.length} apps',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (usageState.dailyStats.appStats.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No app usage recorded yet today.',
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
                  itemCount: usageState.dailyStats.appStats.length.clamp(0, 5),
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final appUsage = usageState.dailyStats.appStats[index];
                    return AppUsageListItem(
                      usage: appUsage,
                      totalDailyTime: usageState.dailyStats.totalScreenTime,
                      onTap: () {
                        // Quick preview in notch
                        overlayNotifier.setNotchState(
                          NotchState.usageDisplay,
                          appName: appUsage.displayName,
                          todayDuration: appUsage.totalDuration,
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 24),

              // 6. Today's Timeline Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TODAY’S TIMELINE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '${usageState.dailyStats.rawSessions.length} sessions',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SessionTimelineView(
                sessions: usageState.dailyStats.rawSessions,
                onClassify: (sessionId, isIntentional) {
                  usageNotifier.classifySession(sessionId, isIntentional);
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.oliveGreen.withValues(alpha: 0.18),
        side: BorderSide(
          color: isSelected
              ? AppColors.oliveGreen
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
    );
  }
}
