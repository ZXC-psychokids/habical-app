import '../core/api_client.dart';
import '../core/app_logger.dart';

enum EventRepeatUnit { none, day, week, month }

class EventRepeatRule {
  const EventRepeatRule({this.unit = EventRepeatUnit.none, this.interval = 1})
    : assert(interval > 0);

  static const none = EventRepeatRule();

  final EventRepeatUnit unit;
  final int interval;

  bool get isNone => unit == EventRepeatUnit.none;
}

class CalendarEventItem {
  const CalendarEventItem({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String categoryId;
  final String categoryName;
  final String categoryColor;
}

class EventCategoryItem {
  const EventCategoryItem({
    required this.id,
    required this.title,
    required this.color,
  });

  final String id;
  final String title;
  final String color;
}

abstract class CalendarRepository {
  Future<List<CalendarEventItem>> fetchEventsInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  });

  Future<CalendarEventItem> addEvent({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule,
    String? categoryId,
    int categoryColorValue,
  });

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule,
    String? categoryId,
    int categoryColorValue,
  });

  Future<void> deleteEvent({
    required String eventId,
    required bool deleteFollowingInSeries,
  });

  Future<List<EventCategoryItem>> fetchCategories();

  Future<EventCategoryItem> createCategory({
    required String title,
    required String color,
  });

  Future<EventCategoryItem> updateCategory({
    required String categoryId,
    String? title,
    String? color,
  });

  Future<void> deleteCategory({
    required String categoryId,
  });
}

class ApiCalendarRepository implements CalendarRepository {
  ApiCalendarRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<CalendarEventItem>> fetchEventsInRange({
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/events',
      queryParameters: {
        'from': fromInclusive.toUtc().toIso8601String(),
        'to': toInclusive.toUtc().toIso8601String(),
      },
    );

    final raw = response.data;
    if (raw is! List) {
      AppLogger.e(
        'Failed to parse calendar events payload',
        StateError('Invalid events payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid events payload.');
    }

    final result = raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(_parseEvent)
        .toList(growable: false)
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return result;
  }

  @override
  Future<CalendarEventItem> addEvent({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule = EventRepeatRule.none,
    String? categoryId,
    int categoryColorValue = 0xFF5AA9E6,
  }) async {
    final resolvedCategoryId = categoryId?.trim().isNotEmpty == true
        ? categoryId!.trim()
        : await _resolveCategoryIdByColor(categoryColorValue);
    final response = await _apiClient.dio.post(
      '/me/events',
      data: {
        'title': title.trim(),
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        ..._schedulePayload(repeatRule),
        'categoryId': resolvedCategoryId,
        'taskId': null,
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse created calendar event payload',
        StateError('Invalid created event payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid created event payload.');
    }
    return _parseEvent(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule = EventRepeatRule.none,
    String? categoryId,
    int categoryColorValue = 0xFF5AA9E6,
  }) async {
    final resolvedCategoryId = categoryId?.trim().isNotEmpty == true
        ? categoryId!.trim()
        : await _resolveCategoryIdByColor(categoryColorValue);
    await _apiClient.dio.patch(
      '/me/events/$eventId',
      data: {
        'title': title.trim(),
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        ..._schedulePayload(repeatRule),
        'categoryId': resolvedCategoryId,
      },
    );
  }

  @override
  Future<void> deleteEvent({
    required String eventId,
    required bool deleteFollowingInSeries,
  }) async {
    await _apiClient.dio.delete('/me/events/$eventId');
  }

  @override
  Future<List<EventCategoryItem>> fetchCategories() async {
    final response = await _apiClient.dio.get('/me/event-categories');
    final raw = response.data;
    if (raw is! List) {
      AppLogger.e(
        'Failed to parse event categories payload',
        StateError('Invalid categories payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid categories payload.');
    }

    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (map) => EventCategoryItem(
            id: _requiredString(map['id'], 'id'),
            title: _requiredString(map['title'], 'title'),
            color: _requiredString(map['color'], 'color'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<EventCategoryItem> createCategory({
    required String title,
    required String color,
  }) async {
    final response = await _apiClient.dio.post(
      '/me/event-categories',
      data: {
        'title': title.trim(),
        'color': color.trim().toUpperCase(),
      },
    );
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse created category payload',
        StateError('Invalid created category payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid created category payload.');
    }
    final map = Map<String, dynamic>.from(raw);
    return EventCategoryItem(
      id: _requiredString(map['id'], 'id'),
      title: _requiredString(map['title'], 'title'),
      color: _requiredString(map['color'], 'color'),
    );
  }

  @override
  Future<EventCategoryItem> updateCategory({
    required String categoryId,
    String? title,
    String? color,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) {
      payload['title'] = title.trim();
    }
    if (color != null) {
      payload['color'] = color.trim().toUpperCase();
    }
    if (payload.isEmpty) {
      throw ArgumentError('No category fields to update.');
    }

    final response = await _apiClient.dio.patch(
      '/me/event-categories/$categoryId',
      data: payload,
    );
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse updated category payload',
        StateError('Invalid updated category payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid updated category payload.');
    }
    final map = Map<String, dynamic>.from(raw);
    return EventCategoryItem(
      id: _requiredString(map['id'], 'id'),
      title: _requiredString(map['title'], 'title'),
      color: _requiredString(map['color'], 'color'),
    );
  }

  @override
  Future<void> deleteCategory({
    required String categoryId,
  }) async {
    await _apiClient.dio.delete('/me/event-categories/$categoryId');
  }

  CalendarEventItem _parseEvent(Map<String, dynamic> map) {
    try {
      final categoryRaw = map['category'];
      if (categoryRaw is! Map) {
        throw StateError('Invalid event.category payload.');
      }
      final category = Map<String, dynamic>.from(categoryRaw);

      return CalendarEventItem(
        id: _requiredString(map['id'], 'id'),
        title: _requiredString(map['title'], 'title'),
        startsAt: _requiredDateTime(map['startsAt'], 'startsAt'),
        endsAt: _requiredDateTime(map['endsAt'], 'endsAt'),
        categoryId: _requiredString(category['id'], 'category.id'),
        categoryName: _requiredString(category['title'], 'category.title'),
        categoryColor: _requiredString(category['color'], 'category.color'),
      );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to parse CalendarEventItem data=${AppLogger.pretty(map)}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<String> _resolveCategoryIdByColor(int argbColor) async {
    final hexColor = _argbToHex(argbColor);
    final categories = await fetchCategories();
    for (final category in categories) {
      if (category.color.toUpperCase() == hexColor) {
        return category.id;
      }
    }

    final response = await _apiClient.dio.post(
      '/me/event-categories',
      data: {
        'title': 'Category $hexColor',
        'color': hexColor,
      },
    );
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse auto-created category payload',
        StateError('Invalid created category payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid created category payload.');
    }
    final map = Map<String, dynamic>.from(raw);
    return _requiredString(map['id'], 'id');
  }

  Map<String, dynamic> _schedulePayload(EventRepeatRule rule) {
    if (rule.isNone) {
      return const {
        'scheduleType': 'none',
        'intervalDays': 1,
        'weekdays': <int>[],
      };
    }

    if (rule.unit == EventRepeatUnit.day) {
      if (rule.interval == 1) {
        return const {
          'scheduleType': 'daily',
          'intervalDays': 1,
          'weekdays': <int>[],
        };
      }
      return {
        'scheduleType': 'interval',
        'intervalDays': rule.interval,
        'weekdays': <int>[],
      };
    }

    if (rule.unit == EventRepeatUnit.week) {
      return {
        'scheduleType': 'interval',
        'intervalDays': rule.interval * 7,
        'weekdays': <int>[],
      };
    }

    return {
      'scheduleType': 'monthly',
      'intervalDays': rule.interval,
      'weekdays': <int>[],
    };
  }

  String _argbToHex(int argbColor) {
    final rgb = argbColor & 0x00FFFFFF;
    final hex = rgb.toRadixString(16).toUpperCase().padLeft(6, '0');
    return '#$hex';
  }

  String _requiredString(dynamic value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  DateTime _requiredDateTime(dynamic value, String fieldName) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw StateError('Invalid "$fieldName" field.');
  }
}
