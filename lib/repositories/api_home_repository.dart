import '../core/api_client.dart';
import '../models/event.dart';
import '../models/home_data.dart';
import '../models/home_event_item.dart';
import '../models/home_feed_item.dart';
import '../models/task.dart';
import 'home_repository.dart';

class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<HomeData> fetchHomeData({
    required String userId,
    DateTime? day,
  }) async {
    final selectedDay = _dayOnly(day ?? DateTime.now());
    final from = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final to = from.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    final events = await _fetchEventsForUser(
      userId: userId,
      fromInclusive: from,
      toInclusive: to,
    );

    final feedItems = _apiClient.isCurrentUser(userId)
        ? await _fetchFeedItems()
        : const <HomeFeedItem>[];

    return HomeData(
      day: selectedDay,
      tasks: const <Task>[],
      events: events,
      feedItems: feedItems,
    );
  }

  @override
  Future<void> toggleTask({
    required String taskId,
  }) async {
    // Не падаем, пока backend-зона задач (участник 1) не готова.
  }

  @override
  Future<List<HomeEventItem>> fetchEventsInRange({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    return _fetchEventsForUser(
      userId: userId,
      fromInclusive: fromInclusive,
      toInclusive: toInclusive,
    );
  }

  @override
  Future<HomeEventItem> addEvent({
    required String userId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule = EventRepeatRule.none,
    String categoryName = 'Календарь',
    int categoryColorValue = 0xFF5AA9E6,
  }) async {
    final categoryId = await _ensureDefaultCategoryId();

    final schedule = _mapRepeatRule(repeatRule);
    final response = await _apiClient.dio.post(
      '/me/events',
      data: {
        'title': title.trim(),
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'scheduleType': schedule.scheduleType,
        'intervalDays': schedule.intervalDays,
        'weekdays': schedule.weekdays,
        'categoryId': categoryId,
        'taskId': null,
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      throw StateError('Некорректный формат созданного события.');
    }
    return _mapHomeEventItem(
      Map<String, dynamic>.from(raw),
      userId: _apiClient.currentUserId ?? userId,
    );
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    int categoryColorValue = 0xFF5AA9E6,
  }) async {
    await _apiClient.dio.patch(
      '/me/events/$eventId',
      data: {
        'title': title.trim(),
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> deleteEvent({
    required String eventId,
    required bool deleteFollowingInSeries,
  }) async {
    await _apiClient.dio.delete('/me/events/$eventId');
  }

  Future<List<HomeEventItem>> _fetchEventsForUser({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final isCurrent = _apiClient.isCurrentUser(userId);
    final response = isCurrent
        ? await _apiClient.dio.get(
            '/me/events',
            queryParameters: {
              'from': fromInclusive.toUtc().toIso8601String(),
              'to': toInclusive.toUtc().toIso8601String(),
            },
          )
        : await _apiClient.dio.get(
            '/users/$userId/events',
            queryParameters: {
              'from': fromInclusive.toUtc().toIso8601String(),
              'to': toInclusive.toUtc().toIso8601String(),
            },
          );

    final raw = response.data;
    if (raw is! List) {
      throw StateError('Некорректный формат списка событий.');
    }

    final effectiveUserId = _apiClient.currentUserId ?? userId;
    final items = raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (map) => _mapHomeEventItem(
            map,
            userId: isCurrent ? effectiveUserId : userId,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    return items;
  }

  HomeEventItem _mapHomeEventItem(
    Map<String, dynamic> map, {
    required String userId,
  }) {
    final categoryMap = Map<String, dynamic>.from(map['category'] as Map);
    final taskMapRaw = map['task'];
    String? taskId;
    if (taskMapRaw is Map) {
      taskId = taskMapRaw['id'] as String?;
    }

    final event = Event(
      id: map['id'] as String,
      title: map['title'] as String,
      startsAt: DateTime.parse(map['startsAt'] as String).toLocal(),
      endsAt: DateTime.parse(map['endsAt'] as String).toLocal(),
      userId: userId,
      taskId: taskId,
    );

    return HomeEventItem(
      event: event,
      categoryName: categoryMap['title'] as String? ?? 'Календарь',
      categoryColorValue: _parseHexColor(
        categoryMap['color'] as String? ?? '#5AA9E6',
      ),
    );
  }

  Future<List<HomeFeedItem>> _fetchFeedItems() async {
    final response = await _apiClient.dio.get(
      '/me/feed',
      queryParameters: {
        'limit': 20,
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      return const <HomeFeedItem>[];
    }

    final map = Map<String, dynamic>.from(raw);
    final itemsRaw = map['items'];
    if (itemsRaw is! List) {
      return const <HomeFeedItem>[];
    }

    return itemsRaw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((item) => _mapFeedItem(item))
        .toList(growable: false);
  }

  HomeFeedItem _mapFeedItem(Map<String, dynamic> map) {
    final actor = Map<String, dynamic>.from(map['actor'] as Map);
    final relatedHabitRaw = map['relatedHabit'];
    final relatedUserRaw = map['relatedUser'];
    final type = map['type'] as String? ?? '';

    final friendName = actor['handle'] as String? ?? 'Друг';
    final message = switch (type) {
      'friend_added' => 'добавил(а) нового друга',
      'habit_created' => 'создал(а) привычку',
      'habit_streak' => 'обновил(а) streak',
      'shared_habit_reminder' => 'отправил(а) напоминание',
      _ => 'есть новое действие',
    };

    final detail = () {
      if (relatedHabitRaw is Map) {
        final relatedHabit = Map<String, dynamic>.from(relatedHabitRaw);
        final title = relatedHabit['title'] as String? ?? '';
        if (title.isNotEmpty) {
          return ' - $title';
        }
      }
      if (relatedUserRaw is Map) {
        final relatedUser = Map<String, dynamic>.from(relatedUserRaw);
        final handle = relatedUser['handle'] as String? ?? '';
        if (handle.isNotEmpty) {
          return ' - @$handle';
        }
      }
      final streakValue = map['streakValue'] as int?;
      if (streakValue != null) {
        return ' - $streakValue';
      }
      return '';
    }();

    return HomeFeedItem(
      id: map['id'] as String,
      friendName: friendName,
      message: '$message$detail',
      kind: HomeFeedKind.streak,
      createdAt: DateTime.parse(map['createdAt'] as String).toLocal(),
    );
  }

  Future<String> _ensureDefaultCategoryId() async {
    final listResponse = await _apiClient.dio.get('/me/event-categories');
    final raw = listResponse.data;
    if (raw is List && raw.isNotEmpty) {
      final first = Map<String, dynamic>.from(raw.first as Map);
      return first['id'] as String;
    }

    final createResponse = await _apiClient.dio.post(
      '/me/event-categories',
      data: {
        'title': 'Календарь',
        'color': '#5AA9E6',
      },
    );
    final created = createResponse.data;
    if (created is! Map) {
      throw StateError('Не удалось создать категорию события.');
    }
    return created['id'] as String;
  }

  _ScheduleData _mapRepeatRule(EventRepeatRule rule) {
    if (rule.isNone) {
      return const _ScheduleData(
        scheduleType: 'none',
        intervalDays: 1,
        weekdays: <int>[],
      );
    }
    if (rule.unit == EventRepeatUnit.day) {
      return _ScheduleData(
        scheduleType: rule.interval == 1 ? 'daily' : 'interval',
        intervalDays: rule.interval,
        weekdays: const <int>[],
      );
    }
    if (rule.unit == EventRepeatUnit.week) {
      return _ScheduleData(
        scheduleType: 'interval',
        intervalDays: rule.interval * 7,
        weekdays: const <int>[],
      );
    }
    return _ScheduleData(
      scheduleType: 'monthly',
      intervalDays: rule.interval,
      weekdays: const <int>[],
    );
  }

  int _parseHexColor(String hex) {
    final normalized = hex.trim().replaceFirst('#', '');
    if (normalized.length == 6) {
      return int.parse('FF$normalized', radix: 16);
    }
    if (normalized.length == 8) {
      return int.parse(normalized, radix: 16);
    }
    return 0xFF5AA9E6;
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _ScheduleData {
  const _ScheduleData({
    required this.scheduleType,
    required this.intervalDays,
    required this.weekdays,
  });

  final String scheduleType;
  final int intervalDays;
  final List<int> weekdays;
}
