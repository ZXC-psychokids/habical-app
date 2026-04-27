import '../models/home_data.dart';
import '../models/home_day_event_item.dart';
import '../models/home_feed_entry.dart';
import '../models/home_task_item.dart';
import 'in_memory_app_store.dart';

class HomeTaskUpdateInput {
  const HomeTaskUpdateInput({
    this.title,
    this.taskDate,
    this.position,
    this.manualColor,
    this.clearManualColor = false,
  });

  final String? title;
  final DateTime? taskDate;
  final int? position;
  final String? manualColor;
  final bool clearManualColor;

  bool get hasChanges {
    return title != null ||
        taskDate != null ||
        position != null ||
        manualColor != null ||
        clearManualColor;
  }
}

class HomeTaskReorderItem {
  const HomeTaskReorderItem({
    required this.taskId,
    required this.position,
    required this.taskDate,
  });

  final String taskId;
  final int position;
  final DateTime taskDate;
}

abstract class HomeRepository {
  Future<HomeData> fetchHomeData({required DateTime day});

  Future<void> toggleTask({required String taskId});

  Future<HomeTaskItem> createTask({
    required String title,
    required DateTime taskDate,
    required int position,
    String? manualColor,
  });

  Future<HomeTaskItem> updateTask({
    required String taskId,
    required HomeTaskUpdateInput input,
  });

  Future<void> deleteTask({required String taskId});

  Future<void> reorderTasks({required List<HomeTaskReorderItem> items});

  Future<HomeTaskItem> linkTaskToEvent({
    required String taskId,
    required String eventId,
  });

  Future<void> unlinkTaskFromEvent({required String taskId});
}

class InMemoryHomeRepository implements HomeRepository {
  InMemoryHomeRepository({DateTime? now, InMemoryAppStore? store})
    : _store = store ?? InMemoryAppStore(now: now);

  final InMemoryAppStore _store;

  @override
  Future<HomeData> fetchHomeData({required DateTime day}) async {
    final selectedDay = DateTime(day.year, day.month, day.day);

    final tasks = _store
        .tasksForUser('user_me')
        .where((task) => _isSameDay(task.startsAt, selectedDay))
        .map(
          (task) => HomeTaskItem(
            id: task.id,
            title: task.title,
            taskDate: selectedDay,
            position: task.startsAt.hour * 60 + task.startsAt.minute,
            isCompleted: task.isCompleted,
          ),
        )
        .toList(growable: false);

    final events = _store
        .eventsForUserInRange(
          userId: 'user_me',
          fromInclusive: selectedDay,
          toExclusive: selectedDay.add(const Duration(days: 1)),
        )
        .map(
          (item) => HomeDayEventItem(
            id: item.event.id,
            title: item.event.title,
            startsAt: item.event.startsAt,
            endsAt: item.event.endsAt,
            categoryId: item.categoryName,
            categoryName: item.categoryName,
            categoryColor: _argbToHex(item.categoryColorValue),
          ),
        )
        .toList(growable: false);

    final feedEntries = _store.feedItems
        .map(
          (item) => HomeFeedEntry(
            id: item.id,
            type: HomeFeedType.habitCreated,
            actor: HomeFeedUserRef(
              id: item.id,
              handle: item.friendName,
              avatarUrl: 'https://example.com/avatar.png',
            ),
            createdAt: item.createdAt,
          ),
        )
        .toList(growable: false);

    return HomeData(
      day: selectedDay,
      tasks: tasks,
      events: events,
      feedEntries: feedEntries,
    );
  }

  @override
  Future<void> toggleTask({required String taskId}) async {
    _store.toggleTaskById(taskId);
  }

  @override
  Future<HomeTaskItem> createTask({
    required String title,
    required DateTime taskDate,
    required int position,
    String? manualColor,
  }) async {
    final item = HomeTaskItem(
      id: 'local_task_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      taskDate: DateTime(taskDate.year, taskDate.month, taskDate.day),
      position: position,
      isCompleted: false,
      manualColor: manualColor,
    );
    return item;
  }

  @override
  Future<HomeTaskItem> updateTask({
    required String taskId,
    required HomeTaskUpdateInput input,
  }) async {
    return HomeTaskItem(
      id: taskId,
      title: input.title ?? 'Task',
      taskDate: input.taskDate ?? DateTime.now(),
      position: input.position ?? 0,
      isCompleted: false,
      manualColor: input.manualColor,
    );
  }

  @override
  Future<void> deleteTask({required String taskId}) async {}

  @override
  Future<void> reorderTasks({required List<HomeTaskReorderItem> items}) async {}

  @override
  Future<HomeTaskItem> linkTaskToEvent({
    required String taskId,
    required String eventId,
  }) async {
    return HomeTaskItem(
      id: taskId,
      title: 'Task',
      taskDate: DateTime.now(),
      position: 0,
      isCompleted: false,
      event: HomeTaskEventRef(
        id: eventId,
        startsAt: DateTime.now(),
        endsAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<void> unlinkTaskFromEvent({required String taskId}) async {}

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _argbToHex(int value) {
    final rgb = value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
