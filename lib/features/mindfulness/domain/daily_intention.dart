class DailyIntention {
  final String id;
  final String dateKey;
  final String intentionText;
  final DateTime createdAt;
  final bool isAccomplished;

  const DailyIntention({
    required this.id,
    required this.dateKey,
    required this.intentionText,
    required this.createdAt,
    this.isAccomplished = false,
  });

  DailyIntention copyWith({
    String? id,
    String? dateKey,
    String? intentionText,
    DateTime? createdAt,
    bool? isAccomplished,
  }) {
    return DailyIntention(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      intentionText: intentionText ?? this.intentionText,
      createdAt: createdAt ?? this.createdAt,
      isAccomplished: isAccomplished ?? this.isAccomplished,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_key': dateKey,
      'intention_text': intentionText,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_accomplished': isAccomplished ? 1 : 0,
    };
  }

  factory DailyIntention.fromMap(Map<String, dynamic> map) {
    return DailyIntention(
      id: map['id'] as String,
      dateKey: map['date_key'] as String,
      intentionText: map['intention_text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isAccomplished: (map['is_accomplished'] as int) == 1,
    );
  }
}
