import 'package:flutter_test/flutter_test.dart';
import 'package:habical/services/streak_service.dart';

void main() {
  group('StreakService', () {
    test('does not reset daily streak when new day is not completed yet', () {
      const service = StreakService();
      final asOf = DateTime(2026, 3, 13);
      final completionDates = [
        DateTime(2026, 3, 12),
        DateTime(2026, 3, 11),
        DateTime(2026, 3, 10),
      ];

      final streak = service.calculateStreakDays(
        periodicityDays: 1,
        completionDates: completionDates,
        asOf: asOf,
      );

      expect(streak, 3);
    });

    test('resets daily streak after a fully missed previous day', () {
      const service = StreakService();
      final asOf = DateTime(2026, 3, 13);
      final completionDates = [
        DateTime(2026, 3, 11),
        DateTime(2026, 3, 10),
      ];

      final streak = service.calculateStreakDays(
        periodicityDays: 1,
        completionDates: completionDates,
        asOf: asOf,
      );

      expect(streak, 0);
    });

    test('keeps previous window streak for periodic habits until window passes', () {
      const service = StreakService();
      final asOf = DateTime(2026, 3, 4);
      final completionDates = [
        DateTime(2026, 3, 1),
      ];

      final streak = service.calculateStreakDays(
        periodicityDays: 3,
        completionDates: completionDates,
        asOf: asOf,
      );

      expect(streak, 3);
    });
  });
}
