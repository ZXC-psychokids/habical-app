import 'model_parsers.dart';

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.periodicityDays,
    required this.initialStreakDays,
    required this.userId,
    this.sharedWithName,
  }) : assert(id != ''),
       assert(title != ''),
       assert(periodicityDays > 0),
       assert(initialStreakDays >= 0),
       assert(userId != ''),
       assert(sharedWithName == null || sharedWithName != '');

  final String id;
  final String title;
  final int periodicityDays;
  final int initialStreakDays;
  final String userId;
  final String? sharedWithName;

  bool get isShared => sharedWithName != null;

  Habit copyWith({
    String? id,
    String? title,
    int? periodicityDays,
    int? initialStreakDays,
    String? userId,
    String? sharedWithName,
    bool clearSharedWithName = false,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      periodicityDays: periodicityDays ?? this.periodicityDays,
      initialStreakDays: initialStreakDays ?? this.initialStreakDays,
      userId: userId ?? this.userId,
      sharedWithName: clearSharedWithName
          ? null
          : (sharedWithName ?? this.sharedWithName),
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: parseRequiredString(map['id'], 'id'),
      title: parseRequiredString(map['title'], 'title'),
      periodicityDays: parseRequiredInt(
        map['periodicityDays'],
        'periodicityDays',
      ),
      initialStreakDays: parseRequiredInt(
        map['initialStreakDays'],
        'initialStreakDays',
      ),
      userId: parseRequiredString(map['userId'], 'userId'),
      sharedWithName: parseNullableString(
        map['sharedWithName'],
        'sharedWithName',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'periodicityDays': periodicityDays,
      'initialStreakDays': initialStreakDays,
      'userId': userId,
      'sharedWithName': sharedWithName,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Habit &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            periodicityDays == other.periodicityDays &&
            initialStreakDays == other.initialStreakDays &&
            userId == other.userId &&
            sharedWithName == other.sharedWithName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      periodicityDays,
      initialStreakDays,
      userId,
      sharedWithName,
    );
  }
}
