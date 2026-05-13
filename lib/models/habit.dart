import 'model_parsers.dart';

class Habit {
  const Habit({
    required this.id,
    required this.title,
    this.color = '#5AA9E6',
    this.scheduleType = 'daily',
    this.intervalDays = 1,
    this.weekdays = const <int>[],
    required this.periodicityDays,
    required this.initialStreakDays,
    required this.userId,
    this.sharedWithName,
  }) : assert(id != ''),
       assert(title != ''),
       assert(color != ''),
       assert(scheduleType != ''),
       assert(intervalDays > 0),
       assert(periodicityDays > 0),
       assert(initialStreakDays >= 0),
       assert(userId != ''),
       assert(sharedWithName == null || sharedWithName != '');

  final String id;
  final String title;
  final String color;
  final String scheduleType;
  final int intervalDays;
  final List<int> weekdays;
  final int periodicityDays;
  final int initialStreakDays;
  final String userId;
  final String? sharedWithName;

  bool get isShared => sharedWithName != null;

  Habit copyWith({
    String? id,
    String? title,
    String? color,
    String? scheduleType,
    int? intervalDays,
    List<int>? weekdays,
    int? periodicityDays,
    int? initialStreakDays,
    String? userId,
    String? sharedWithName,
    bool clearSharedWithName = false,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      scheduleType: scheduleType ?? this.scheduleType,
      intervalDays: intervalDays ?? this.intervalDays,
      weekdays: weekdays ?? this.weekdays,
      periodicityDays: periodicityDays ?? this.periodicityDays,
      initialStreakDays: initialStreakDays ?? this.initialStreakDays,
      userId: userId ?? this.userId,
      sharedWithName: clearSharedWithName
          ? null
          : (sharedWithName ?? this.sharedWithName),
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final periodicity = _resolvePeriodicityDays(map);
    return Habit(
      id: parseRequiredString(map['id'], 'id'),
      title: parseRequiredString(map['title'], 'title'),
      color: _parseColor(map),
      scheduleType: _parseScheduleType(map),
      intervalDays: _parseIntervalDays(map),
      weekdays: _parseWeekdays(map),
      periodicityDays: periodicity,
      initialStreakDays: _parseInitialStreakDays(map),
      userId: _parseUserId(map),
      sharedWithName: _parseSharedWithName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'scheduleType': scheduleType,
      'intervalDays': intervalDays,
      'weekdays': weekdays,
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
            color == other.color &&
            scheduleType == other.scheduleType &&
            intervalDays == other.intervalDays &&
            _listEquals(weekdays, other.weekdays) &&
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
      color,
      scheduleType,
      intervalDays,
      Object.hashAll(weekdays),
      periodicityDays,
      initialStreakDays,
      userId,
      sharedWithName,
    );
  }

  static String _parseColor(Map<String, dynamic> map) {
    final value = map['color'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return '#5AA9E6';
  }

  static String _parseScheduleType(Map<String, dynamic> map) {
    final value = map['scheduleType'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return 'daily';
  }

  static int _parseIntervalDays(Map<String, dynamic> map) {
    final value = map['intervalDays'];
    if (value is int && value > 0) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    final periodicity = map['periodicityDays'];
    if (periodicity is int && periodicity > 0) {
      return periodicity;
    }
    return 1;
  }

  static List<int> _parseWeekdays(Map<String, dynamic> map) {
    final value = map['weekdays'];
    if (value is List) {
      return value
          .whereType<int>()
          .where((day) => day >= 1 && day <= 7)
          .toList(growable: false);
    }
    return const <int>[];
  }

  static int _resolvePeriodicityDays(Map<String, dynamic> map) {
    final periodicity = map['periodicityDays'];
    if (periodicity is int && periodicity > 0) {
      return periodicity;
    }

    final scheduleType = _parseScheduleType(map);
    if (scheduleType == 'interval') {
      return _parseIntervalDays(map);
    }
    return 1;
  }

  static int _parseInitialStreakDays(Map<String, dynamic> map) {
    final value = map['initialStreakDays'];
    if (value is int && value >= 0) {
      return value;
    }
    final streakDays = map['streakDays'];
    if (streakDays is int && streakDays >= 0) {
      return streakDays;
    }
    return 0;
  }

  static String _parseUserId(Map<String, dynamic> map) {
    final userId = map['userId'];
    if (userId is String && userId.trim().isNotEmpty) {
      return userId;
    }
    return 'me';
  }

  static String? _parseSharedWithName(Map<String, dynamic> map) {
    final flat = map['sharedWithName'];
    if (flat is String && flat.trim().isNotEmpty) {
      return flat;
    }

    final sharedWith = map['sharedWith'];
    if (sharedWith is Map) {
      final handle = sharedWith['handle'];
      if (handle is String && handle.trim().isNotEmpty) {
        return handle;
      }
    }
    return null;
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
