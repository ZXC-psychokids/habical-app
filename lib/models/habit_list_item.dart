import 'habit.dart';

class HabitListItem {
  const HabitListItem({required this.habit, required this.streakDays})
    : assert(streakDays >= 0);

  final Habit habit;
  final int streakDays;

  String get streakLabel {
    if (streakDays >= 14 && streakDays % 7 == 0) {
      final weeks = streakDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }
    return '$streakDays ${streakDays == 1 ? 'day' : 'days'}';
  }
}
