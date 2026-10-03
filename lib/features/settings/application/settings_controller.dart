import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../platform/android/android_overlay_service.dart';
import '../../../platform/android/android_permissions_service.dart';

class SettingsState {
  final bool overlayEnabled;
  final bool usageNotificationsEnabled;
  final int nudgeThresholdMinutes;
  final List<String> trackedPackages;
  final bool hasUsagePermission;
  final bool hasOverlayPermission;
  final bool hasAccessibilityPermission;
  final bool isLoading;

  const SettingsState({
    this.overlayEnabled = true,
    this.usageNotificationsEnabled = true,
    this.nudgeThresholdMinutes = 20,
    this.trackedPackages = const [],
    this.hasUsagePermission = false,
    this.hasOverlayPermission = false,
    this.hasAccessibilityPermission = false,
    this.isLoading = false,
  });

  SettingsState copyWith({
    bool? overlayEnabled,
    bool? usageNotificationsEnabled,
    int? nudgeThresholdMinutes,
    List<String>? trackedPackages,
    bool? hasUsagePermission,
    bool? hasOverlayPermission,
    bool? hasAccessibilityPermission,
    bool? isLoading,
  }) {
    return SettingsState(
      overlayEnabled: overlayEnabled ?? this.overlayEnabled,
      usageNotificationsEnabled:
          usageNotificationsEnabled ?? this.usageNotificationsEnabled,
      nudgeThresholdMinutes:
          nudgeThresholdMinutes ?? this.nudgeThresholdMinutes,
      trackedPackages: trackedPackages ?? this.trackedPackages,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      hasAccessibilityPermission:
          hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final AndroidPermissionsService _permissionsService;
  final AndroidOverlayService _overlayService;

  SettingsController({
    AndroidPermissionsService? permissionsService,
    AndroidOverlayService? overlayService,
  })  : _permissionsService = permissionsService ?? AndroidPermissionsService(),
        _overlayService = overlayService ?? AndroidOverlayService(),
        super(const SettingsState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();

    final overlayEnabled = prefs.getBool('overlay_enabled') ?? true;
    final notifications = prefs.getBool('notifications_enabled') ?? true;
    final threshold = prefs.getInt('nudge_threshold_minutes') ?? 20;
    final trackedList = prefs.getStringList('tracked_packages') ?? [];

    final hasUsage = await _permissionsService.checkUsagePermission();
    final hasOverlay = await _permissionsService.checkOverlayPermission();
    final hasAccessibility =
        await _permissionsService.checkAccessibilityPermission();

    state = state.copyWith(
      overlayEnabled: overlayEnabled,
      usageNotificationsEnabled: notifications,
      nudgeThresholdMinutes: threshold,
      trackedPackages: trackedList,
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
      hasAccessibilityPermission: hasAccessibility,
      isLoading: false,
    );

    // Sync to native service
    await _syncToNative();
  }

  Future<void> refreshPermissions() async {
    final hasUsage = await _permissionsService.checkUsagePermission();
    final hasOverlay = await _permissionsService.checkOverlayPermission();
    final hasAccessibility =
        await _permissionsService.checkAccessibilityPermission();

    state = state.copyWith(
      hasUsagePermission: hasUsage,
      hasOverlayPermission: hasOverlay,
      hasAccessibilityPermission: hasAccessibility,
    );
  }

  Future<void> setOverlayEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('overlay_enabled', enabled);
    state = state.copyWith(overlayEnabled: enabled);
    await _syncToNative();

    if (enabled) {
      await _overlayService.startOverlayService();
    } else {
      await _overlayService.stopOverlayService();
    }
  }

  Future<void> setNudgeThreshold(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nudge_threshold_minutes', minutes);
    state = state.copyWith(nudgeThresholdMinutes: minutes);
    await _syncToNative();
  }

  Future<void> setTrackedPackages(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tracked_packages', packages);
    state = state.copyWith(trackedPackages: packages);
    await _syncToNative();
  }

  Future<void> toggleAppTracked(String packageName) async {
    final list = List<String>.from(state.trackedPackages);
    if (list.contains(packageName)) {
      list.remove(packageName);
    } else {
      list.add(packageName);
    }
    await setTrackedPackages(list);
  }

  Future<void> requestUsagePermission() async {
    await _permissionsService.requestUsagePermission();
  }

  Future<void> requestOverlayPermission() async {
    await _permissionsService.requestOverlayPermission();
  }

  Future<void> requestAccessibilityPermission() async {
    await _permissionsService.requestAccessibilityPermission();
  }

  Future<void> _syncToNative() async {
    await _overlayService.updateNotchSettings(
      overlayEnabled: state.overlayEnabled,
      trackedPackages: state.trackedPackages,
      nudgeThreshold: state.nudgeThresholdMinutes,
      currentPrimaryTask: '',
    );
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});
