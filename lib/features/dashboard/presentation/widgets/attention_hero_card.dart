import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../usage/domain/daily_usage_stats.dart';

class AttentionHeroCard extends StatelessWidget {
  final DailyUsageStats stats;
  final VoidCallback? onAddIntention;

  const AttentionHeroCard({
    super.key,
    required this.stats,
    this.onAddIntention,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hours = stats.totalScreenTime.inHours;
    final mins = stats.totalScreenTime.inMinutes.remainder(60);
    final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    final intentionalPct = (stats.intentionalRatio * 100).round();

    // Average session calculation
    final avgMins = stats.totalSessions > 0
        ? (stats.totalScreenTime.inMinutes / stats.totalSessions).round()
        : 0;
    final avgStr = avgMins > 0 ? '${avgMins}m' : '<1m';

    final now = DateTime.now();
    final todayDateStr = 'Today · ${Formatters.formatDateShort(now)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Signature Stitch Wise-Lime Hero Account Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.wiseForest : AppColors.wiseLime,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.wiseDark).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.wiseLime : AppColors.wiseDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'TOTAL ATTENTION BALANCE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white70 : AppColors.wiseDark.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.wiseLime.withValues(alpha: 0.2) : AppColors.wiseDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      todayDateStr,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isDark ? AppColors.wiseLime : AppColors.wiseLime,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Attention Big Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.05,
                      color: isDark ? Colors.white : AppColors.wiseDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HELD CONSCIOUSLY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.wiseLime : AppColors.wiseDark.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Time held with full presence. You navigated digital spaces with conscious rhythm today.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.wiseDark.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),

              // Conscious Transparency Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.wiseDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.wiseDark.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: isDark ? AppColors.wiseLime : AppColors.wiseDark,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Conscious rate: $intentionalPct% intentional',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.wiseDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Zero hidden alerts',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.wiseDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Micro Session Vitals Bento (Stitch 3-column bento)
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                context,
                title: 'ARRIVALS',
                value: '${stats.totalSessions}',
                subtitle: 'sessions today',
                icon: Icons.login_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                context,
                title: 'LONGEST',
                value: Formatters.formatDuration(stats.longestSession),
                subtitle: 'continuous focus',
                icon: Icons.timer_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBentoCard(
                context,
                title: 'AVERAGE',
                value: avgStr,
                subtitle: 'restful interval',
                icon: Icons.speed_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.wiseBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.wiseSubtle,
                ),
              ),
              Icon(
                icon,
                size: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.wiseSubtle,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? AppColors.textPrimaryDark : AppColors.wiseDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.wiseSubtle,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
