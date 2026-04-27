enum HomeFeedType {
  friendAdded,
  habitStreak,
  habitCreated,
  sharedHabitReminder,
}

class HomeFeedUserRef {
  const HomeFeedUserRef({
    required this.id,
    required this.handle,
    required this.avatarUrl,
  });

  final String id;
  final String handle;
  final String avatarUrl;
}

class HomeFeedHabitRef {
  const HomeFeedHabitRef({
    required this.id,
    required this.title,
    required this.color,
  });

  final String id;
  final String title;
  final String color;
}

class HomeFeedEntry {
  const HomeFeedEntry({
    required this.id,
    required this.type,
    required this.actor,
    required this.createdAt,
    this.relatedUser,
    this.relatedHabit,
    this.streakValue,
  });

  final String id;
  final HomeFeedType type;
  final HomeFeedUserRef actor;
  final DateTime createdAt;
  final HomeFeedUserRef? relatedUser;
  final HomeFeedHabitRef? relatedHabit;
  final int? streakValue;

  bool get isPriorityReminder => type == HomeFeedType.sharedHabitReminder;

  String toPresentationText() {
    return switch (type) {
      HomeFeedType.friendAdded =>
        '"${actor.handle}" добавил друга "${relatedUser?.handle ?? 'пользователь'}"',
      HomeFeedType.habitStreak =>
        '"${actor.handle}" выполняет "${relatedHabit?.title ?? 'привычку'}" уже ${streakValue ?? 0} дней подряд',
      HomeFeedType.habitCreated =>
        '"${actor.handle}" создал новую привычку "${relatedHabit?.title ?? 'без названия'}"',
      HomeFeedType.sharedHabitReminder =>
        'Совместная привычка с "${actor.handle}": сегодня вы ещё не выполнили задание!',
    };
  }
}
