class DailyTask {
  final String id;
  final String title;
  final String? description;
  final String? deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority;

  const DailyTask({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.priority = 1,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    String? deadline,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    int? priority,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'priority': priority,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: map['deadline'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      priority: (map['priority'] as int?) ?? 1,
    );
  }
}
