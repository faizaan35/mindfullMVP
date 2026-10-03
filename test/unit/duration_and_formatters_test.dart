import 'package:flutter_test/flutter_test.dart';
import 'package:mindfull/core/utils/formatters.dart';

void main() {
  group('Formatters Unit Tests', () {
    test('formatDuration formats zero, minutes, and hours accurately', () {
      expect(Formatters.formatDuration(Duration.zero), '0m');
      expect(Formatters.formatDuration(const Duration(seconds: 45)), '45s');
      expect(Formatters.formatDuration(const Duration(minutes: 5)), '5m');
      expect(Formatters.formatDuration(const Duration(minutes: 65)), '1h 5m');
      expect(Formatters.formatDuration(const Duration(hours: 3, minutes: 42)), '3h 42m');
    });

    test('formatPercentage formats decimal ratios properly', () {
      expect(Formatters.formatPercentage(0.5), '50%');
      expect(Formatters.formatPercentage(0.684), '68%');
      expect(Formatters.formatPercentage(1.0), '100%');
      expect(Formatters.formatPercentage(0.0), '0%');
    });

    test('formatDateKey formats YYYY-MM-DD uniformly', () {
      final date = DateTime(2026, 10, 3, 14, 30);
      expect(Formatters.formatDateKey(date), '2026-10-03');
    });

    test('formatSessionRange formats start and end times cleanly', () {
      final start = DateTime(2026, 10, 3, 9, 42);
      final end = DateTime(2026, 10, 3, 10, 3);
      final range = Formatters.formatSessionRange(start, end);
      expect(range, contains('9:42'));
      expect(range, contains('10:03'));
      expect(range, contains('→'));
    });
  });
}
