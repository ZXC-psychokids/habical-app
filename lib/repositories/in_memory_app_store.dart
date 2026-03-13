import '../models/event.dart';
import '../models/habit.dart';
import '../models/home_event_item.dart';
import '../models/home_feed_item.dart';
import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import '../models/task.dart';
import '../services/streak_service.dart';

class InMemoryAppStore {
  InMemoryAppStore({DateTime? now}) : now = now ?? DateTime.now() {
    _seedData();
  }

  final DateTime now;

  late List<Habit> habits;
  late Map<String, List<Task>> tasksByHabit;
  late List<HomeEventItem> events;
  late List<HomeFeedItem> feedItems;
  late Map<String, List<FriendListItem>> friendsByUser;
  late Map<String, List<FriendInviteItem>> incomingInvitesByUser;
  int nextHabitId = 1;
  int nextFriendId = 1;
  final StreakService _streakService = const StreakService();

  Iterable<Task> tasksForUser(String userId) sync* {
    for (final habit in habits) {
      if (habit.userId != userId) {
        continue;
      }
      yield* tasksByHabit[habit.id] ?? const <Task>[];
    }
  }

  Iterable<FriendListItem> friendsForUser(String userId) sync* {
    final items = friendsByUser[userId] ?? const <FriendListItem>[];
    final connected = items.where((item) => item.isConnected).map((item) {
      if (!item.hasSharedHabit) {
        return item.copyWith(streakDays: 0);
      }

      Habit? sharedHabit;
      for (final habit in habits) {
        if (habit.userId == userId && habit.sharedWithName == item.name) {
          sharedHabit = habit;
          break;
        }
      }

      if (sharedHabit == null) {
        return item.copyWith(streakDays: 0);
      }

      final tasks = tasksByHabit[sharedHabit.id] ?? const <Task>[];
      final completionDates = tasks
          .where((task) => task.isCompleted)
          .map((task) => task.startsAt)
          .toList(growable: false);

      final streakDays = _streakService.calculateStreakDays(
        periodicityDays: sharedHabit.periodicityDays,
        completionDates: completionDates,
        asOf: DateTime.now(),
        seedDays: sharedHabit.initialStreakDays,
      );

      return item.copyWith(
        streakDays: streakDays,
        sharedHabitTitle: sharedHabit.title,
      );
    });
    final suggestions = items.where((item) => !item.isConnected);
    yield* connected;
    yield* suggestions;
  }

  Iterable<FriendInviteItem> incomingInvitesForUser(String userId) sync* {
    yield* incomingInvitesByUser[userId] ?? const <FriendInviteItem>[];
  }

  bool connectFriend({required String userId, required String friendId}) {
    final items = friendsByUser[userId];
    if (items == null) {
      return false;
    }

    var changed = false;
    final updated = items
        .map((item) {
          if (item.id != friendId || item.isConnected) {
            return item;
          }
          changed = true;
          return item.copyWith(
            status: FriendRelationStatus.connected,
            streakDays: 0,
            clearSharedHabit: true,
          );
        })
        .toList(growable: false);

    if (!changed) {
      return false;
    }

    friendsByUser = {...friendsByUser, userId: updated};
    final friend = updated.firstWhere((item) => item.id == friendId);
    _prependFriendFeed(
      friendName: friend.name,
      message: 'теперь у вас в друзьях.',
    );
    return true;
  }

  void sendInviteByEmail({required String userId, required String email}) {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_isLikelyEmail(normalizedEmail)) {
      throw ArgumentError('Некорректный email.');
    }

    // Backend is not connected yet: we only validate and pretend to send.
    if (userId.isEmpty) {
      throw ArgumentError('Пользователь не найден.');
    }
  }

  void acceptInvite({required String userId, required String inviteId}) {
    final invites = incomingInvitesByUser[userId];
    if (invites == null) {
      throw StateError('Список заявок не найден.');
    }

    FriendInviteItem? acceptedInvite;
    final updatedInvites = <FriendInviteItem>[];
    for (final invite in invites) {
      if (invite.id == inviteId) {
        acceptedInvite = invite;
      } else {
        updatedInvites.add(invite);
      }
    }

    if (acceptedInvite == null) {
      throw StateError('Заявка не найдена.');
    }

    incomingInvitesByUser = {...incomingInvitesByUser, userId: updatedInvites};

    final currentFriends = friendsByUser[userId] ?? const <FriendListItem>[];
    final alreadyExists = currentFriends.any(
      (friend) => friend.name == acceptedInvite!.fromName,
    );
    if (!alreadyExists) {
      final friend = FriendListItem(
        id: 'friend_${nextFriendId++}',
        userId: acceptedInvite.fromUserId,
        name: acceptedInvite.fromName,
        status: FriendRelationStatus.connected,
        streakDays: 0,
        sharedHabitTitle: null,
      );
      friendsByUser = {
        ...friendsByUser,
        userId: [friend, ...currentFriends],
      };
    }

    _prependFriendFeed(
      friendName: acceptedInvite.fromName,
      message: 'теперь у вас в друзьях.',
      kind: HomeFeedKind.achievement,
    );
  }

  void createSharedHabit({
    required String userId,
    required String friendId,
    required String title,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Название совместной привычки не может быть пустым.');
    }

    final items = friendsByUser[userId];
    if (items == null) {
      throw StateError('Пользователь не найден.');
    }

    var changed = false;
    final updated = items
        .map((item) {
          if (item.id != friendId) {
            return item;
          }
          if (!item.isConnected) {
            throw StateError('Сначала добавьте пользователя в друзья.');
          }
          changed = true;
          return item.copyWith(
            sharedHabitTitle: normalizedTitle,
            streakDays: 0,
          );
        })
        .toList(growable: false);

    if (!changed) {
      throw StateError('Друг не найден.');
    }

    friendsByUser = {...friendsByUser, userId: updated};
    final friend = updated.firstWhere((item) => item.id == friendId);
    _upsertSharedHabitForFriend(
      userId: userId,
      friendName: friend.name,
      title: normalizedTitle,
    );
    _upsertSharedHabitForFriend(
      userId: friend.userId,
      friendName: _labelForUser(userId),
      title: normalizedTitle,
    );
    _prependFriendFeed(
      friendName: friend.name,
      message: 'начал(а) совместную привычку «$normalizedTitle».',
      kind: HomeFeedKind.startedHabit,
    );
  }

  bool toggleTaskById(String taskId) {
    var toggled = false;
    final updated = <String, List<Task>>{};

    for (final entry in tasksByHabit.entries) {
      final list = entry.value;
      updated[entry.key] = list
          .map((task) {
            if (task.id != taskId) {
              return task;
            }
            toggled = true;
            return task.copyWith(isCompleted: !task.isCompleted);
          })
          .toList(growable: false);
    }

    if (toggled) {
      tasksByHabit = updated;
    }
    return toggled;
  }

  List<Task> generateTasksForPeriod({
    required Habit habit,
    required DateTime startDay,
    required int days,
    Set<DateTime> completedDays = const <DateTime>{},
  }) {
    final normalizedCompletedDays = completedDays.map(_dayOnly).toSet();
    final tasks = <Task>[];
    final step = habit.periodicityDays <= 0 ? 1 : habit.periodicityDays;

    for (var offset = 0; offset < days; offset += step) {
      final day = startDay.add(Duration(days: offset));
      final start = day.add(const Duration(hours: 9));
      final end = start.add(const Duration(hours: 1));
      final isCompleted = normalizedCompletedDays.contains(_dayOnly(day));

      tasks.add(
        Task(
          id: 'task_${habit.id}_$offset',
          startsAt: start,
          endsAt: end,
          title: habit.title,
          isCompleted: isCompleted,
        ),
      );
    }

    return tasks;
  }

  void _seedData() {
    final today = _dayOnly(now);
    final startDay = today.subtract(const Duration(days: 12));

    habits = const [
      Habit(
        id: 'habit_1',
        title: 'Отжимания',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_me',
      ),
      Habit(
        id: 'habit_2',
        title: 'Холодный душ',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_me',
      ),
      Habit(
        id: 'habit_3',
        title: 'Чтение',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_me',
      ),
    ];

    habits = [
      ...habits,
      const Habit(
        id: 'habit_4',
        title: 'Отжимания',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_kirill',
      ),
      const Habit(
        id: 'habit_5',
        title: 'Холодный душ',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_kirill',
      ),
      const Habit(
        id: 'habit_6',
        title: 'Утренняя пробежка',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_liza',
      ),
      const Habit(
        id: 'habit_7',
        title: 'Чтение',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_anya',
      ),
      const Habit(
        id: 'habit_8',
        title: 'Футбол',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_kirill',
        sharedWithName: 'Вы',
      ),
      const Habit(
        id: 'habit_9',
        title: 'Сон 8 часов',
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: 'user_anya',
        sharedWithName: 'Вы',
      ),
    ];

    tasksByHabit = {
      'habit_1': generateTasksForPeriod(
        habit: habits[0],
        startDay: startDay,
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
        },
      ),
      'habit_2': generateTasksForPeriod(
        habit: habits[1],
        startDay: startDay,
        days: 42,
        completedDays: {
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 3)),
          today.subtract(const Duration(days: 5)),
        },
      ),
      'habit_3': generateTasksForPeriod(
        habit: habits[2],
        startDay: startDay,
        days: 42,
        completedDays: {today.subtract(const Duration(days: 1))},
      ),
      'habit_4': generateTasksForPeriod(
        habit: habits[3],
        startDay: startDay,
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
          today.subtract(const Duration(days: 4)),
          today.subtract(const Duration(days: 5)),
          today.subtract(const Duration(days: 6)),
          today.subtract(const Duration(days: 7)),
          today.subtract(const Duration(days: 8)),
          today.subtract(const Duration(days: 9)),
        },
      ),
      'habit_5': generateTasksForPeriod(
        habit: habits[4],
        startDay: startDay,
        days: 42,
        completedDays: {today.subtract(const Duration(days: 1))},
      ),
      'habit_6': generateTasksForPeriod(
        habit: habits[5],
        startDay: startDay,
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
        },
      ),
      'habit_7': generateTasksForPeriod(
        habit: habits[6],
        startDay: startDay,
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
          today.subtract(const Duration(days: 4)),
          today.subtract(const Duration(days: 5)),
          today.subtract(const Duration(days: 6)),
          today.subtract(const Duration(days: 7)),
          today.subtract(const Duration(days: 8)),
          today.subtract(const Duration(days: 9)),
          today.subtract(const Duration(days: 10)),
          today.subtract(const Duration(days: 11)),
          today.subtract(const Duration(days: 12)),
          today.subtract(const Duration(days: 13)),
          today.subtract(const Duration(days: 14)),
          today.subtract(const Duration(days: 15)),
          today.subtract(const Duration(days: 16)),
          today.subtract(const Duration(days: 17)),
          today.subtract(const Duration(days: 18)),
          today.subtract(const Duration(days: 19)),
          today.subtract(const Duration(days: 20)),
          today.subtract(const Duration(days: 21)),
          today.subtract(const Duration(days: 22)),
          today.subtract(const Duration(days: 23)),
          today.subtract(const Duration(days: 24)),
          today.subtract(const Duration(days: 25)),
          today.subtract(const Duration(days: 26)),
          today.subtract(const Duration(days: 27)),
          today.subtract(const Duration(days: 28)),
          today.subtract(const Duration(days: 29)),
        },
      ),
      'habit_8': generateTasksForPeriod(
        habit: habits[7],
        startDay: startDay,
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 3)),
        },
      ),
      'habit_9': generateTasksForPeriod(
        habit: habits[8],
        startDay: startDay,
        days: 42,
        completedDays: {
          today,
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 2)),
        },
      ),
    };

    final habit1TaskTodayId = _taskIdForDay(habitId: 'habit_1', day: today);
    final habit3TaskTodayId = _taskIdForDay(habitId: 'habit_3', day: today);
    final habit4TaskTodayId = _taskIdForDay(habitId: 'habit_4', day: today);
    final habit5TaskTodayId = _taskIdForDay(habitId: 'habit_5', day: today);
    final habit6TaskTodayId = _taskIdForDay(habitId: 'habit_6', day: today);
    final habit7TaskTodayId = _taskIdForDay(habitId: 'habit_7', day: today);
    final habit8TaskTodayId = _taskIdForDay(habitId: 'habit_8', day: today);
    final habit9TaskTodayId = _taskIdForDay(habitId: 'habit_9', day: today);

    events = [
      HomeEventItem(
        event: Event(
          id: 'event_1',
          title: 'Тренировка',
          startsAt: today.add(const Duration(hours: 8)),
          endsAt: today.add(const Duration(hours: 9)),
          userId: 'user_me',
          taskId: habit1TaskTodayId,
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
          taskId: habit3TaskTodayId,
        ),
        categoryName: 'Саморазвитие',
        categoryColorValue: 0xFFFF9800,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_5',
          title: 'Тренировка по боксу',
          startsAt: today.add(const Duration(hours: 7)),
          endsAt: today.add(const Duration(hours: 8)),
          userId: 'user_kirill',
          taskId: habit4TaskTodayId,
        ),
        categoryName: 'Спорт',
        categoryColorValue: 0xFF4CAF50,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_6',
          title: 'Встреча с куратором',
          startsAt: today.add(const Duration(hours: 9)),
          endsAt: today.add(const Duration(hours: 10)),
          userId: 'user_kirill',
          taskId: habit5TaskTodayId,
        ),
        categoryName: 'Учёба',
        categoryColorValue: 0xFF42A5F5,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_7',
          title: 'Йога',
          startsAt: today.add(const Duration(hours: 20)),
          endsAt: today.add(const Duration(hours: 21)),
          userId: 'user_anya',
          taskId: habit7TaskTodayId,
        ),
        categoryName: 'Здоровье',
        categoryColorValue: 0xFFF44336,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_8',
          title: 'Занятие английским',
          startsAt: today.add(const Duration(hours: 7)),
          endsAt: today.add(const Duration(hours: 8)),
          userId: 'user_liza',
          taskId: habit6TaskTodayId,
        ),
        categoryName: 'Учёба',
        categoryColorValue: 0xFF42A5F5,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_9',
          title: 'Рабочий звонок',
          startsAt: today.add(const Duration(hours: 18)),
          endsAt: today.add(const Duration(hours: 19)),
          userId: 'user_kirill',
          taskId: habit8TaskTodayId,
        ),
        categoryName: 'Работа',
        categoryColorValue: 0xFFFF9800,
      ),
      HomeEventItem(
        event: Event(
          id: 'event_10',
          title: 'Консультация',
          startsAt: today.add(const Duration(hours: 22)),
          endsAt: today.add(const Duration(hours: 23)),
          userId: 'user_anya',
          taskId: habit9TaskTodayId,
        ),
        categoryName: 'Учёба',
        categoryColorValue: 0xFF42A5F5,
      ),
    ];

    friendsByUser = {
      'user_me': const [
        FriendListItem(
          id: 'friend_1',
          userId: 'user_kirill',
          name: 'Кирилл',
          status: FriendRelationStatus.connected,
          streakDays: 0,
          sharedHabitTitle: 'Футбол',
        ),
        FriendListItem(
          id: 'friend_2',
          userId: 'user_liza',
          name: 'Лиза',
          status: FriendRelationStatus.connected,
          streakDays: 0,
          sharedHabitTitle: null,
        ),
        FriendListItem(
          id: 'friend_3',
          userId: 'user_anya',
          name: 'Аня',
          status: FriendRelationStatus.connected,
          streakDays: 0,
          sharedHabitTitle: 'Сон 8 часов',
        ),
      ],
    };
    nextHabitId = habits.length + 1;
    _upsertSharedHabitForFriend(
      userId: 'user_me',
      friendName: 'Кирилл',
      title: 'Футбол',
    );
    _upsertSharedHabitForFriend(
      userId: 'user_me',
      friendName: 'Аня',
      title: 'Сон 8 часов',
    );

    incomingInvitesByUser = {
      'user_me': [
        FriendInviteItem(
          id: 'invite_1',
          fromUserId: 'user_bulat',
          fromName: 'Булат',
          fromEmail: 'bulat@example.com',
          sentAt: now.subtract(const Duration(hours: 2)),
        ),
      ],
    };

    feedItems = [
      HomeFeedItem(
        id: 'feed_1',
        friendName: 'Кирилл',
        message: 'выполняет «Отжимания» уже 10 дней подряд!',
        kind: HomeFeedKind.streak,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      HomeFeedItem(
        id: 'feed_2',
        friendName: 'Кирилл',
        message: 'начал привычку «Холодный душ».',
        kind: HomeFeedKind.startedHabit,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      HomeFeedItem(
        id: 'feed_3',
        friendName: 'Аня',
        message: 'выбила стрик 30 дней в «Чтении».',
        kind: HomeFeedKind.achievement,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];

    nextHabitId = habits.length + 1;
    nextFriendId = 4;
  }

  void _upsertSharedHabitForFriend({
    required String userId,
    required String friendName,
    required String title,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      return;
    }

    Habit? existing;
    for (final habit in habits) {
      if (habit.userId == userId && habit.sharedWithName == friendName) {
        existing = habit;
        break;
      }
    }

    if (existing == null) {
      final habit = Habit(
        id: 'habit_${nextHabitId++}',
        title: normalizedTitle,
        periodicityDays: 1,
        initialStreakDays: 0,
        userId: userId,
        sharedWithName: friendName,
      );

      habits = [...habits, habit];
      tasksByHabit[habit.id] = generateTasksForPeriod(
        habit: habit,
        startDay: _dayOnly(now),
        days: 30,
      );
      return;
    }

    final existingHabit = existing;

    habits = habits
        .map((habit) {
          if (habit.id != existingHabit.id) {
            return habit;
          }
          return habit.copyWith(
            title: normalizedTitle,
            sharedWithName: friendName,
          );
        })
        .toList(growable: false);

    tasksByHabit.putIfAbsent(
      existingHabit.id,
      () => generateTasksForPeriod(
        habit: existingHabit,
        startDay: _dayOnly(now),
        days: 30,
      ),
    );
  }

  void _prependFriendFeed({
    required String friendName,
    required String message,
    HomeFeedKind kind = HomeFeedKind.achievement,
  }) {
    final item = HomeFeedItem(
      id: 'feed_friend_${now.microsecondsSinceEpoch}_${feedItems.length}',
      friendName: friendName,
      message: message,
      kind: kind,
      createdAt: DateTime.now(),
    );

    feedItems = [item, ...feedItems];
  }

  String? _taskIdForDay({required String habitId, required DateTime day}) {
    final tasks = tasksByHabit[habitId];
    if (tasks == null) {
      return null;
    }

    final targetDay = _dayOnly(day);
    for (final task in tasks) {
      if (_isSameDay(task.startsAt, targetDay)) {
        return task.id;
      }
    }
    return null;
  }

  String _labelForUser(String userId) {
    if (userId == 'user_me') {
      return 'Вы';
    }

    for (final list in friendsByUser.values) {
      for (final item in list) {
        if (item.userId == userId) {
          return item.name;
        }
      }
    }

    return 'Друг';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isLikelyEmail(String value) {
    final atIndex = value.indexOf('@');
    if (atIndex <= 0 || atIndex != value.lastIndexOf('@')) {
      return false;
    }
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex <= atIndex + 1 || dotIndex == value.length - 1) {
      return false;
    }
    return true;
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
