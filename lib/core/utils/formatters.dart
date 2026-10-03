import 'package:intl/intl.dart';

class Formatters {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else if (seconds > 0) {
      return '${seconds}s';
    } else {
      return '0m';
    }
  }

  static String formatDurationMs(int millis) {
    return formatDuration(Duration(milliseconds: millis));
  }

  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  static String formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  static String formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatSessionRange(DateTime start, DateTime end) {
    final startStr = DateFormat('h:mm a').format(start);
    final endStr = DateFormat('h:mm a').format(end);
    return '$startStr → $endStr';
  }

  static String formatPercentage(double value) {
    return '${(value * 100).round()}%';
  }
}
