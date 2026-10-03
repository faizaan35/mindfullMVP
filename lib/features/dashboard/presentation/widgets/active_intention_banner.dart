import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../mindfulness/domain/daily_intention.dart';

class ActiveIntentionBanner extends StatelessWidget {
  final DailyIntention? intention;
  final VoidCallback onEdit;
  final VoidCallback onToggleAccomplished;

  const ActiveIntentionBanner({
    super.key,
    this.intention,
    required this.onEdit,
    required this.onToggleAccomplished,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (intention == null || intention!.intentionText.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wb_sunny_outlined,
              size: 20,
              color: AppColors.warmOchre,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'What is your main intention for today?',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.oliveGreen,
              ),
              child: const Text('Set Intention'),
            ),
          ],
        ),
      );
    }

    final isDone = intention!.isAccomplished;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDone
            ? (isDark ? AppColors.surfaceDark : AppColors.oliveGreenLight.withValues(alpha: 0.4))
            : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? AppColors.oliveGreen.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleAccomplished,
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            color: isDone ? AppColors.oliveGreen : AppColors.warmOchre,
            icon: Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY’S INTENTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intention!.intentionText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}
