enum FriendFeedType {
  friendAdded,
  habitStreak,
  habitCreated,
  sharedHabitReminder,
}

class FriendFeedItem {
  const FriendFeedItem({
    required this.id,
    required this.type,
    required this.actorHandle,
    required this.createdAt,
    this.relatedUserHandle,
    this.relatedHabitTitle,
    this.streakValue,
  });

  final String id;
  final FriendFeedType type;
  final String actorHandle;
  final DateTime createdAt;
  final String? relatedUserHandle;
  final String? relatedHabitTitle;
  final int? streakValue;

  String toPresentationText() {
    return switch (type) {
      FriendFeedType.friendAdded =>
        '$actorHandle added ${relatedUserHandle ?? 'a friend'}',
      FriendFeedType.habitStreak =>
        '$actorHandle streak: ${streakValue ?? 0} days (${relatedHabitTitle ?? 'habit'})',
      FriendFeedType.habitCreated =>
        '$actorHandle created habit ${relatedHabitTitle ?? ''}'.trim(),
      FriendFeedType.sharedHabitReminder =>
        '$actorHandle sent a reminder for ${relatedHabitTitle ?? 'a shared habit'}',
    };
  }
}

class FriendFeedPage {
  const FriendFeedPage({
    required this.items,
    required this.nextCursor,
  });

  final List<FriendFeedItem> items;
  final String? nextCursor;
}
