class HomeTaskHabitRef {
  const HomeTaskHabitRef({
    required this.id,
    required this.title,
    required this.color,
  });

  final String id;
  final String title;
  final String color;
}

class HomeTaskEventRef {
  const HomeTaskEventRef({
    required this.id,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
}

class HomeTaskItem {
  const HomeTaskItem({
    required this.id,
    required this.title,
    required this.taskDate,
    required this.position,
    required this.isCompleted,
    this.manualColor,
    this.habit,
    this.event,
  });

  final String id;
  final String title;
  final DateTime taskDate;
  final int position;
  final bool isCompleted;
  final String? manualColor;
  final HomeTaskHabitRef? habit;
  final HomeTaskEventRef? event;

  HomeTaskItem copyWith({
    String? id,
    String? title,
    DateTime? taskDate,
    int? position,
    bool? isCompleted,
    String? manualColor,
    bool clearManualColor = false,
    HomeTaskHabitRef? habit,
    bool clearHabit = false,
    HomeTaskEventRef? event,
    bool clearEvent = false,
  }) {
    return HomeTaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      taskDate: taskDate ?? this.taskDate,
      position: position ?? this.position,
      isCompleted: isCompleted ?? this.isCompleted,
      manualColor: clearManualColor ? null : (manualColor ?? this.manualColor),
      habit: clearHabit ? null : (habit ?? this.habit),
      event: clearEvent ? null : (event ?? this.event),
    );
  }
}
