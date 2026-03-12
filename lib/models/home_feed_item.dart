enum HomeFeedKind {
  streak,
  startedHabit,
  achievement,
}

class HomeFeedItem {
  const HomeFeedItem({
    required this.id,
    required this.friendName,
    required this.message,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String friendName;
  final String message;
  final HomeFeedKind kind;
  final DateTime createdAt;
}