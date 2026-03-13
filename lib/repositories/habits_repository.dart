import '../models/models.dart';
import 'in_memory_app_store.dart';
import '../services/streak_service.dart';

abstract class HabitsRepository {
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  });

  Future<Habit> addHabit({
    required String userId,
    required String title,
    required DateTime startDate,
  });

  Future<HabitDetailsData> fetchHabitDetails({required String habitId});
}

class InMemoryHabitsRepository implements HabitsRepository {
  InMemoryHabitsRepository({
    DateTime? now,
    StreakService? streakService,
    InMemoryAppStore? store,
  }) : _store = store ?? InMemoryAppStore(now: now),
       _streakService = streakService ?? const StreakService();

  final InMemoryAppStore _store;
  final StreakService _streakService;

  @override
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  }) async {
    final targetDate = asOf ?? _store.now;

    final items =
        _store.habits
            .where((habit) => habit.userId == userId)
            .map((habit) {
              final habitTasks =
                  _store.tasksByHabit[habit.id] ?? const <Task>[];
              final completionDates = habitTasks
                  .where((task) => task.isCompleted)
                  .map((task) => task.startsAt)
                  .toList(growable: false);

              final streakDays = _streakService.calculateStreakDays(
                periodicityDays: habit.periodicityDays,
                completionDates: completionDates,
                asOf: targetDate,
                seedDays: habit.initialStreakDays,
              );

              return HabitListItem(habit: habit, streakDays: streakDays);
            })
            .toList(growable: false)
          ..sort((a, b) => b.streakDays.compareTo(a.streakDays));

    return items;
  }

  @override
  Future<Habit> addHabit({
    required String userId,
    required String title,
    required DateTime startDate,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Название привычки не может быть пустым.');
    }

    final habit = Habit(
      id: 'habit_${_store.nextHabitId++}',
      title: normalizedTitle,
      periodicityDays: 1,
      initialStreakDays: 0,
      userId: userId,
    );

    _store.habits = [..._store.habits, habit];
    _store.tasksByHabit[habit.id] = _store.generateTasksForPeriod(
      habit: habit,
      startDay: _dayOnly(startDate),
      days: 30,
    );
    return habit;
  }

  @override
  Future<HabitDetailsData> fetchHabitDetails({required String habitId}) async {
    Habit? habit;
    for (final item in _store.habits) {
      if (item.id == habitId) {
        habit = item;
        break;
      }
    }
    if (habit == null) {
      throw StateError('Привычка не найдена.');
    }

    final tasks = [...(_store.tasksByHabit[habit.id] ?? const <Task>[])]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return HabitDetailsData(habit: habit, tasks: tasks);
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
