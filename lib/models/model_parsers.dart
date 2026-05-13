import '../core/app_logger.dart';

DateTime parseRequiredDateTime(dynamic value, String fieldName) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  AppLogger.e(
    'Failed to parse DateTime field "$fieldName"',
    FormatException(
      'Field "$fieldName" must be DateTime or ISO-8601 String.',
    ),
    StackTrace.current,
  );
  throw FormatException(
    'Field "$fieldName" must be DateTime or ISO-8601 String.',
  );
}

String parseRequiredString(dynamic value, String fieldName) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  AppLogger.e(
    'Failed to parse String field "$fieldName" value=${AppLogger.pretty(value)}',
    FormatException('Field "$fieldName" must be a non-empty String.'),
    StackTrace.current,
  );
  throw FormatException('Field "$fieldName" must be a non-empty String.');
}

String? parseNullableString(dynamic value, String fieldName) {
  if (value == null) {
    return null;
  }
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  AppLogger.e(
    'Failed to parse nullable String field "$fieldName" value=${AppLogger.pretty(value)}',
    FormatException(
      'Field "$fieldName" must be null or a non-empty String.',
    ),
    StackTrace.current,
  );
  throw FormatException(
    'Field "$fieldName" must be null or a non-empty String.',
  );
}

int parseRequiredInt(dynamic value, String fieldName) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  AppLogger.e(
    'Failed to parse int field "$fieldName" value=${AppLogger.pretty(value)}',
    FormatException('Field "$fieldName" must be int.'),
    StackTrace.current,
  );
  throw FormatException('Field "$fieldName" must be int.');
}

bool parseRequiredBool(dynamic value, String fieldName) {
  if (value is bool) {
    return value;
  }
  if (value is int) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  AppLogger.e(
    'Failed to parse bool field "$fieldName" value=${AppLogger.pretty(value)}',
    FormatException('Field "$fieldName" must be bool, 0/1, or true/false.'),
    StackTrace.current,
  );
  throw FormatException('Field "$fieldName" must be bool, 0/1, or true/false.');
}
