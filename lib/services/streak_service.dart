class StreakService {
  const StreakService();

  int calculateStreakDays({
    required int periodicityDays,
    required List<DateTime> completionDates,
    required DateTime asOf,
    int seedDays = 0,
  }) {
    if (periodicityDays <= 0) {
      return seedDays;
    }

    final asOfDay = _dayOnly(asOf);
    final uniqueDays =
        completionDates
            .map(_dayOnly)
            .where((day) => !day.isAfter(asOfDay))
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => b.compareTo(a));

    if (uniqueDays.isEmpty) {
      return seedDays;
    }

    var cursor = asOfDay;
    var completedWindows = 0;

    while (true) {
      final windowStart = cursor.subtract(Duration(days: periodicityDays - 1));
      final hasCompletionInWindow = uniqueDays.any(
        (day) => !day.isAfter(cursor) && !day.isBefore(windowStart),
      );

      if (!hasCompletionInWindow) {
        break;
      }

      completedWindows++;
      cursor = windowStart.subtract(const Duration(days: 1));
    }

    return seedDays + (completedWindows * periodicityDays);
  }

  DateTime _dayOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
