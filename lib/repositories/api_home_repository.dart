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

    final results = await Future.wait([
      _apiClient.dio.get(
        '/users/$userId/tasks/by-period',
        queryParameters: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      ),
      _apiClient.dio.get(
        '/users/$userId/events/by-period',
        queryParameters: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      ),
      _apiClient.dio.get('/users/$userId/news'),
    ]);

    final taskRaw = results[0].data;
    final eventRaw = results[1].data;
    final newsRaw = results[2].data;

    if (taskRaw is! List) {
      throw StateError('Некорректный формат списка задач.');
    }
    if (eventRaw is! List) {
      throw StateError('Некорректный формат списка событий.');
    }
    if (newsRaw is! List) {
      throw StateError('Некорректный формат списка новостей.');
    }

    final tasks = taskRaw
        .map((item) => Task.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false)
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.startsAt.compareTo(b.startsAt);
        }
        return a.isCompleted ? 1 : -1;
      });

    final events = eventRaw
        .map((item) => Event.fromMap(Map<String, dynamic>.from(item as Map)))
        .map(
          (event) => HomeEventItem(
            event: event,
            categoryName: 'Календарь',
            categoryColorValue: 0xFF5AA9E6,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    final feedItems = newsRaw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (map) => HomeFeedItem(
            id: map['id'] as String,
            friendName: '',
            message: (map['text'] as String).trim(),
            kind: HomeFeedKind.streak,
            createdAt: DateTime.now(),
          ),
        )
        .toList(growable: false);

    return HomeData(
      day: selectedDay,
      tasks: tasks,
      events: events,
      feedItems: feedItems,
    );
  }

  @override
  Future<void> toggleTask({
    required String taskId,
  }) async {
    await _apiClient.dio.post('/tasks/$taskId/complete');
  }

  @override
  Future<List<HomeEventItem>> fetchEventsInRange({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final response = await _apiClient.dio.get(
      '/users/$userId/events/by-period',
      queryParameters: {
        'from': fromInclusive.toUtc().toIso8601String(),
        'to': toInclusive.toUtc().toIso8601String(),
      },
    );

    final raw = response.data;
    if (raw is! List) {
      throw StateError('Некорректный формат списка событий.');
    }

    final items = raw
        .map((item) => Event.fromMap(Map<String, dynamic>.from(item as Map)))
        .map(
          (event) => HomeEventItem(
            event: event,
            categoryName: 'Календарь',
            categoryColorValue: 0xFF5AA9E6,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    return items;
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
    throw UnimplementedError(
      'Создание событий пока остаётся локальным в гибридном репозитории.',
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
      '/events/$eventId',
      data: {
        'title': title,
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
    throw UnimplementedError(
      'Удаление событий пока остаётся локальным в гибридном репозитории.',
    );
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}