class ParsedTaskItem {
  final String title;
  final String? deadline;
  final int? durationMinutes;
  final int priority;

  const ParsedTaskItem({
    required this.title,
    this.deadline,
    this.durationMinutes,
    this.priority = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'deadline': deadline,
      'durationMinutes': durationMinutes,
      'priority': priority,
    };
  }

  factory ParsedTaskItem.fromJson(Map<String, dynamic> json) {
    return ParsedTaskItem(
      title: json['title'] as String,
      deadline: json['deadline'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      priority: (json['priority'] as int?) ?? 1,
    );
  }
}

class ParsedTaskResult {
  final List<ParsedTaskItem> tasks;
  final String rawInput;
  final bool isValid;
  final String? parsingNote;

  const ParsedTaskResult({
    required this.tasks,
    required this.rawInput,
    this.isValid = true,
    this.parsingNote,
  });
}
