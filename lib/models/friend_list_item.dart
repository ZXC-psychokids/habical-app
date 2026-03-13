enum FriendRelationStatus {
  connected,
  suggestion,
}

class FriendListItem {
  const FriendListItem({
    required this.id,
    required this.name,
    required this.status,
    required this.streakDays,
    this.sharedHabitTitle,
  }) : assert(id != ''),
       assert(name != ''),
       assert(streakDays >= 0),
       assert(
         sharedHabitTitle == null || sharedHabitTitle != '',
       );

  final String id;
  final String name;
  final FriendRelationStatus status;
  final int streakDays;
  final String? sharedHabitTitle;

  bool get isConnected => status == FriendRelationStatus.connected;
  bool get hasSharedHabit => sharedHabitTitle != null;

  FriendListItem copyWith({
    String? id,
    String? name,
    FriendRelationStatus? status,
    int? streakDays,
    String? sharedHabitTitle,
    bool clearSharedHabit = false,
  }) {
    return FriendListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      streakDays: streakDays ?? this.streakDays,
      sharedHabitTitle: clearSharedHabit
          ? null
          : (sharedHabitTitle ?? this.sharedHabitTitle),
    );
  }

  String get streakLabel {
    final dayWord = _pluralRu(streakDays, 'день', 'дня', 'дней');
    return '$streakDays $dayWord';
  }

  String _pluralRu(int value, String one, String few, String many) {
    final mod100 = value % 100;
    if (mod100 >= 11 && mod100 <= 14) {
      return many;
    }

    final mod10 = value % 10;
    if (mod10 == 1) {
      return one;
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return few;
    }
    return many;
  }
}
