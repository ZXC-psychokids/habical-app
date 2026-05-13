import '../models/models.dart';

abstract class HabitsRepository {
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  });

  Future<Habit> addHabit({
    required String userId,
    required String title,
    required DateTime startDate,
    String color = '#5AA9E6',
    String scheduleType = 'daily',
    int intervalDays = 1,
    List<int> weekdays = const <int>[],
  });

  Future<HabitDetailsData> fetchHabitDetails({required String habitId});

  Future<List<HabitCalendarDaySummary>> fetchCalendarSummary({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  });

  Future<Habit> updateHabit({
    required String habitId,
    String? title,
    String? color,
    String? scheduleType,
    int? intervalDays,
    List<int>? weekdays,
  });

  Future<void> deleteHabit({required String habitId});

  Future<SharedHabitCreationResult> createSharedHabit({
    required String friendUserId,
    required String title,
    required String color,
    required String scheduleType,
    required int intervalDays,
    required List<int> weekdays,
  });

  Future<SharedHabitDetails> fetchSharedHabitDetails({
    required String sharedHabitPairId,
  });

  Future<SharedHabitRemindResult> remindSharedHabit({
    required String sharedHabitPairId,
    required String taskId,
  });
}
