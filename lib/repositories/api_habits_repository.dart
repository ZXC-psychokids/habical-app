import '../core/api_client.dart';
import '../core/app_logger.dart';
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
      AppLogger.e(
        'Failed to parse habits list payload',
        StateError('Invalid habits list payload.'),
        StackTrace.current,
      );
      throw StateError('РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚ СЃРїРёСЃРєР° РїСЂРёРІС‹С‡РµРє.');
    }

    final targetDate = asOf ?? DateTime.now();

    final habits = rawList
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) {
          try {
            return Habit.fromMap(map);
          } catch (error, stackTrace) {
            AppLogger.e(
              'Failed to parse Habit data=${AppLogger.pretty(map)}',
              error,
              stackTrace,
            );
            rethrow;
          }
        })
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
      throw ArgumentError('РќР°Р·РІР°РЅРёРµ РїСЂРёРІС‹С‡РєРё РЅРµ РјРѕР¶РµС‚ Р±С‹С‚СЊ РїСѓСЃС‚С‹Рј.');
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
      AppLogger.e(
        'Failed to parse created habit payload',
        StateError('Invalid created habit payload.'),
        StackTrace.current,
      );
      throw StateError('РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚ СЃРѕР·РґР°РЅРЅРѕР№ РїСЂРёРІС‹С‡РєРё.');
    }

    final rawMap = Map<String, dynamic>.from(raw);
    try {
      return Habit.fromMap(rawMap);
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to parse created Habit data=${AppLogger.pretty(rawMap)}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<HabitDetailsData> fetchHabitDetails({required String habitId}) async {
    final habitResponse = await _apiClient.dio.get('/habits/$habitId');
    final habitRaw = habitResponse.data;
    if (habitRaw is! Map) {
      AppLogger.e(
        'Failed to parse habit details payload',
        StateError('Invalid habit details payload.'),
        StackTrace.current,
      );
      throw StateError('РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚ РїСЂРёРІС‹С‡РєРё.');
    }

    final habitMap = Map<String, dynamic>.from(habitRaw);
    final habit = (() {
      try {
        return Habit.fromMap(habitMap);
      } catch (error, stackTrace) {
        AppLogger.e(
          'Failed to parse Habit details data=${AppLogger.pretty(habitMap)}',
          error,
          stackTrace,
        );
        rethrow;
      }
    })();
    final tasks = await _fetchTasksForHabit(habitId);

    tasks.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return HabitDetailsData(habit: habit, tasks: tasks);
  }

  Future<List<Task>> _fetchTasksForHabit(String habitId) async {
    final response = await _apiClient.dio.get('/habits/$habitId/tasks');

    final rawList = response.data;
    if (rawList is! List) {
      AppLogger.e(
        'Failed to parse habit tasks payload',
        StateError('Invalid habit tasks payload.'),
        StackTrace.current,
      );
      throw StateError('РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚ СЃРїРёСЃРєР° Р·Р°РґР°С‡ РїСЂРёРІС‹С‡РєРё.');
    }

    return rawList
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) {
          try {
            return Task.fromMap(map);
          } catch (error, stackTrace) {
            AppLogger.e(
              'Failed to parse Habit Task data=${AppLogger.pretty(map)}',
              error,
              stackTrace,
            );
            rethrow;
          }
        })
        .toList(growable: false);
  }
}
