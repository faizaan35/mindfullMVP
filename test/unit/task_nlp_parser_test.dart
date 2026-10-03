import 'package:flutter_test/flutter_test.dart';
import 'package:mindfull/features/ai_companion/application/task_nlp_parser.dart';

void main() {
  group('TaskNlpParser Unit Tests', () {
    test('Parses compound input from AGENTS.md spec accurately', () {
      const input =
          'I need to finish my DB assignment before 10, go to the gym around 7 and revise calculus for an hour.';

      final result = TaskNlpParser.parse(input);

      expect(result.isValid, isTrue);
      expect(result.tasks.length, 3);

      final task1 = result.tasks[0];
      expect(task1.title, contains('DB assignment'));
      expect(task1.deadline, equals('22:00'));

      final task2 = result.tasks[1];
      expect(task2.title, contains('gym'));
      expect(task2.deadline, equals('19:00'));

      final task3 = result.tasks[2];
      expect(task3.title, contains('calculus'));
      expect(task3.durationMinutes, equals(60));
    });

    test('Parses single task with deadline and duration', () {
      const input = 'Read 20 pages for 30 mins by 9pm';
      final result = TaskNlpParser.parse(input);

      expect(result.isValid, isTrue);
      expect(result.tasks.length, 1);
      final task = result.tasks.first;
      expect(task.title, contains('Read 20 pages'));
      expect(task.durationMinutes, equals(30));
      expect(task.deadline, equals('21:00'));
    });

    test('Gracefully handles empty and invalid inputs', () {
      final emptyResult = TaskNlpParser.parse('');
      expect(emptyResult.isValid, isFalse);
      expect(emptyResult.tasks, isEmpty);

      final whitespaceResult = TaskNlpParser.parse('   ');
      expect(whitespaceResult.isValid, isFalse);
      expect(whitespaceResult.tasks, isEmpty);
    });
  });
}
