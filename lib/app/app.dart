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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.oliveGreen.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.blur_circular_rounded),
            selectedIcon: Icon(Icons.blur_circular_rounded, color: AppColors.oliveGreen),
            label: 'Attention',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.oliveGreen),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded, color: AppColors.oliveGreen),
            label: 'Mindfulness',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_rounded),
            selectedIcon: Icon(Icons.self_improvement_rounded, color: AppColors.oliveGreen),
            label: 'Reflection',
          ),
        ],
      ),
    );
  }
}
