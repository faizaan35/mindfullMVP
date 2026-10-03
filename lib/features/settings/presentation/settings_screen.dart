import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../usage/application/usage_controller.dart';
import '../application/settings_controller.dart';
import 'permissions_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final usageState = ref.watch(usageControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Overlay Section
          Text(
            'DYNAMIC NOTCH OVERLAY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Floating Notch'),
                  subtitle: const Text('Shows top-center awareness pill over other apps'),
                  value: settingsState.overlayEnabled,
                  activeThumbColor: AppColors.oliveGreen,
                  onChanged: (val) => settingsNotifier.setOverlayEnabled(val),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Contextual Nudge Threshold'),
                  subtitle: Text('Remind me after ${settingsState.nudgeThresholdMinutes} minutes of continuous app use'),
                  trailing: DropdownButton<int>(
                    value: settingsState.nudgeThresholdMinutes,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10m')),
                      DropdownMenuItem(value: 15, child: Text('15m')),
                      DropdownMenuItem(value: 20, child: Text('20m')),
                      DropdownMenuItem(value: 30, child: Text('30m')),
                    ],
                    onChanged: (val) {
                      if (val != null) settingsNotifier.setNudgeThreshold(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Tracked Applications Section
          Text(
            'TRACKED APPLICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: ListTile(
              title: const Text('Select Tracked Apps'),
              subtitle: Text(
                settingsState.trackedPackages.isEmpty
                    ? 'All launcher apps (default)'
                    : '${settingsState.trackedPackages.length} apps selected',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                _showAppSelectionDialog(context, ref, usageState.installedApps, settingsState.trackedPackages);
              },
            ),
          ),
          const SizedBox(height: 24),

          // 3. Permissions Section
          Text(
            'PERMISSIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: ListTile(
              title: const Text('System Access & Permissions'),
              subtitle: Text(
                settingsState.hasUsagePermission && settingsState.hasOverlayPermission
                    ? 'All required permissions granted'
                    : 'Action needed to enable background tracking',
              ),
              leading: Icon(
                settingsState.hasUsagePermission && settingsState.hasOverlayPermission
                    ? Icons.verified_user_rounded
                    : Icons.warning_amber_rounded,
                color: settingsState.hasUsagePermission && settingsState.hasOverlayPermission
                    ? AppColors.oliveGreen
                    : AppColors.terracotta,
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 4. Privacy & Data
          Text(
            'PRIVACY & LOCAL STORAGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.oliveGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '100% On-Device Privacy',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your usage sessions, tasks, reflections, and check-ins are stored in an encrypted SQLite database on your device and are never sold or sent to remote servers.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAppSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> installedApps,
    List<String> currentTracked,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(settingsControllerProvider);
            final notifier = ref.read(settingsControllerProvider.notifier);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tracked Applications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose which apps trigger the Dynamic Notch and awareness nudges.',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: installedApps.isEmpty
                        ? const Center(child: Text('Loading installed apps...'))
                        : ListView.builder(
                            itemCount: installedApps.length,
                            itemBuilder: (context, index) {
                              final app = installedApps[index];
                              final isSelected = settings.trackedPackages.contains(app.packageName);
                              return CheckboxListTile(
                                title: Text(app.displayName),
                                subtitle: Text(app.packageName, style: const TextStyle(fontSize: 11)),
                                value: isSelected,
                                activeColor: AppColors.oliveGreen,
                                onChanged: (_) {
                                  notifier.toggleAppTracked(app.packageName);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
