import '../core/api_client.dart';
import '../models/models.dart';
import 'habits_repository.dart';

class ApiHabitsRepository implements HabitsRepository {
  ApiHabitsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<HabitListItem>> fetchHabits({
    required String userId,
    DateTime? asOf,
  }) async {
    final response = await _apiClient.dio.get('/me/habits');
    final raw = response.data;
    final listPayload = _extractHabitsList(raw);
    if (listPayload == null) {
      throw StateError('Invalid habits list payload.');
    }

    final items = listPayload
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) {
          final habit = Habit.fromMap(map);
          final streakDays = _extractStreakDays(map);
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
    String color = '#5AA9E6',
    String scheduleType = 'daily',
    int intervalDays = 1,
    List<int> weekdays = const <int>[],
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Habit title cannot be empty.');
    }
    final requestBody = {
      'title': normalizedTitle,
      'color': color,
      'scheduleType': scheduleType,
      'intervalDays': intervalDays,
      'weekdays': weekdays,
    };
    Response<dynamic> response;
    try {
      response = await _apiClient.dio.post('/me/habits', data: requestBody);
    } on Exception catch (error) {
      response = await _fallbackAddHabitIfNeeded(
        error: error,
        title: normalizedTitle,
        startDate: startDate,
        color: color,
        scheduleType: scheduleType,
        intervalDays: intervalDays,
        weekdays: weekdays,
      );
    }

    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Invalid created habit payload.');
    }
    return Habit.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<HabitDetailsData> fetchHabitDetails({required String habitId}) async {
    final response = await _apiClient.dio.get('/me/habits/$habitId');
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Invalid habit details payload.');
    }

    final map = Map<String, dynamic>.from(raw);
    final habit = Habit.fromMap(map);
    final tasks = _extractTasks(map)..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return HabitDetailsData(habit: habit, tasks: tasks);
  }

  @override
  Future<List<HabitCalendarDaySummary>> fetchCalendarSummary({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/habits/calendar-summary',
      queryParameters: {
        'from': _formatDate(fromInclusive),
        'to': _formatDate(toInclusive),
      },
    );
    final raw = response.data;
    final listPayload = _extractCalendarDays(raw);
    if (listPayload == null) {
      throw StateError('Invalid habits calendar summary payload.');
    }

    final result = <HabitCalendarDaySummary>[];
    for (final item in listPayload) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      final date = _extractDate(map);
      if (date == null) {
        continue;
      }
      final colors = _extractCompletedColors(map);
      result.add(
        HabitCalendarDaySummary(
          date: date,
          completedHabits: colors,
        ),
      );
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Future<Habit> updateHabit({
    required String habitId,
    String? title,
    String? color,
    String? scheduleType,
    int? intervalDays,
    List<int>? weekdays,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) {
      payload['title'] = title.trim();
    }
    if (color != null) {
      payload['color'] = color;
    }
    if (scheduleType != null) {
      payload['scheduleType'] = scheduleType;
    }
    if (intervalDays != null) {
      payload['intervalDays'] = intervalDays;
    }
    if (weekdays != null) {
      payload['weekdays'] = weekdays;
    }
    if (payload.isEmpty) {
      throw ArgumentError('No habit fields to update.');
    }

    final response = await _apiClient.dio.patch(
      '/me/habits/$habitId',
      data: payload,
    );
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Invalid updated habit payload.');
    }
    return Habit.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> deleteHabit({required String habitId}) async {
    await _apiClient.dio.delete('/me/habits/$habitId');
  }

  @override
  Future<SharedHabitCreationResult> createSharedHabit({
    required String friendUserId,
    required String title,
    required String color,
    required String scheduleType,
    required int intervalDays,
    required List<int> weekdays,
  }) async {
    final response = await _apiClient.dio.post(
      '/me/shared-habits',
      data: {
        'friendUserId': friendUserId,
        'title': title.trim(),
        'color': color,
        'scheduleType': scheduleType,
        'intervalDays': intervalDays,
        'weekdays': weekdays,
      },
    );
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Invalid shared habit creation payload.');
    }
    final map = Map<String, dynamic>.from(raw);
    final firstHabit = _asMap(map['firstHabit']);
    final secondHabit = _asMap(map['secondHabit']);
    if (firstHabit == null || secondHabit == null) {
      throw StateError('Invalid shared habit creation payload.');
    }
    return SharedHabitCreationResult(
      sharedHabitPairId: _requiredString(map['sharedHabitPairId'], 'sharedHabitPairId'),
      firstHabitId: _requiredString(firstHabit['id'], 'firstHabit.id'),
      secondHabitId: _requiredString(secondHabit['id'], 'secondHabit.id'),
    );
  }

  @override
  Future<SharedHabitDetails> fetchSharedHabitDetails({
    required String sharedHabitPairId,
  }) async {
    final response = await _apiClient.dio.get('/me/shared-habits/$sharedHabitPairId');
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Invalid shared habit details payload.');
    }
    final map = Map<String, dynamic>.from(raw);
    final youRaw = _asMap(map['you']);
    final friendRaw = _asMap(map['friend']);
    if (youRaw == null || friendRaw == null) {
      throw StateError('Invalid shared habit participant payload.');
    }
    return SharedHabitDetails(
      sharedHabitPairId: _requiredString(map['sharedHabitPairId'], 'sharedHabitPairId'),
      title: _requiredString(map['title'], 'title'),
      color: _requiredString(map['color'], 'color'),
      streakDays: _requiredInt(map['streakDays'], 'streakDays'),
      youCompletedToday: _requiredBool(map['youCompletedToday'], 'youCompletedToday'),
      friendCompletedToday: _requiredBool(map['friendCompletedToday'], 'friendCompletedToday'),
      you: SharedHabitParticipant(
        id: _requiredString(youRaw['id'], 'you.id'),
        handle: _requiredString(youRaw['handle'], 'you.handle'),
      ),
      friend: SharedHabitParticipant(
        id: _requiredString(friendRaw['id'], 'friend.id'),
        handle: _requiredString(friendRaw['handle'], 'friend.handle'),
      ),
      todayTaskId: _optionalTaskId(map),
    );
  }

  @override
  Future<SharedHabitRemindResult> remindSharedHabit({
    required String sharedHabitPairId,
    required String taskId,
  }) async {
    final response = await _apiClient.dio.post(
      '/me/shared-habits/$sharedHabitPairId/remind',
      data: {'taskId': taskId},
    );
    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Invalid shared habit remind payload.');
    }
    final map = Map<String, dynamic>.from(raw);
    return SharedHabitRemindResult(
      message: _requiredString(map['message'], 'message'),
    );
  }

  List<Task> _extractTasks(Map<String, dynamic> map) {
    final tasksRaw = map['tasks'];
    if (tasksRaw is! List) {
      return const <Task>[];
    }

    final tasks = <Task>[];
    for (final item in tasksRaw) {
      if (item is Map) {
        tasks.add(Task.fromMap(Map<String, dynamic>.from(item)));
      }
    }
    return tasks;
  }

  int _extractStreakDays(Map<String, dynamic> map) {
    final direct = map['streakDays'];
    if (direct is int && direct >= 0) {
      return direct;
    }

    final streak = map['streak'];
    if (streak is Map) {
      final days = streak['days'];
      if (days is int && days >= 0) {
        return days;
      }
    }

    return 0;
  }

  DateTime? _extractDate(Map<String, dynamic> map) {
    final value = map['date'] ?? map['day'];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  List<HabitCalendarCompletedHabit> _extractCompletedColors(Map<String, dynamic> map) {
    final completed = <HabitCalendarCompletedHabit>[];
    final directColors = map['completedHabitColors'];
    if (directColors is List) {
      var index = 0;
      for (final value in directColors) {
        if (value is String && value.trim().isNotEmpty) {
          completed.add(
            HabitCalendarCompletedHabit(
              habitId: 'unknown_$index',
              color: value,
            ),
          );
          index++;
        }
      }
      return completed;
    }

    final completedHabits = map['completedHabits'];
    if (completedHabits is List) {
      for (final item in completedHabits) {
        if (item is Map) {
          final habitId = item['habitId'];
          final habitColor = item['color'];
          if (habitId is String &&
              habitId.trim().isNotEmpty &&
              habitColor is String &&
              habitColor.trim().isNotEmpty) {
            completed.add(
              HabitCalendarCompletedHabit(
                habitId: habitId,
                color: habitColor,
              ),
            );
          }
        }
      }
    }
    return completed;
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<Response<dynamic>> _fallbackAddHabitIfNeeded({
    required Exception error,
    required String title,
    required DateTime startDate,
    required String color,
    required String scheduleType,
    required int intervalDays,
    required List<int> weekdays,
  }) async {
    if (error is DioException && error.response?.statusCode == 500) {
      final periodicityDays = scheduleType == 'interval' ? intervalDays : 1;
      return _apiClient.dio.post(
        '/me/habits',
        data: {
          'title': title,
          'color': color,
          'scheduleType': scheduleType,
          'intervalDays': intervalDays,
          'weekdays': weekdays,
          'startDate': _formatDate(startDate),
          'periodicityDays': periodicityDays,
        },
      );
    }
    throw error;
  }

  List<dynamic>? _extractHabitsList(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final items = map['items'] ?? map['habits'];
      if (items is List) {
        return items;
      }
    }
    return null;
  }

  List<dynamic>? _extractCalendarDays(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final days = map['days'];
      if (days is List) {
        return days;
      }
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _requiredString(dynamic value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  int _requiredInt(dynamic value, String fieldName) {
    if (value is int) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  bool _requiredBool(dynamic value, String fieldName) {
    if (value is bool) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  String? _optionalTaskId(Map<String, dynamic> map) {
    const keys = <String>['taskId', 'todayTaskId', 'currentTaskId'];
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
