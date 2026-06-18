/// Date helpers for the `'YYYY-MM-DD'` keys used by [HabitLog.date].
///
/// Logs are keyed by local calendar day (not UTC instants) so that "today"
/// matches the user's wall clock.
class DateUtils {
  DateUtils._();

  /// Formats a [DateTime] as a zero-padded `'YYYY-MM-DD'` day key.
  static String toDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses a `'YYYY-MM-DD'` day key into a local [DateTime] at midnight.
  static DateTime fromDateKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// The day key for today in local time.
  static String todayKey() => toDateKey(DateTime.now());

  /// Whether two dates fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
