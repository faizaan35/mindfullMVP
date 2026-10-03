class DailyReflectionSummary {
  final String dateKey;
  final String headline;
  final String narrative;
  final String reflectionPrompt;
  final List<String> observations;
  final DateTime generatedAt;

  const DailyReflectionSummary({
    required this.dateKey,
    required this.headline,
    required this.narrative,
    required this.reflectionPrompt,
    required this.observations,
    required this.generatedAt,
  });
}
