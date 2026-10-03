import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../ai_companion/presentation/assistant_sheet.dart';
import '../../mindfulness/application/mindfulness_controller.dart';
import '../../mindfulness/presentation/intention_sheet.dart';
import '../../overlay/application/overlay_controller.dart';
import '../../overlay/domain/notch_state.dart';
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
    final overlayNotifier = ref.read(overlayControllerProvider.notifier);
    final settingsState = ref.watch(settingsControllerProvider);

    final needsPermission = !settingsState.hasUsagePermission || !settingsState.hasOverlayPermission;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.wiseForest : AppColors.wiseMint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.wiseLime.withValues(alpha: 0.3) : AppColors.wiseLime,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.spa_rounded,
                  size: 18,
                  color: isDark ? AppColors.wiseLime : AppColors.wiseDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AURA CONSCIOUS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.wiseLime : AppColors.wiseDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.wiseLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
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
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevatedDark : AppColors.wiseGreyPill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: 6),
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
              Builder(
                builder: (context) {
                  final focusSessions = usageState.dailyStats.rawSessions
                      .where((s) => s.duration.inMinutes >= 5)
                      .toList();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TODAY’S TIMELINE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${focusSessions.length} focus sessions (≥ 5m)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  );
                },
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
}
