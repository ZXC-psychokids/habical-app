import '../models/home_data.dart';
import '../models/home_event_item.dart';
import 'in_memory_app_store.dart';

enum EventRepeatUnit { none, day, week, month }

class EventRepeatRule {
  const EventRepeatRule({this.unit = EventRepeatUnit.none, this.interval = 1})
    : assert(interval > 0);

  static const none = EventRepeatRule();

  final EventRepeatUnit unit;
  final int interval;

  bool get isNone => unit == EventRepeatUnit.none;
}

abstract class HomeRepository {
  Future<HomeData> fetchHomeData({required String userId, DateTime? day});

  Future<void> toggleTask({required String taskId});

  Future<List<HomeEventItem>> fetchEventsInRange({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  });

  Future<HomeEventItem> addEvent({
    required String userId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule,
    String categoryName,
    int categoryColorValue,
  });

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    int categoryColorValue,
  });

  Future<void> deleteEvent({
    required String eventId,
    required bool deleteFollowingInSeries,
  });
}

class InMemoryHomeRepository implements HomeRepository {
  InMemoryHomeRepository({DateTime? now, InMemoryAppStore? store})
    : _store = store ?? InMemoryAppStore(now: now);

  final InMemoryAppStore _store;

  @override
  Future<HomeData> fetchHomeData({
    required String userId,
    DateTime? day,
  }) async {
    final selectedDay = _dayOnly(day ?? _store.now);

    final tasksForDay =
        _store.tasksForUser(userId).where((task) {
          return _isSameDay(task.startsAt, selectedDay);
        }).toList()..sort((a, b) {
          if (a.isCompleted == b.isCompleted) {
            return a.startsAt.compareTo(b.startsAt);
          }
          return a.isCompleted ? 1 : -1;
        });

    final eventsForDay = _store.events.where((item) {
      return item.event.userId == userId &&
          _isSameDay(item.event.startsAt, selectedDay);
    }).toList()..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    final sortedFeed = [..._store.feedItems]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return HomeData(
      day: selectedDay,
      tasks: tasksForDay,
      events: eventsForDay,
      feedItems: sortedFeed,
    );
  }

  @override
  Future<void> toggleTask({required String taskId}) async {
    _store.toggleTaskById(taskId);
  }

  @override
  Future<List<HomeEventItem>> fetchEventsInRange({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final from = _dayOnly(fromInclusive);
    final toExclusive = _dayOnly(toInclusive).add(const Duration(days: 1));
    return _store
        .eventsForUserInRange(
          userId: userId,
          fromInclusive: from,
          toExclusive: toExclusive,
        )
        .toList(growable: false)
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));
  }

  @override
  Future<HomeEventItem> addEvent({
    required String userId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule = EventRepeatRule.none,
    String categoryName =
        '\u041a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044c',
    int categoryColorValue = 0xFF5AA9E6,
  }) async {
    return _store.addEvent(
      userId: userId,
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      repeatUnitKey: _repeatUnitKey(repeatRule.unit),
      repeatInterval: repeatRule.interval,
      categoryName: categoryName,
      categoryColorValue: categoryColorValue,
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
    _store.updateEvent(
      eventId: eventId,
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      categoryColorValue: categoryColorValue,
    );
  }

  @override
  Future<void> deleteEvent({
    required String eventId,
    required bool deleteFollowingInSeries,
  }) async {
    _store.deleteEvent(
      eventId: eventId,
      deleteFollowingInSeries: deleteFollowingInSeries,
    );
  }

  String _repeatUnitKey(EventRepeatUnit unit) {
    return switch (unit) {
      EventRepeatUnit.none => 'none',
      EventRepeatUnit.day => 'day',
      EventRepeatUnit.week => 'week',
      EventRepeatUnit.month => 'month',
    };
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
