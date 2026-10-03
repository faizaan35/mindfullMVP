class CheckInEntry {
  final String id;
  final DateTime timestamp;
  final String dateKey;
  final String mood; // 'focused', 'wandering', 'distracted'
  final int score; // 5, 3, 1
  final String? note;

  const CheckInEntry({
    required this.id,
    required this.timestamp,
    required this.dateKey,
    required this.mood,
    required this.score,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'date_key': dateKey,
      'mood': mood,
      'score': score,
      'note': note,
    };
  }

  factory CheckInEntry.fromMap(Map<String, dynamic> map) {
    return CheckInEntry(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      dateKey: map['date_key'] as String,
      mood: map['mood'] as String,
      score: map['score'] as int,
      note: map['note'] as String?,
    );
  }
}
