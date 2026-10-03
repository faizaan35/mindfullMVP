import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class WeeklyChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeeklyChartWidget({
    super.key,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxMinutes = weeklyData.fold<int>(
      60,
      (maxVal, item) => max(maxVal, (item['totalMinutes'] as int?) ?? 0),
    );

    return Container(
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
                '7-DAY ATTENTION TREND',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Max: ${(maxMinutes / 60).toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weeklyData.map((day) {
                final mins = (day['totalMinutes'] as int?) ?? 0;
                final ratio = maxMinutes > 0 ? (mins / maxMinutes).clamp(0.04, 1.0) : 0.04;
                final dayLabel = (day['dayLabel'] as String?) ?? 'Day';
                final isToday = day == weeklyData.last;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          mins > 0 ? '${(mins / 60).toStringAsFixed(1)}h' : '0m',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isToday
                                ? AppColors.oliveGreen
                                : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: 90 * ratio,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.oliveGreen
                                : (isDark
                                    ? AppColors.surfaceElevatedDark
                                    : AppColors.surfaceElevatedLight),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.oliveGreen
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                            color: isToday
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
