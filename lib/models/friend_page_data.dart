class FriendPublicProfile {
  const FriendPublicProfile({
    required this.id,
    required this.handle,
    required this.avatarUrl,
  });

  final String id;
  final String handle;
  final String avatarUrl;
}

class FriendTaskPreview {
  const FriendTaskPreview({
    required this.id,
    required this.title,
    required this.isCompleted,
    this.habitTitle,
    this.habitColor,
    this.eventId,
    this.eventStartsAt,
    this.eventEndsAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final String? habitTitle;
  final String? habitColor;
  final String? eventId;
  final DateTime? eventStartsAt;
  final DateTime? eventEndsAt;
}

class FriendEventPreview {
  const FriendEventPreview({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.categoryName,
    required this.categoryColor,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String categoryName;
  final String categoryColor;
}

class SharedHabitPreview {
  const SharedHabitPreview({
    required this.sharedHabitPairId,
    required this.habitId,
    required this.title,
    required this.color,
    required this.streakDays,
    required this.youCompletedToday,
    required this.friendCompletedToday,
  });

  final String sharedHabitPairId;
  final String habitId;
  final String title;
  final String color;
  final int streakDays;
  final bool youCompletedToday;
  final bool friendCompletedToday;
}

class FriendPageData {
  const FriendPageData({
    required this.profile,
    required this.tasks,
    required this.events,
    required this.sharedHabits,
    required this.canViewTasks,
    required this.canViewEvents,
    required this.canViewSharedHabits,
  });

  final FriendPublicProfile profile;
  final List<FriendTaskPreview> tasks;
  final List<FriendEventPreview> events;
  final List<SharedHabitPreview> sharedHabits;
  final bool canViewTasks;
  final bool canViewEvents;
  final bool canViewSharedHabits;

  bool get isEverythingHidden {
    return !canViewTasks && !canViewEvents && !canViewSharedHabits;
  }

  bool get hasTopBlockData {
    return canViewTasks || canViewEvents;
  }
}
