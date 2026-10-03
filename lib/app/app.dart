import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/mindfulness/presentation/mindfulness_screen.dart';
import '../features/reflection/presentation/reflections_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class MindfullApp extends StatelessWidget {
  const MindfullApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindfull',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StatisticsScreen(),
    MindfulnessScreen(),
    ReflectionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.wiseBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Attention',
                  icon: Icons.spa_rounded,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Analytics',
                  icon: Icons.bar_chart_rounded,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Mindfulness',
                  icon: Icons.task_alt_rounded,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Reflection',
                  icon: Icons.self_improvement_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isSelected ? 48 : 36,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.wiseLime
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 19,
              color: isSelected
                  ? AppColors.wiseForest
                  : (isDark ? AppColors.textSecondaryDark : AppColors.wiseSubtle),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? AppColors.wiseLime : AppColors.wiseForest)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.wiseSubtle),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
