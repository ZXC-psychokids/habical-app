import 'model_parsers.dart';

class TaskCategory {
  const TaskCategory({required this.taskId, required this.categoryId})
    : assert(taskId != ''),
      assert(categoryId != '');

  final String taskId;
  final String categoryId;

  TaskCategory copyWith({String? taskId, String? categoryId}) {
    return TaskCategory(
      taskId: taskId ?? this.taskId,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      taskId: parseRequiredString(map['taskId'], 'taskId'),
      categoryId: parseRequiredString(map['categoryId'], 'categoryId'),
    );
  }

  Map<String, dynamic> toMap() {
    return {'taskId': taskId, 'categoryId': categoryId};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaskCategory &&
            runtimeType == other.runtimeType &&
            taskId == other.taskId &&
            categoryId == other.categoryId;
  }

  @override
  int get hashCode {
    return Object.hash(taskId, categoryId);
  }
}
