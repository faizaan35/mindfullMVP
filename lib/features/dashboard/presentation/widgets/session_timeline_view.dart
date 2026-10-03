import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../usage/domain/app_session.dart';

class SessionTimelineView extends StatelessWidget {
  final List<AppSession> sessions;
  final Function(String sessionId, bool isIntentional) onClassify;

  const SessionTimelineView({
    super.key,
    required this.sessions,
    required this.onClassify,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 28,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: 8),
              Text(
                'No recorded sessions yet today',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start using apps or launch the overlay to track attention',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final reversedSessions = sessions.reversed.toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversedSessions.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = reversedSessions[index];
        final timeRange = Formatters.formatSessionRange(session.startedAt, session.endedAt);
        final durationStr = Formatters.formatDuration(session.duration);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: session.isIntentional == true
                      ? AppColors.oliveGreen
                      : session.isIntentional == false
                          ? AppColors.terracotta
                          : AppColors.warmOchre,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeRange,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                durationStr,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(width: 10),
              // Intentional / Unintentional Tag Toggle
              _buildClassificationChip(
                context,
                session: session,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassificationChip(
    BuildContext context, {
    required AppSession session,
    required bool isDark,
  }) {
    if (session.isIntentional == true) {
      return GestureDetector(
        onTap: () => onClassify(session.id, false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.oliveGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.oliveGreen.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'Intentional',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.oliveGreen,
            ),
          ),
        ),
      );
    } else if (session.isIntentional == false) {
      return GestureDetector(
        onTap: () => onClassify(session.id, true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.terracotta.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'Unintentional',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.terracotta,
            ),
          ),
        ),
      );
    } else {
      // Untagged
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onClassify(session.id, true),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'Tag as Intentional',
            icon: const Icon(Icons.thumb_up_alt_outlined, color: AppColors.oliveGreen),
          ),
          IconButton(
            onPressed: () => onClassify(session.id, false),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'Tag as Unintentional',
            icon: const Icon(Icons.thumb_down_alt_outlined, color: AppColors.terracotta),
          ),
        ],
      );
    }
  }
}
