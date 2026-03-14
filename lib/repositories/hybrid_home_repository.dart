import '../models/home_data.dart';
import '../models/home_event_item.dart';
import '../models/task.dart';
import 'home_repository.dart';
import 'in_memory_app_store.dart';

class HybridHomeRepository implements HomeRepository {
  HybridHomeRepository({
    required HomeRepository remoteRepository,
    required InMemoryAppStore store,
  }) : _remoteRepository = remoteRepository,
       _store = store {
    _initialTaskStateById = {
      for (final task in _store.tasksForUser('user_me')) task.id: task.isCompleted,
    };

    _initialEventById = {
      for (final item in _store.events) item.event.id: item,
    };
  }

  final HomeRepository _remoteRepository;
  final InMemoryAppStore _store;

  late final Map<String, bool> _initialTaskStateById;
  late final Map<String, HomeEventItem> _initialEventById;
  final Map<String, String> _remoteToLocalTaskId = {};
  final Map<String, bool> _taskCompletionOverrideById = {};
  final Map<String, bool> _lastKnownTaskStateById = {};

  @override
  Future<HomeData> fetchHomeData({
    required String userId,
    DateTime? day,
  }) async {
    final remote = await _remoteRepository.fetchHomeData(
      userId: userId,
      day: day,
    );

    final selectedDay = _dayOnly(day ?? remote.day);

    final mergedTasks = _mergeTasksForDay(
      remoteTasks: remote.tasks,
      userId: userId,
      day: selectedDay,
    );

    final mergedEvents = _mergeEventsForDay(
      remoteEvents: remote.events,
      userId: userId,
      day: selectedDay,
    );

    return HomeData(
      day: selectedDay,
      tasks: mergedTasks,
      events: mergedEvents,
      feedItems: remote.feedItems,
    );
  }

  @override
  Future<void> toggleTask({
    required String taskId,
  }) async {
    final currentState = _lastKnownTaskStateById[taskId];
    final toggledState = currentState == null ? null : !currentState;

    try {
      await _remoteRepository.toggleTask(taskId: taskId);
    } catch (_) {
    }

    var toggledLocally = _store.toggleTaskById(taskId);
    var effectiveState = toggledState;

    if (!toggledLocally) {
      final mappedLocalTaskId = _remoteToLocalTaskId[taskId];
      if (mappedLocalTaskId != null) {
        toggledLocally = _store.toggleTaskById(mappedLocalTaskId);
        if (toggledLocally) {
          final localTask = _findLocalTaskById(mappedLocalTaskId);
          effectiveState = localTask?.isCompleted ?? toggledState;
        }
      }
    } else {
      final localTask = _findLocalTaskById(taskId);
      effectiveState = localTask?.isCompleted ?? toggledState;
    }

    if (effectiveState != null) {
      _taskCompletionOverrideById[taskId] = effectiveState;
      _lastKnownTaskStateById[taskId] = effectiveState;
    }
  }

  @override
  Future<List<HomeEventItem>> fetchEventsInRange({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final remote = await _remoteRepository.fetchEventsInRange(
      userId: userId,
      fromInclusive: fromInclusive,
      toInclusive: toInclusive,
    );

    final remoteById = {
      for (final item in remote) item.event.id: item,
    };

    final currentLocal = _store
        .eventsForUserInRange(
          userId: userId,
          fromInclusive: _dayOnly(fromInclusive),
          toExclusive: _dayOnly(toInclusive).add(const Duration(days: 1)),
        )
        .toList(growable: false);

    for (final item in currentLocal) {
      final id = item.event.id;
      final initial = _initialEventById[id];

      if (initial == null) {
        remoteById[id] = item;
        continue;
      }

      if (!_sameEventItem(initial, item)) {
        remoteById[id] = item;
      }
    }

    final currentIds = currentLocal.map((e) => e.event.id).toSet();
    for (final initialId in _initialEventById.keys) {
      if (!currentIds.contains(initialId)) {
        remoteById.remove(initialId);
      }
    }

    final merged = remoteById.values.toList(growable: false)
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    return merged;
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
    try {
      await _remoteRepository.updateEvent(
        eventId: eventId,
        title: title,
        startsAt: startsAt,
        endsAt: endsAt,
        categoryColorValue: categoryColorValue,
      );
    } catch (_) {
      // For demo we keep local update behavior even if backend fails.
    }

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

  List<Task> _mergeTasksForDay({
    required List<Task> remoteTasks,
    required String userId,
    required DateTime day,
  }) {
    final byId = <String, Task>{
      for (final task in remoteTasks)
        task.id: _taskCompletionOverrideById[task.id] == null
            ? task
            : task.copyWith(isCompleted: _taskCompletionOverrideById[task.id]!),
    };

    final remoteByMatchKey = {
      for (final task in remoteTasks) _taskMatchKey(task): task,
    };

    final currentLocalTasks = _store.tasksForUser(userId).where((task) {
      return _isSameDay(task.startsAt, day);
    });

    for (final task in currentLocalTasks) {
      final matchedRemoteTask = remoteByMatchKey[_taskMatchKey(task)];
      if (matchedRemoteTask != null && matchedRemoteTask.id != task.id) {
        _remoteToLocalTaskId[matchedRemoteTask.id] = task.id;
      }

      final initialCompleted = _initialTaskStateById[task.id];

      if (initialCompleted == null) {
        byId[task.id] = task;
        continue;
      }

      if (initialCompleted != task.isCompleted) {
        if (matchedRemoteTask != null) {
          byId[matchedRemoteTask.id] = matchedRemoteTask.copyWith(
            title: task.title,
            startsAt: task.startsAt,
            endsAt: task.endsAt,
            isCompleted: task.isCompleted,
          );
        } else {
          byId[task.id] = task;
        }
      }
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.startsAt.compareTo(b.startsAt);
        }
        return a.isCompleted ? 1 : -1;
      });

    for (final task in merged) {
      _lastKnownTaskStateById[task.id] = task.isCompleted;
    }

    return merged;
  }

  List<HomeEventItem> _mergeEventsForDay({
    required List<HomeEventItem> remoteEvents,
    required String userId,
    required DateTime day,
  }) {
    final byId = {
      for (final item in remoteEvents) item.event.id: item,
    };

    final currentLocalEvents = _store.events.where((item) {
      return item.event.userId == userId && _isSameDay(item.event.startsAt, day);
    });

    for (final item in currentLocalEvents) {
      final id = item.event.id;
      final initial = _initialEventById[id];

      if (initial == null) {
        byId[id] = item;
        continue;
      }

      if (!_sameEventItem(initial, item)) {
        byId[id] = item;
      }
    }

    final currentDayIds = currentLocalEvents.map((e) => e.event.id).toSet();
    for (final entry in _initialEventById.entries) {
      final initial = entry.value;
      if (_isSameDay(initial.event.startsAt, day) && !currentDayIds.contains(entry.key)) {
        byId.remove(entry.key);
      }
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) => a.event.startsAt.compareTo(b.event.startsAt));

    return merged;
  }

  bool _sameEventItem(HomeEventItem a, HomeEventItem b) {
    return a.event.id == b.event.id &&
        a.event.title == b.event.title &&
        a.event.startsAt == b.event.startsAt &&
        a.event.endsAt == b.event.endsAt &&
        a.event.userId == b.event.userId &&
        a.event.taskId == b.event.taskId &&
        a.categoryName == b.categoryName &&
        a.categoryColorValue == b.categoryColorValue;
  }

  String _taskMatchKey(Task task) {
    final normalizedTitle = task.title.trim().toLowerCase();
    return '$normalizedTitle|${task.startsAt.hour}:${task.startsAt.minute}|${task.endsAt.hour}:${task.endsAt.minute}';
  }

  Task? _findLocalTaskById(String taskId) {
    for (final tasks in _store.tasksByHabit.values) {
      for (final task in tasks) {
        if (task.id == taskId) {
          return task;
        }
      }
    }
    return null;
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
