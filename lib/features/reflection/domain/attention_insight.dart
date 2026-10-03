class AttentionInsight {
  final String title;
  final String description;
  final String category; // 'time_of_day', 'intentionality', 'app_pattern', 'focus'
  final String highlightStat;
  final bool isPositive;

  const AttentionInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.highlightStat,
    this.isPositive = true,
  });
}
