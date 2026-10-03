import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../application/settings_controller.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions & Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AWARENESS PERMISSIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mindfull requires two key Android capabilities to gently reflect your attention above applications.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),

            // 1. Usage Access Permission Card
            _buildPermissionCard(
              context,
              title: 'Usage Access',
              description:
                  'Allows Mindfull to read foreground applications and measure how long you spend in each app without storing keystrokes or sensitive contents.',
              isGranted: settingsState.hasUsagePermission,
              icon: Icons.data_usage_rounded,
              isDark: isDark,
              onAction: () async {
                await settingsNotifier.requestUsagePermission();
                await Future.delayed(const Duration(seconds: 1));
                await settingsNotifier.refreshPermissions();
              },
            ),
            const SizedBox(height: 16),

            // 2. Overlay Permission Card
            _buildPermissionCard(
              context,
              title: 'Display Over Other Apps',
              description:
                  'Enables the floating Dynamic Notch to smoothly appear top-center on your screen when you switch into attention-tracked apps.',
              isGranted: settingsState.hasOverlayPermission,
              icon: Icons.layers_rounded,
              isDark: isDark,
              onAction: () async {
                await settingsNotifier.requestOverlayPermission();
                await Future.delayed(const Duration(seconds: 1));
                await settingsNotifier.refreshPermissions();
              },
            ),
            const SizedBox(height: 16),

            // 3. Accessibility (Optional for Phase 4 Reel detection)
            _buildPermissionCard(
              context,
              title: 'Accessibility (Optional)',
              description:
                  'Used strictly for experimental short-form video feed detection (Instagram Reels / YouTube Shorts).',
              isGranted: settingsState.hasAccessibilityPermission,
              icon: Icons.accessibility_new_rounded,
              isDark: isDark,
              isOptional: true,
              onAction: () async {
                await settingsNotifier.requestAccessibilityPermission();
                await Future.delayed(const Duration(seconds: 1));
                await settingsNotifier.refreshPermissions();
              },
            ),
            const SizedBox(height: 32),

            Center(
              child: FilledButton(
                onPressed: () async {
                  await settingsNotifier.refreshPermissions();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.oliveGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirm & Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool isGranted,
    required IconData icon,
    required bool isDark,
    bool isOptional = false,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted
              ? AppColors.oliveGreen.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.oliveGreen.withValues(alpha: 0.12)
                      : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isGranted ? AppColors.oliveGreen : AppColors.warmOchre,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (isOptional)
                      Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGranted
                      ? AppColors.oliveGreen.withValues(alpha: 0.12)
                      : AppColors.terracotta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isGranted ? 'Granted' : 'Missing',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isGranted ? AppColors.oliveGreen : AppColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          if (!isGranted)
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.oliveGreen.withValues(alpha: 0.15),
                foregroundColor: AppColors.oliveGreen,
              ),
              child: const Text('Open Settings to Grant'),
            ),
        ],
      ),
    );
  }
}
