import 'model_parsers.dart';

class Event {
  Event({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.userId,
    this.taskId,
  }) : assert(id != ''),
       assert(title != ''),
       assert(userId != ''),
       assert(taskId == null || taskId.isNotEmpty),
       assert(!endsAt.isBefore(startsAt));

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String userId;
  final String? taskId;

  Event copyWith({
    String? id,
    String? title,
    DateTime? startsAt,
    DateTime? endsAt,
    String? userId,
    String? taskId,
    bool removeTaskId = false,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      userId: userId ?? this.userId,
      taskId: removeTaskId ? null : (taskId ?? this.taskId),
    );
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: parseRequiredString(map['id'], 'id'),
      title: parseRequiredString(map['title'], 'title'),
      startsAt: parseRequiredDateTime(map['startsAt'], 'startsAt'),
      endsAt: parseRequiredDateTime(map['endsAt'], 'endsAt'),
      userId: parseRequiredString(map['userId'], 'userId'),
      taskId: parseNullableString(map['taskId'], 'taskId'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'userId': userId,
      'taskId': taskId,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Event &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            startsAt == other.startsAt &&
            endsAt == other.endsAt &&
            userId == other.userId &&
            taskId == other.taskId;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, startsAt, endsAt, userId, taskId);
  }
}
