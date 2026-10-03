import 'package:flutter/services.dart';
import 'platform_channel.dart';

class AndroidUsageService {
  final MethodChannel _channel;

  AndroidUsageService([MethodChannel? channel])
      : _channel = channel ?? PlatformChannel.methodChannel;

  Future<Map<String, dynamic>> getTodayUsageStats() async {
    try {
      final result = await _channel.invokeMethod<Map>('getTodayUsageStats');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException {
      // Platform exception handling
    }
    return {'totalTimeMs': 0, 'appStats': []};
  }

  Future<List<Map<String, dynamic>>> getPast7DaysStats() async {
    try {
      final List? result = await _channel.invokeMethod<List>('getPast7DaysStats');
      if (result != null) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } on PlatformException {
      // Ignored
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getInstalledApps({bool includeIcons = false}) async {
    try {
      final List? result = await _channel.invokeMethod<List>(
        'getInstalledApps',
        {'includeIcons': includeIcons},
      );
      if (result != null) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } on PlatformException {
      // Ignored
    }
    return [];
  }

  Future<Map<String, dynamic>> getShortFormStats() async {
    try {
      final Map? result = await _channel.invokeMethod<Map>('getShortFormStats');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException {
      // Ignored
    }
    return {'isEnabled': false, 'reelCount': 0, 'estimatedReelMs': 0};
  }
}
