class JournalEntry {
  final String id;
  final DateTime timestamp;
  final String dateKey;
  final String title;
  final String content;
  final String? promptType;

  const JournalEntry({
    required this.id,
    required this.timestamp,
    required this.dateKey,
    required this.title,
    required this.content,
    this.promptType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date_key': dateKey,
      'title': title,
      'content': content,
      'prompt_type': promptType,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      dateKey: map['date_key'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      promptType: map['prompt_type'] as String?,
    );
  }
}
