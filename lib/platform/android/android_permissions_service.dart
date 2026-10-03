import 'package:flutter/services.dart';
import 'platform_channel.dart';

class AndroidPermissionsService {
  final MethodChannel _channel;

  AndroidPermissionsService([MethodChannel? channel])
      : _channel = channel ?? PlatformChannel.methodChannel;

  Future<bool> checkUsagePermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('checkUsagePermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } on PlatformException {
      // Ignored
    }
  }

  Future<bool> checkOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException {
      // Ignored
    }
  }

  Future<bool> checkAccessibilityPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('checkAccessibilityPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } on PlatformException {
      // Ignored
    }
  }
}
