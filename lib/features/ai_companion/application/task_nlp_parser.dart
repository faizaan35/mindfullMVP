import '../domain/parsed_task_result.dart';

class TaskNlpParser {
  /// Parses natural language input into validated structured tasks.
  static ParsedTaskResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParsedTaskResult(
        tasks: [],
        rawInput: '',
        isValid: false,
        parsingNote: 'Empty input provided',
      );
    }

    // Split compound sentences into task clauses
    final clauses = _splitIntoClauses(trimmed);
    final List<ParsedTaskItem> parsedTasks = [];

    for (final clause in clauses) {
      final taskItem = _parseSingleClause(clause);
      if (taskItem != null && taskItem.title.isNotEmpty) {
        parsedTasks.add(taskItem);
      }
    }

    if (parsedTasks.isEmpty) {
      // Fallback: treat whole text as a single task if reasonable
      final fallbackTitle = _cleanPrefixes(trimmed);
      if (fallbackTitle.isNotEmpty) {
        parsedTasks.add(ParsedTaskItem(title: fallbackTitle));
      }
    }

    return ParsedTaskResult(
      tasks: parsedTasks,
      rawInput: trimmed,
      isValid: parsedTasks.isNotEmpty,
      parsingNote: 'Parsed ${parsedTasks.length} task(s) successfully',
    );
  }

  static List<String> _splitIntoClauses(String text) {
    // Normalizes conjunctions and punctuation delimiters
    String normalized = text
        .replaceAll(RegExp(r'\s+and\s+(then\s+)?', caseSensitive: false), ' ;; ')
        .replaceAll(RegExp(r'\s*,\s*(then\s+)?', caseSensitive: false), ' ;; ')
        .replaceAll(RegExp(r'\s*;\s*', caseSensitive: false), ' ;; ')
        .replaceAll(RegExp(r'\n+', caseSensitive: false), ' ;; ')
        .replaceAll(RegExp(r'\s+also\s+', caseSensitive: false), ' ;; ');

    return normalized
        .split(';;')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static ParsedTaskItem? _parseSingleClause(String clause) {
    String cleaned = _cleanPrefixes(clause);
    if (cleaned.isEmpty) return null;

    String? deadline;
    int? durationMinutes;

    // 1. Detect duration e.g. "for an hour", "for 45 mins", "for 30 minutes"
    final durationRegex = RegExp(
      r'for\s+(?:an?\s+hour|1\s+hour|(\d+)\s*(?:hours|hrs|hour|mins|minutes|m))\b',
      caseSensitive: false,
    );
    final durationMatch = durationRegex.firstMatch(cleaned);
    if (durationMatch != null) {
      final matchStr = durationMatch.group(0)!.toLowerCase();
      if (matchStr.contains('hour') && (matchStr.contains('1') || matchStr.contains('an'))) {
        durationMinutes = 60;
      } else {
        final numStr = durationMatch.group(1);
        if (numStr != null) {
          final val = int.tryParse(numStr);
          if (val != null) {
            durationMinutes = matchStr.contains('hour') ? val * 60 : val;
          }
        }
      }
      cleaned = cleaned.replaceRange(durationMatch.start, durationMatch.end, '').trim();
    }

    // 2. Detect deadline e.g. "before 10", "around 7", "at 7pm", "by 22:00"
    final deadlineRegex = RegExp(
      r'(?:before|by|around|at)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)',
      caseSensitive: false,
    );
    final deadlineMatch = deadlineRegex.firstMatch(cleaned);
    if (deadlineMatch != null) {
      final rawTime = deadlineMatch.group(1)!.trim();
      deadline = _normalizeTime(rawTime);
      cleaned = cleaned.replaceRange(deadlineMatch.start, deadlineMatch.end, '').trim();
    }

    // Clean remaining punctuation & extra spaces
    cleaned = cleaned
        .replaceAll(RegExp(r'^[,\.\s]+|[,\.\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.isEmpty) return null;

    // Capitalize first letter
    cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);

    return ParsedTaskItem(
      title: cleaned,
      deadline: deadline,
      durationMinutes: durationMinutes,
    );
  }

  static String _cleanPrefixes(String text) {
    String res = text;
    final prefixPatterns = [
      RegExp(r"^(?:i need to|i have to|i want to|i should|remember to|don't forget to|please|todo:?)\s+", caseSensitive: false),
      RegExp(r"^(?:first|next|then)\s+", caseSensitive: false),
    ];

    for (final pattern in prefixPatterns) {
      res = res.replaceFirst(pattern, '');
    }
    return res.trim();
  }

  static String _normalizeTime(String rawTime) {
    final lower = rawTime.toLowerCase();
    final isPm = lower.contains('pm');
    final isAm = lower.contains('am');
    final digitsOnly = lower.replaceAll(RegExp(r'[a-z\s]'), '');

    if (digitsOnly.contains(':')) {
      final parts = digitsOnly.split(':');
      int h = int.tryParse(parts[0]) ?? 0;
      final m = parts[1];
      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      return '${h.toString().padLeft(2, '0')}:$m';
    } else {
      int h = int.tryParse(digitsOnly) ?? 0;
      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
      // Default heuristics: numbers like 7, 8, 9, 10 without am/pm:
      // if < 7, usually PM (like 2 = 14:00), if >= 7 and < 12 could be evening or morning
      if (!isAm && !isPm && h >= 1 && h <= 11) {
        h += 12; // e.g. 7 -> 19:00, 10 -> 22:00
      }
      return '${h.toString().padLeft(2, '0')}:00';
    }
  }
}
