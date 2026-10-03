import 'dart:async';
import 'package:flutter/services.dart';

class PlatformChannel {
  static const MethodChannel methodChannel = MethodChannel('com.mindfull/platform');
  static const EventChannel eventChannel = EventChannel('com.mindfull/events');

  static Stream<Map<String, dynamic>>? _eventsStream;

  static Stream<Map<String, dynamic>> get eventsStream {
    _eventsStream ??= eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
    return _eventsStream!;
  }
}
