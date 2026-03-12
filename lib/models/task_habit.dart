import 'model_parsers.dart';

class TaskHabit {
  const TaskHabit({required this.taskId, required this.habitId})
    : assert(taskId != ''),
      assert(habitId != '');

  final String taskId;
  final String habitId;

  TaskHabit copyWith({String? taskId, String? habitId}) {
    return TaskHabit(
      taskId: taskId ?? this.taskId,
      habitId: habitId ?? this.habitId,
    );
  }

  factory TaskHabit.fromMap(Map<String, dynamic> map) {
    return TaskHabit(
      taskId: parseRequiredString(map['taskId'], 'taskId'),
      habitId: parseRequiredString(map['habitId'], 'habitId'),
    );
  }

  Map<String, dynamic> toMap() {
    return {'taskId': taskId, 'habitId': habitId};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskHabit &&
            runtimeType == other.runtimeType &&
            taskId == other.taskId &&
            habitId == other.habitId;
  }

  @override
  int get hashCode {
    return Object.hash(taskId, habitId);
  }
}
