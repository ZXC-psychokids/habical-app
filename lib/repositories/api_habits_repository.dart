import '../core/api_client.dart';
import '../models/models.dart';
import '../services/streak_service.dart';
import 'habits_repository.dart';

class ApiHabitsRepository implements HabitsRepository {
  ApiHabitsRepository({
    required ApiClient apiClient,
    StreakService? streakService,
  }) : _apiClient = apiClient,
       _streakService = streakService ?? const StreakService();

  final ApiClient _apiClient;
  final StreakService _streakService;

  @override
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  }) async {
    final response = await _apiClient.dio.get('/users/$userId/habits');

    final rawList = response.data;
    if (rawList is! List) {
      throw StateError('Некорректный формат списка привычек.');
    }

    final targetDate = asOf ?? DateTime.now();

    final habits = rawList
        .map((item) => Habit.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);

    final result = <HabitListItem>[];

    for (final habit in habits) {
      final tasks = await _fetchTasksForHabit(habit.id);

      final completionDates = tasks
          .where((task) => task.isCompleted)
          .map((task) => task.startsAt)
          .toList(growable: false);

      final streakDays = _streakService.calculateStreakDays(
        periodicityDays: habit.periodicityDays,
        completionDates: completionDates,
        asOf: targetDate,
        seedDays: habit.initialStreakDays,
      );

      result.add(HabitListItem(habit: habit, streakDays: streakDays));
    }

    result.sort((a, b) => b.streakDays.compareTo(a.streakDays));
    return result;
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

    final response = await _apiClient.dio.post(
      '/users/$userId/habits',
      data: {
        'title': normalizedTitle,
        'periodicityDays': 1,
        'initialStreakDays': 0,
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Некорректный формат созданной привычки.');
    }

    return Habit.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<HabitDetailsData> fetchHabitDetails({required String habitId}) async {
    final habitResponse = await _apiClient.dio.get('/habits/$habitId');
    final habitRaw = habitResponse.data;
    if (habitRaw is! Map) {
      throw StateError('Некорректный формат привычки.');
    }

    final habit = Habit.fromMap(Map<String, dynamic>.from(habitRaw));
    final tasks = await _fetchTasksForHabit(habitId);

    tasks.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return HabitDetailsData(habit: habit, tasks: tasks);
  }

  Future<List<Task>> _fetchTasksForHabit(String habitId) async {
    final response = await _apiClient.dio.get('/habits/$habitId/tasks');

    final rawList = response.data;
    if (rawList is! List) {
      throw StateError('Некорректный формат списка задач привычки.');
    }

    return rawList
        .map((item) => Task.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }
}