enum NotchState {
  dormant,
  appDetected,
  usageDisplay,
  collapsed,
  expanded,
  contextualNudge,
  assistantListening,
  assistantProcessing,
  assistantResponding,
  checkIn,
  reflection,
}

extension NotchStateX on NotchState {
  String get nativeName {
    switch (this) {
      case NotchState.dormant:
        return 'DORMANT';
      case NotchState.appDetected:
        return 'APP_DETECTED';
      case NotchState.usageDisplay:
        return 'USAGE_DISPLAY';
      case NotchState.collapsed:
        return 'COLLAPSED';
      case NotchState.expanded:
        return 'EXPANDED';
      case NotchState.contextualNudge:
        return 'CONTEXTUAL_NUDGE';
      case NotchState.assistantListening:
        return 'ASSISTANT_LISTENING';
      case NotchState.assistantProcessing:
        return 'ASSISTANT_PROCESSING';
      case NotchState.assistantResponding:
        return 'ASSISTANT_RESPONDING';
      case NotchState.checkIn:
        return 'CHECK_IN';
      case NotchState.reflection:
        return 'REFLECTION';
    }
  }

  static NotchState fromNative(String name) {
    switch (name.toUpperCase()) {
      case 'DORMANT':
        return NotchState.dormant;
      case 'APP_DETECTED':
        return NotchState.appDetected;
      case 'USAGE_DISPLAY':
        return NotchState.usageDisplay;
      case 'COLLAPSED':
        return NotchState.collapsed;
      case 'EXPANDED':
        return NotchState.expanded;
      case 'CONTEXTUAL_NUDGE':
        return NotchState.contextualNudge;
      case 'ASSISTANT_LISTENING':
        return NotchState.assistantListening;
      case 'ASSISTANT_PROCESSING':
        return NotchState.assistantProcessing;
      case 'ASSISTANT_RESPONDING':
        return NotchState.assistantResponding;
      case 'CHECK_IN':
        return NotchState.checkIn;
      case 'REFLECTION':
        return NotchState.reflection;
      default:
        return NotchState.collapsed;
    }
  }
}
