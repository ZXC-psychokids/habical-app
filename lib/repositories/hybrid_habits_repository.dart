import '../models/models.dart';
import '../services/streak_service.dart';
import 'habits_repository.dart';
import 'in_memory_app_store.dart';

class HybridHabitsRepository implements HabitsRepository {
  HybridHabitsRepository({
    required HabitsRepository remoteRepository,
    required InMemoryAppStore store,
    StreakService? streakService,
  }) : _remoteRepository = remoteRepository,
       _store = store,
       _streakService = streakService ?? const StreakService();

  final HabitsRepository _remoteRepository;
  final InMemoryAppStore _store;
  final StreakService _streakService;

  @override
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  }) async {
    final targetDate = asOf ?? _store.now;

    final remoteItems = await _remoteRepository.fetchHabits(
      userId: userId,
      asOf: targetDate,
    );

    final localItems = _store.habits
        .where((habit) => habit.userId == userId)
        .map((habit) {
          final habitTasks = _store.tasksByHabit[habit.id] ?? const <Task>[];
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
        .toList(growable: false);

    final byId = <String, HabitListItem>{};

    for (final item in remoteItems) {
      byId[item.habit.id] = item;
    }
    for (final item in localItems) {
      byId[item.habit.id] = item;
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) => b.streakDays.compareTo(a.streakDays));
    return merged;
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

    try {
      await _remoteRepository.addHabit(
        userId: userId,
        title: normalizedTitle,
        startDate: startDate,
      );
    } catch (_) {
      // Для демо не валим сценарий, если мок не умеет жить как настоящая БД.
    }

    final habit = Habit(
      id: 'local_habit_${_store.nextHabitId++}',
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
    for (final habit in _store.habits) {
      if (habit.id == habitId) {
        final tasks = [...(_store.tasksByHabit[habit.id] ?? const <Task>[])]
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

        return HabitDetailsData(habit: habit, tasks: tasks);
      }
    }

    return _remoteRepository.fetchHabitDetails(habitId: habitId);
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
