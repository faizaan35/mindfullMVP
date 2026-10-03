class Habit {
  final String id;
  final String title;
  final String frequency;
  final int streak;
  final String? lastCompletedDate;
  final DateTime createdAt;
  final bool isCompletedToday;

  const Habit({
    required this.id,
    required this.title,
    required this.frequency,
    this.streak = 0,
    this.lastCompletedDate,
    required this.createdAt,
    this.isCompletedToday = false,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? frequency,
    int? streak,
    String? lastCompletedDate,
    DateTime? createdAt,
    bool? isCompletedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      streak: streak ?? this.streak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'frequency': frequency,
      'streak': streak,
      'last_completed_date': lastCompletedDate,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map, {String? todayDateKey}) {
    final lastDate = map['last_completed_date'] as String?;
    final isDone = todayDateKey != null && lastDate == todayDateKey;

    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      frequency: (map['frequency'] ?? 'daily') as String,
      streak: (map['streak'] as int?) ?? 0,
      lastCompletedDate: lastDate,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isCompletedToday: isDone,
    );
  }
}
