class HabitCalendarCompletedHabit {
  const HabitCalendarCompletedHabit({
    required this.habitId,
    required this.color,
  });

  final String habitId;
  final String color;
}

class HabitCalendarDaySummary {
  const HabitCalendarDaySummary({
    required this.date,
    required this.completedHabits,
  });

  final DateTime date;
  final List<HabitCalendarCompletedHabit> completedHabits;
}
