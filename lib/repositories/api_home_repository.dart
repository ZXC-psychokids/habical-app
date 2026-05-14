import '../core/api_client.dart';
import '../core/app_logger.dart';
import '../models/home_data.dart';
import '../models/home_day_event_item.dart';
import '../models/home_feed_entry.dart';
import '../models/home_task_item.dart';
import 'home_repository.dart';
import 'package:dio/dio.dart';

class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<HomeData> fetchHomeData({required DateTime day}) async {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final from = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
    ).toUtc().toIso8601String();
    final to = DateTime(
      normalizedDay.year,
      normalizedDay.month,
      normalizedDay.day,
      23,
      59,
      59,
      999,
    ).toUtc().toIso8601String();

    final tasksResponse = await _apiClient.dio.get(
      '/me/tasks',
      queryParameters: {'date': _formatDate(normalizedDay)},
    );
    final eventsResponse = await _apiClient.dio.get(
      '/me/events',
      queryParameters: {
        'from': from,
        'to': to,
      },
    );
    final feedResponse = await _apiClient.dio.get(
      '/me/feed',
      queryParameters: {
        'limit': 20,
      },
    );

    final rawTasks = tasksResponse.data;
    final rawEvents = eventsResponse.data;
    final rawFeed = feedResponse.data;
    final tasksPayload = _extractListPayload(rawTasks, primaryKey: 'items');
    final eventsPayload = _extractListPayload(rawEvents, primaryKey: 'items');
    if (tasksPayload == null || eventsPayload == null || rawFeed is! Map) {
      AppLogger.e(
        'Failed to parse HomeData payload',
        StateError('Invalid home payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid home payload.');
    }

    final tasks = tasksPayload
        .map((item) => _parseTask(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false)
      ..sort((a, b) => a.position.compareTo(b.position));

    final events = eventsPayload
        .map((item) => _parseEvent(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false)
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final feedMap = Map<String, dynamic>.from(rawFeed);
    final rawItems = feedMap['items'];
    if (rawItems is! List) {
      AppLogger.e(
        'Failed to parse HomeFeed items payload',
        StateError('Invalid feed items payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid feed items payload.');
    }
    final feedEntries = rawItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(_parseFeedEntry)
        .toList(growable: false);

    final nextCursorRaw = feedMap['nextCursor'];
    final nextCursor = nextCursorRaw is String && nextCursorRaw.isNotEmpty
        ? nextCursorRaw
        : null;

    return HomeData(
      day: normalizedDay,
      tasks: tasks,
      events: events,
      feedEntries: feedEntries,
      nextFeedCursor: nextCursor,
    );
  }

  @override
  Future<void> toggleTask({required String taskId}) async {
    await _apiClient.dio.post('/me/tasks/$taskId/toggle');
  }

  @override
  Future<HomeTaskItem> createTask({
    required String title,
    required DateTime taskDate,
    required int position,
    String? manualColor,
  }) async {
    final payload = {
      'title': title.trim(),
      'taskDate': _formatDate(taskDate),
      'position': position,
      if (manualColor != null && manualColor.isNotEmpty) 'manualColor': manualColor,
    };
    Response<dynamic> response;
    try {
      response = await _apiClient.dio.post('/me/tasks', data: payload);
    } on DioException catch (error) {
      // Compatibility fallback for gateways that still expect "date".
      if (error.response?.statusCode == 400 || error.response?.statusCode == 500) {
        response = await _apiClient.dio.post(
          '/me/tasks',
          data: {
            ...payload,
            'date': _formatDate(taskDate),
          },
        );
      } else {
        rethrow;
      }
    }

    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse created HomeTask payload',
        StateError('Invalid created task payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid created task payload.');
    }
    return _parseTask(Map<String, dynamic>.from(raw));
  }

  @override
  Future<HomeTaskItem> updateTask({
    required String taskId,
    required HomeTaskUpdateInput input,
  }) async {
    if (!input.hasChanges) {
      throw ArgumentError('No fields to update.');
    }

    final data = <String, dynamic>{};
    if (input.title != null) {
      data['title'] = input.title!.trim();
    }
    if (input.taskDate != null) {
      data['taskDate'] = _formatDate(input.taskDate!);
    }
    if (input.position != null) {
      data['position'] = input.position;
    }
    if (input.clearManualColor) {
      data['manualColor'] = null;
    } else if (input.manualColor != null) {
      data['manualColor'] = input.manualColor;
    }

    final response = await _apiClient.dio.patch('/me/tasks/$taskId', data: data);
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse updated HomeTask payload',
        StateError('Invalid updated task payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid updated task payload.');
    }
    return _parseTask(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    await _apiClient.dio.delete('/me/tasks/$taskId');
  }

  @override
  Future<void> reorderTasks({required List<HomeTaskReorderItem> items}) async {
    await _apiClient.dio.post(
      '/me/tasks/reorder',
      data: {
        'items': items
            .map(
              (item) => {
                'taskId': item.taskId,
                'position': item.position,
                'taskDate': _formatDate(item.taskDate),
              },
            )
            .toList(growable: false),
      },
    );
  }

  @override
  Future<HomeTaskItem> linkTaskToEvent({
    required String taskId,
    required String eventId,
  }) async {
    final response = await _apiClient.dio.post(
      '/me/tasks/$taskId/event-link',
      data: {'eventId': eventId},
    );

    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse linked HomeTask payload',
        StateError('Invalid linked task payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid linked task payload.');
    }
    return _parseTask(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> unlinkTaskFromEvent({required String taskId}) async {
    await _apiClient.dio.delete('/me/tasks/$taskId/event-link');
  }

  HomeTaskItem _parseTask(Map<String, dynamic> map) {
    try {
    final habitMap = _asMap(map['habit']);
    final eventMap = _asMap(map['event']);

    return HomeTaskItem(
      id: _requiredString(map['id'], 'id'),
      title: _requiredString(map['title'], 'title'),
      taskDate: _requiredDate(map['taskDate'], 'taskDate'),
      position: _requiredInt(map['position'], 'position'),
      isCompleted: _requiredBool(map['isCompleted'], 'isCompleted'),
      manualColor: _nullableString(map['manualColor']),
      habit: habitMap == null
          ? null
          : HomeTaskHabitRef(
              id: _requiredString(habitMap['id'], 'habit.id'),
              title: _requiredString(habitMap['title'], 'habit.title'),
              color: _requiredString(habitMap['color'], 'habit.color'),
            ),
      event: eventMap == null
          ? null
          : HomeTaskEventRef(
              id: _requiredString(eventMap['id'], 'event.id'),
              startsAt: _requiredDateTime(eventMap['startsAt'], 'event.startsAt'),
              endsAt: _requiredDateTime(eventMap['endsAt'], 'event.endsAt'),
            ),
    );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to parse HomeTaskItem data=${AppLogger.pretty(map)}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  HomeDayEventItem _parseEvent(Map<String, dynamic> map) {
    try {
    final categoryMap = _asMap(map['category']);
    if (categoryMap == null) {
      throw StateError('Event category is missing.');
    }

    final taskMap = _asMap(map['task']);
    return HomeDayEventItem(
      id: _requiredString(map['id'], 'id'),
      title: _requiredString(map['title'], 'title'),
      startsAt: _requiredDateTime(map['startsAt'], 'startsAt'),
      endsAt: _requiredDateTime(map['endsAt'], 'endsAt'),
      categoryId: _requiredString(categoryMap['id'], 'category.id'),
      categoryName: _requiredString(categoryMap['title'], 'category.title'),
      categoryColor: _requiredString(categoryMap['color'], 'category.color'),
      task: taskMap == null
          ? null
          : HomeDayEventTaskRef(
              id: _requiredString(taskMap['id'], 'task.id'),
              title: _requiredString(taskMap['title'], 'task.title'),
            ),
    );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to parse HomeDayEventItem data=${AppLogger.pretty(map)}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  HomeFeedEntry _parseFeedEntry(Map<String, dynamic> map) {
    try {
    final actorMap = _asMap(map['actor']);
    if (actorMap == null) {
      throw StateError('Feed actor is missing.');
    }

    final relatedUserMap = _asMap(map['relatedUser']);
    final relatedHabitMap = _asMap(map['relatedHabit']);

    return HomeFeedEntry(
      id: _requiredString(map['id'], 'id'),
      type: _parseFeedType(_requiredString(map['type'], 'type')),
      actor: HomeFeedUserRef(
        id: _requiredString(actorMap['id'], 'actor.id'),
        handle: _requiredString(actorMap['handle'], 'actor.handle'),
        avatarUrl: _requiredString(actorMap['avatarUrl'], 'actor.avatarUrl'),
      ),
      relatedUser: relatedUserMap == null
          ? null
          : HomeFeedUserRef(
              id: _requiredString(relatedUserMap['id'], 'relatedUser.id'),
              handle: _requiredString(
                relatedUserMap['handle'],
                'relatedUser.handle',
              ),
              avatarUrl: _requiredString(
                relatedUserMap['avatarUrl'],
                'relatedUser.avatarUrl',
              ),
            ),
      relatedHabit: relatedHabitMap == null
          ? null
          : HomeFeedHabitRef(
              id: _requiredString(relatedHabitMap['id'], 'relatedHabit.id'),
              title: _requiredString(
                relatedHabitMap['title'],
                'relatedHabit.title',
              ),
              color: _requiredString(
                relatedHabitMap['color'],
                'relatedHabit.color',
              ),
            ),
      streakValue: _nullableInt(map['streakValue']),
      createdAt: _requiredDateTime(map['createdAt'], 'createdAt'),
    );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to parse HomeFeedEntry data=${AppLogger.pretty(map)}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  HomeFeedType _parseFeedType(String value) {
    return switch (value) {
      'friend_added' => HomeFeedType.friendAdded,
      'habit_streak' => HomeFeedType.habitStreak,
      'habit_created' => HomeFeedType.habitCreated,
      'shared_habit_reminder' => HomeFeedType.sharedHabitReminder,
      _ => throw StateError('Unsupported feed type "$value".'),
    };
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  DateTime _requiredDate(dynamic value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    throw StateError('Invalid "$field" field.');
  }

  DateTime _requiredDateTime(dynamic value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw StateError('Invalid "$field" field.');
  }

  String _requiredString(dynamic value, String field) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw StateError('Invalid "$field" field.');
  }

  String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  int _requiredInt(dynamic value, String field) {
    if (value is int) {
      return value;
    }
    throw StateError('Invalid "$field" field.');
  }

  int? _nullableInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return null;
  }

  bool _requiredBool(dynamic value, String field) {
    if (value is bool) {
      return value;
    }
    throw StateError('Invalid "$field" field.');
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  List<dynamic>? _extractListPayload(dynamic raw, {required String primaryKey}) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final items = map[primaryKey] ?? map['data'] ?? map['events'] ?? map['tasks'];
      if (items is List) {
        return items;
      }
    }
    return null;
  }

}
