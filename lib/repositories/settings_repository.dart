import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/app_logger.dart';

class ProfileData {
  const ProfileData({
    required this.id,
    required this.email,
    required this.handle,
    required this.avatarUrl,
  });

  final String id;
  final String email;
  final String handle;
  final String avatarUrl;
}

class UserSettingsData {
  const UserSettingsData({
    required this.shareHabits,
    required this.shareCalendar,
    required this.shareNews,
    required this.notifyFriendRequests,
    required this.notifyHabitReminders,
    required this.notifyFriendsNews,
    required this.timezone,
    required this.weekStartsOn,
  });

  final bool shareHabits;
  final bool shareCalendar;
  final bool shareNews;
  final bool notifyFriendRequests;
  final bool notifyHabitReminders;
  final bool notifyFriendsNews;
  final String timezone;
  final int weekStartsOn;
}

class ProfileAndSettings {
  const ProfileAndSettings({
    required this.profile,
    required this.settings,
  });

  final ProfileData profile;
  final UserSettingsData settings;
}

class SettingsRepository {
  SettingsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ProfileAndSettings> fetchProfileAndSettings() async {
    final results = await Future.wait([
      _apiClient.dio.get('/me'),
      _apiClient.dio.get('/me/settings'),
    ]);

    final profileRaw = results[0].data;
    final settingsRaw = results[1].data;
    if (profileRaw is! Map || settingsRaw is! Map) {
      AppLogger.e(
        'SettingsRepository.fetchProfileAndSettings failed: invalid payload',
        StateError('Invalid profile/settings payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid profile/settings payload.');
    }

    return ProfileAndSettings(
      profile: _parseProfile(Map<String, dynamic>.from(profileRaw)),
      settings: _parseSettings(Map<String, dynamic>.from(settingsRaw)),
    );
  }

  Future<ProfileData> updateProfile({
    String? email,
    String? handle,
  }) async {
    final payload = <String, dynamic>{};
    if (email != null) {
      payload['email'] = email.trim();
    }
    if (handle != null) {
      payload['handle'] = handle.trim();
    }
    if (payload.isEmpty) {
      throw ArgumentError('No profile fields to update.');
    }

    final response = await _apiClient.dio.patch('/me/profile', data: payload);
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'SettingsRepository.updateProfile failed: invalid profile payload',
        StateError('Invalid profile payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid profile payload.');
    }
    return _parseProfile(Map<String, dynamic>.from(raw));
  }

  Future<UserSettingsData> updatePrivacy({
    bool? shareHabits,
    bool? shareCalendar,
    bool? shareNews,
  }) async {
    final payload = <String, dynamic>{};
    if (shareHabits != null) {
      payload['shareHabits'] = shareHabits;
    }
    if (shareCalendar != null) {
      payload['shareCalendar'] = shareCalendar;
    }
    if (shareNews != null) {
      payload['shareNews'] = shareNews;
    }
    if (payload.isEmpty) {
      throw ArgumentError('No privacy fields to update.');
    }

    await _apiClient.dio.patch('/me/settings/privacy', data: payload);
    return _fetchSettings();
  }

  Future<UserSettingsData> updateNotifications({
    bool? notifyFriendRequests,
    bool? notifyHabitReminders,
    bool? notifyFriendsNews,
  }) async {
    final payload = <String, dynamic>{};
    if (notifyFriendRequests != null) {
      payload['notifyFriendRequests'] = notifyFriendRequests;
    }
    if (notifyHabitReminders != null) {
      payload['notifyHabitReminders'] = notifyHabitReminders;
    }
    if (notifyFriendsNews != null) {
      payload['notifyFriendsNews'] = notifyFriendsNews;
    }
    if (payload.isEmpty) {
      throw ArgumentError('No notification fields to update.');
    }

    await _apiClient.dio.patch('/me/settings/notifications', data: payload);
    return _fetchSettings();
  }

  Future<UserSettingsData> updateCalendarSettings({
    String? timezone,
    int? weekStartsOn,
  }) async {
    final payload = <String, dynamic>{};
    if (timezone != null) {
      payload['timezone'] = timezone.trim();
    }
    if (weekStartsOn != null) {
      payload['weekStartsOn'] = weekStartsOn;
    }
    if (payload.isEmpty) {
      throw ArgumentError('No calendar fields to update.');
    }

    await _apiClient.dio.patch('/me/settings/calendar', data: payload);
    return _fetchSettings();
  }

  Future<ProfileData> updateAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    final mediaType = MultipartFile.lookupMediaType(filename);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mediaType,
      ),
    });

    final response = await _apiClient.dio.patch('/me/avatar', data: formData);
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'SettingsRepository.updateAvatar failed: invalid profile payload',
        StateError('Invalid profile payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid profile payload.');
    }
    return _parseProfile(Map<String, dynamic>.from(raw));
  }

  Future<UserSettingsData> _fetchSettings() async {
    final response = await _apiClient.dio.get('/me/settings');
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'SettingsRepository._fetchSettings failed: invalid settings payload',
        StateError('Invalid settings payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid settings payload.');
    }
    return _parseSettings(Map<String, dynamic>.from(raw));
  }

  ProfileData _parseProfile(Map<String, dynamic> map) {
    return ProfileData(
      id: _asNonEmptyString(map['id'], 'id'),
      email: _asNonEmptyString(map['email'], 'email'),
      handle: _asNonEmptyString(map['handle'], 'handle'),
      avatarUrl: _asString(map['avatarUrl']) ?? '',
    );
  }

  UserSettingsData _parseSettings(Map<String, dynamic> map) {
    return UserSettingsData(
      shareHabits: _asBool(map['shareHabits'], 'shareHabits'),
      shareCalendar: _asBool(map['shareCalendar'], 'shareCalendar'),
      shareNews: _asBool(map['shareNews'], 'shareNews'),
      notifyFriendRequests: _asBool(
        map['notifyFriendRequests'],
        'notifyFriendRequests',
      ),
      notifyHabitReminders: _asBool(
        map['notifyHabitReminders'],
        'notifyHabitReminders',
      ),
      notifyFriendsNews: _asBool(
        map['notifyFriendsNews'],
        'notifyFriendsNews',
      ),
      timezone: _asNonEmptyString(map['timezone'], 'timezone'),
      weekStartsOn: _asInt(map['weekStartsOn'], 'weekStartsOn'),
    );
  }

  String _asNonEmptyString(dynamic value, String field) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    AppLogger.e(
      'SettingsRepository failed to parse non-empty string field "$field"',
      StateError('Invalid "$field" field.'),
      StackTrace.current,
    );
    throw StateError('Invalid "$field" field.');
  }

  String? _asString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  bool _asBool(dynamic value, String field) {
    if (value is bool) {
      return value;
    }
    AppLogger.e(
      'SettingsRepository failed to parse bool field "$field"',
      StateError('Invalid "$field" field.'),
      StackTrace.current,
    );
    throw StateError('Invalid "$field" field.');
  }

  int _asInt(dynamic value, String field) {
    if (value is int) {
      return value;
    }
    AppLogger.e(
      'SettingsRepository failed to parse int field "$field"',
      StateError('Invalid "$field" field.'),
      StackTrace.current,
    );
    throw StateError('Invalid "$field" field.');
  }
}
