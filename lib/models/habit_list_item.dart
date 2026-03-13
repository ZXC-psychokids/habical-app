import 'habit.dart';

class HabitListItem {
  const HabitListItem({required this.habit, required this.streakDays})
    : assert(streakDays >= 0);

  final Habit habit;
  final int streakDays;

  String get streakLabel {
    if (streakDays >= 14 && streakDays % 7 == 0) {
      final weeks = streakDays ~/ 7;
      return '$weeks ${_pluralRu(weeks, 'неделя', 'недели', 'недель')}';
    }
    return '$streakDays ${_pluralRu(streakDays, 'день', 'дня', 'дней')}';
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
