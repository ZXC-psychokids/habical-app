import 'habit.dart';
import 'task.dart';

class HabitDetailsData {
  const HabitDetailsData({required this.habit, required this.tasks});

  final Habit habit;
  final List<Task> tasks;
}
