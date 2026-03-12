import 'model_parsers.dart';

class EventCategory {
  const EventCategory({required this.eventId, required this.categoryId})
    : assert(eventId != ''),
      assert(categoryId != '');

  final String eventId;
  final String categoryId;

  EventCategory copyWith({String? eventId, String? categoryId}) {
    return EventCategory(
      eventId: eventId ?? this.eventId,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      eventId: parseRequiredString(map['eventId'], 'eventId'),
      categoryId: parseRequiredString(map['categoryId'], 'categoryId'),
    );
  }

  Map<String, dynamic> toMap() {
    return {'eventId': eventId, 'categoryId': categoryId};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EventCategory &&
            runtimeType == other.runtimeType &&
            eventId == other.eventId &&
            categoryId == other.categoryId;
  }

  @override
  int get hashCode {
    return Object.hash(eventId, categoryId);
  }
}
