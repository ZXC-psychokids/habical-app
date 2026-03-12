import '../models/models.dart';
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
  InMemoryHabitsRepository({DateTime? now, StreakService? streakService})
    : _now = now ?? DateTime.now(),
      _streakService = streakService ?? const StreakService() {
    _seedData();
  }

  final DateTime _now;
  final StreakService _streakService;

  late List<Habit> _habits;
  late Map<String, List<Task>> _tasksByHabit;
  int _nextHabitId = 1;

  @override
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  }) async {
    final targetDate = asOf ?? _now;

    final items =
        _habits
            .where((habit) => habit.userId == userId)
            .map((habit) {
              final habitTasks = _tasksByHabit[habit.id] ?? const <Task>[];
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
      throw ArgumentError('Habit title cannot be empty.');
    }

    final habit = Habit(
      id: 'habit_${_nextHabitId++}',
      title: normalizedTitle,
      periodicityDays: 1,
      initialStreakDays: 0,
      userId: userId,
    );

    _habits = [..._habits, habit];
    _tasksByHabit[habit.id] = _generateTasksForPeriod(
      habit: habit,
      startDay: _dayOnly(startDate),
      days: 30,
    );
    return habit;
  }

  @override
  Future<HabitDetailsData> fetchHabitDetails({required String habitId}) async {
    Habit? habit;
    for (final item in _habits) {
      if (item.id == habitId) {
        habit = item;
        break;
      }
    }
    if (habit == null) {
      throw StateError('Habit not found.');
    }

    final tasks = [...(_tasksByHabit[habit.id] ?? const <Task>[])]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return HabitDetailsData(habit: habit, tasks: tasks);
  }

  List<Task> _generateTasksForPeriod({
    required Habit habit,
    required DateTime startDay,
    required int days,
    Set<DateTime> completedDays = const <DateTime>{},
  }) {
    final normalizedCompletedDays = completedDays.map(_dayOnly).toSet();
    final tasks = <Task>[];
    final step = habit.periodicityDays <= 0 ? 1 : habit.periodicityDays;
    for (var offset = 0; offset < days; offset += step) {
      final day = startDay.add(Duration(days: offset));
      final start = day.add(const Duration(hours: 9));
      final end = start.add(const Duration(hours: 1));
      final isCompleted = normalizedCompletedDays.contains(_dayOnly(day));

      tasks.add(
        Task(
          id: 'task_${habit.id}_$offset',
          startsAt: start,
          endsAt: end,
          title: habit.title,
          isCompleted: isCompleted,
        ),
      );
    }

    return tasks;
  }

  void _seedData() {
    final today = _dayOnly(_now);

    _habits = const [
      Habit(
        id: 'habit_1',
        title: 'Read 30 minutes',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_me',
      ),
      Habit(
        id: 'habit_2',
        title: 'Gym workout',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_me',
      ),
      Habit(
        id: 'habit_3',
        title: 'Drink enough water',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_me',
      ),
    ];

    _tasksByHabit = {
      'habit_1': _generateTasksForPeriod(
        habit: _habits[0],
        startDay: today.subtract(const Duration(days: 12)),
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
        },
      ),
      'habit_2': _generateTasksForPeriod(
        habit: _habits[1],
        startDay: today.subtract(const Duration(days: 12)),
        days: 42,
        completedDays: {
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 3)),
          today.subtract(const Duration(days: 5)),
        },
      ),
      'habit_3': _generateTasksForPeriod(
        habit: _habits[2],
        startDay: today.subtract(const Duration(days: 12)),
        days: 42,
        completedDays: {today, today.subtract(const Duration(days: 1))},
      ),
    };

    _nextHabitId = _habits.length + 1;
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
