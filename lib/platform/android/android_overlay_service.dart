import 'package:flutter/services.dart';
import 'platform_channel.dart';

class AndroidOverlayService {
  final MethodChannel _channel;

  AndroidOverlayService([MethodChannel? channel])
      : _channel = channel ?? PlatformChannel.methodChannel;

  Future<bool> startOverlayService() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('startOverlayService');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> stopOverlayService() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('stopOverlayService');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isOverlayServiceRunning() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isOverlayServiceRunning');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> updateNotchState(String state) async {
    try {
      await _channel.invokeMethod('updateNotchState', {'state': state});
    } on PlatformException {
      // Ignored
    }
  }

  Future<void> updateNotchSettings({
    required bool overlayEnabled,
    required List<String> trackedPackages,
    required int nudgeThreshold,
    required String currentPrimaryTask,
    List<String> tasks = const [],
    String reflectionQuote = '',
  }) async {
    try {
      await _channel.invokeMethod('updateNotchSettings', {
        'overlayEnabled': overlayEnabled,
        'trackedPackages': trackedPackages,
        'nudgeThreshold': nudgeThreshold,
        'currentPrimaryTask': currentPrimaryTask,
        'tasks': tasks,
        'reflectionQuote': reflectionQuote,
      });
    } on PlatformException {
      // Ignored
    }
  }
}
