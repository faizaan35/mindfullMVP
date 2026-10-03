import 'dart:async';
import 'package:flutter_riverpod/legacy.dart';
import '../../../platform/android/android_overlay_service.dart';
import '../../../platform/android/platform_channel.dart';
import '../domain/notch_state.dart';

class OverlayStateModel {
  final NotchState currentState;
  final String activeAppName;
  final Duration todayDuration;
  final Duration sessionDuration;
  final String? activeTaskTitle;
  final String? assistantMessage;
  final String? reflectionQuote;

  const OverlayStateModel({
    this.currentState = NotchState.collapsed,
    this.activeAppName = 'Instagram',
    this.todayDuration = const Duration(minutes: 18),
    this.sessionDuration = const Duration(minutes: 5),
    this.activeTaskTitle,
    this.assistantMessage,
    this.reflectionQuote,
  });

  OverlayStateModel copyWith({
    NotchState? currentState,
    String? activeAppName,
    Duration? todayDuration,
    Duration? sessionDuration,
    String? activeTaskTitle,
    String? assistantMessage,
    String? reflectionQuote,
  }) {
    return OverlayStateModel(
      currentState: currentState ?? this.currentState,
      activeAppName: activeAppName ?? this.activeAppName,
      todayDuration: todayDuration ?? this.todayDuration,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      activeTaskTitle: activeTaskTitle ?? this.activeTaskTitle,
      assistantMessage: assistantMessage ?? this.assistantMessage,
      reflectionQuote: reflectionQuote ?? this.reflectionQuote,
    );
  }
}

class OverlayController extends StateNotifier<OverlayStateModel> {
  final AndroidOverlayService _overlayService;
  StreamSubscription? _eventSubscription;

  OverlayController([AndroidOverlayService? overlayService])
      : _overlayService = overlayService ?? AndroidOverlayService(),
        super(const OverlayStateModel()) {
    _listenToPlatformEvents();
  }

  void _listenToPlatformEvents() {
    _eventSubscription = PlatformChannel.eventsStream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'notch_state_changed') {
        final stateName = event['state'] as String?;
        if (stateName != null) {
          final newState = NotchStateX.fromNative(stateName);
          state = state.copyWith(currentState: newState);
        }
      }
    });
  }

  Future<void> setNotchState(NotchState newState, {
    String? appName,
    Duration? todayDuration,
    Duration? sessionDuration,
    String? activeTaskTitle,
    String? assistantMessage,
    String? reflectionQuote,
  }) async {
    state = state.copyWith(
      currentState: newState,
      activeAppName: appName ?? state.activeAppName,
      todayDuration: todayDuration ?? state.todayDuration,
      sessionDuration: sessionDuration ?? state.sessionDuration,
      activeTaskTitle: activeTaskTitle ?? state.activeTaskTitle,
      assistantMessage: assistantMessage ?? state.assistantMessage,
      reflectionQuote: reflectionQuote ?? state.reflectionQuote,
    );

    await _overlayService.updateNotchState(newState.nativeName);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

final overlayControllerProvider =
    StateNotifierProvider<OverlayController, OverlayStateModel>((ref) {
  return OverlayController();
});
