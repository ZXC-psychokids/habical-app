class SharedHabitCreationResult {
  const SharedHabitCreationResult({
    required this.sharedHabitPairId,
    required this.firstHabitId,
    required this.secondHabitId,
  });

  final String sharedHabitPairId;
  final String firstHabitId;
  final String secondHabitId;
}

class SharedHabitParticipant {
  const SharedHabitParticipant({
    required this.id,
    required this.handle,
  });

  final String id;
  final String handle;
}

class SharedHabitDetails {
  const SharedHabitDetails({
    required this.sharedHabitPairId,
    required this.title,
    required this.color,
    required this.streakDays,
    required this.youCompletedToday,
    required this.friendCompletedToday,
    required this.you,
    required this.friend,
    this.todayTaskId,
  });

  final String sharedHabitPairId;
  final String title;
  final String color;
  final int streakDays;
  final bool youCompletedToday;
  final bool friendCompletedToday;
  final SharedHabitParticipant you;
  final SharedHabitParticipant friend;
  final String? todayTaskId;
}

class SharedHabitRemindResult {
  const SharedHabitRemindResult({required this.message});

  final String message;
}
