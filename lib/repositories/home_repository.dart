import '../models/home_data.dart';
import 'in_memory_app_store.dart';

abstract class HomeRepository {
  Future<HomeData> fetchHomeData({
    required String userId,
    DateTime? day,
  });

  Future<void> toggleTask({
    required String taskId,
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

    final tasksForDay = _store.tasksForUser(userId).where((task) {
      return _isSameDay(task.startsAt, selectedDay);
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.startsAt.compareTo(b.startsAt);
        }
        return a.isCompleted ? 1 : -1;
      });

    final eventsForDay = _store.events.where((item) {
      return item.event.userId == userId &&
          _isSameDay(item.event.startsAt, selectedDay);
    }).toList()
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

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
  Future<void> toggleTask({
    required String taskId,
  }) async {
    _store.toggleTaskById(taskId);
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
