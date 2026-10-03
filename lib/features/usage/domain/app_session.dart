class AppSession {
  final String id;
  final String packageName;
  final String displayName;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final bool? isIntentional;
  final String dateKey;
  final String source;

  const AppSession({
    required this.id,
    required this.packageName,
    required this.displayName,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    this.isIntentional,
    required this.dateKey,
    this.source = 'native_events',
  });

  AppSession copyWith({
    String? id,
    String? packageName,
    String? displayName,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    bool? isIntentional,
    String? dateKey,
    String? source,
  }) {
    return AppSession(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      isIntentional: isIntentional ?? this.isIntentional,
      dateKey: dateKey ?? this.dateKey,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_name': packageName,
      'display_name': displayName,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt.millisecondsSinceEpoch,
      'duration_ms': duration.inMilliseconds,
      'is_intentional': isIntentional == null ? null : (isIntentional! ? 1 : 0),
      'date_key': dateKey,
      'source': source,
    };
  }

  factory AppSession.fromMap(Map<String, dynamic> map) {
    return AppSession(
      id: map['id'] as String,
      packageName: map['package_name'] as String,
      displayName: map['display_name'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      endedAt: DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
      duration: Duration(milliseconds: map['duration_ms'] as int),
      isIntentional: map['is_intentional'] == null
          ? null
          : (map['is_intentional'] == 1),
      dateKey: map['date_key'] as String,
      source: (map['source'] ?? 'native_events') as String,
    );
  }
}
