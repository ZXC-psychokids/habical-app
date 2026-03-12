import '../models/event.dart';
import '../models/home_data.dart';
import '../models/home_event_item.dart';
import '../models/home_feed_item.dart';
import '../models/task.dart';

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
  InMemoryHomeRepository({DateTime? now}) : _now = now ?? DateTime.now() {
    _seedData();
  }

  final DateTime _now;

  late List<Task> _tasks;
  late List<HomeEventItem> _events;
  late List<HomeFeedItem> _feedItems;

  @override
  Future<HomeData> fetchHomeData({
    required String userId,
    DateTime? day,
  }) async {
    final selectedDay = _dayOnly(day ?? _now);

    final tasksForDay = _tasks.where((task) {
      return _isSameDay(task.startsAt, selectedDay);
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.startsAt.compareTo(b.startsAt);
        }
        return a.isCompleted ? 1 : -1;
      });

    final eventsForDay = _events.where((item) {
      return _isSameDay(item.event.startsAt, selectedDay);
    }).toList()
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    final sortedFeed = [..._feedItems]
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
    _tasks = _tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }
      return task.copyWith(isCompleted: !task.isCompleted);
    }).toList(growable: false);
  }

  void _seedData() {
    final today = _dayOnly(_now);

    _tasks = [
      Task(
        id: 'task_1',
        title: 'Отжимания',
        startsAt: today.add(const Duration(hours: 8)),
        endsAt: today.add(const Duration(hours: 9)),
        isCompleted: true,
      ),
      Task(
        id: 'task_2',
        title: 'Холодный душ',
        startsAt: today.add(const Duration(hours: 9)),
        endsAt: today.add(const Duration(hours: 10)),
        isCompleted: false,
      ),
      Task(
        id: 'task_3',
        title: 'Чтение',
        startsAt: today.add(const Duration(hours: 20)),
        endsAt: today.add(const Duration(hours: 21)),
        isCompleted: false,
      ),
    ];

    _events = [
      HomeEventItem(
        event: Event(
          id: 'event_1',
          title: 'Тренировка',
          startsAt: today.add(const Duration(hours: 8)),
          endsAt: today.add(const Duration(hours: 9)),
          userId: 'user_me',
          taskId: 'task_1',
        ),
        categoryName: 'Спорт',
        categoryColorValue: 0xFF4CAF50,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_2',
          title: 'Диетолог',
          startsAt: today.add(const Duration(hours: 10)),
          endsAt: today.add(const Duration(hours: 11)),
          userId: 'user_me',
        ),
        categoryName: 'Здоровье',
        categoryColorValue: 0xFF42A5F5,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_3',
          title: 'Пара по ML',
          startsAt: today.add(const Duration(hours: 11, minutes: 10)),
          endsAt: today.add(const Duration(hours: 12, minutes: 25)),
          userId: 'user_me',
        ),
        categoryName: 'Учёба',
        categoryColorValue: 0xFFF44336,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_4',
          title: 'Чтение',
          startsAt: today.add(const Duration(hours: 20)),
          endsAt: today.add(const Duration(hours: 21)),
          userId: 'user_me',
          taskId: 'task_3',
        ),
        categoryName: 'Саморазвитие',
        categoryColorValue: 0xFFFF9800,
      ),
    ];

    _feedItems = [
      HomeFeedItem(
        id: 'feed_1',
        friendName: 'Кирилл',
        message: 'выполняет “Отжимания” уже 10 дней подряд!',
        kind: HomeFeedKind.streak,
        createdAt: _now.subtract(const Duration(hours: 1)),
      ),
      HomeFeedItem(
        id: 'feed_2',
        friendName: 'Кирилл',
        message: 'начал привычку “Холодный душ”.',
        kind: HomeFeedKind.startedHabit,
        createdAt: _now.subtract(const Duration(hours: 3)),
      ),
      HomeFeedItem(
        id: 'feed_3',
        friendName: 'Аня',
        message: 'выбила стрик 30 дней в “Чтении”.',
        kind: HomeFeedKind.achievement,
        createdAt: _now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}