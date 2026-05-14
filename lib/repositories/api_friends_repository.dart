import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/app_logger.dart';
import '../models/friend_feed_item.dart';
import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import '../models/friend_page_data.dart';
import 'friends_repository.dart';

class ApiFriendsRepository implements FriendsRepository {
  ApiFriendsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<FriendListItem>> fetchFriends() async {
    final response = await _apiClient.dio.get('/me/friends');
    final raw = response.data;
    if (raw is! List) {
      AppLogger.e(
        'Failed to parse friends payload',
        StateError('Invalid friends payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid friends payload.');
    }

    final result = raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) {
          try {
            final userRaw = map['user'];
            if (userRaw is! Map) {
              throw StateError('Invalid friend user payload.');
            }
            final user = Map<String, dynamic>.from(userRaw);
            final handle = _requiredString(user['handle'], 'user.handle');
            return FriendListItem(
              id: _requiredString(user['id'], 'user.id'),
              userId: _requiredString(user['id'], 'user.id'),
              name: handle,
              status: FriendRelationStatus.connected,
              streakDays: 0,
              sharedHabitsCount: _asInt(map['sharedHabitsCount']) ?? 0,
              sharedHabitTitle: null,
            );
          } catch (error, stackTrace) {
            AppLogger.e(
              'Failed to parse FriendListItem data=${AppLogger.pretty(map)}',
              error,
              stackTrace,
            );
            rethrow;
          }
        })
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  @override
  Future<List<FriendInviteItem>> fetchIncomingInvites() async {
    final response = await _apiClient.dio.get('/me/friend-invites');
    final raw = response.data;
    if (raw is! List) {
      AppLogger.e(
        'Failed to parse friend invites payload',
        StateError('Invalid friend invites payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid friend invites payload.');
    }

    final result = raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) {
          try {
            final senderRaw = map['sender'];
            if (senderRaw is! Map) {
              throw StateError('Invalid invite sender payload.');
            }
            final sender = Map<String, dynamic>.from(senderRaw);
            return FriendInviteItem(
              id: _requiredString(map['id'], 'id'),
              fromUserId: _requiredString(sender['id'], 'sender.id'),
              fromName: _requiredString(sender['handle'], 'sender.handle'),
              fromEmail: _requiredString(sender['handle'], 'sender.handle'),
              sentAt: _requiredDateTime(map['createdAt'], 'createdAt'),
            );
          } catch (error, stackTrace) {
            AppLogger.e(
              'Failed to parse FriendInviteItem data=${AppLogger.pretty(map)}',
              error,
              stackTrace,
            );
            rethrow;
          }
        })
        .toList(growable: false)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return result;
  }

  @override
  Future<void> sendInviteByHandle({
    required String handle,
  }) async {
    await _apiClient.dio.post(
      '/me/friend-invites',
      data: {'handle': handle.trim()},
    );
  }

  @override
  Future<void> acceptInvite({
    required String inviteId,
  }) async {
    await _apiClient.dio.post('/me/friend-invites/$inviteId/accept');
  }

  @override
  Future<void> rejectInvite({
    required String inviteId,
  }) async {
    await _apiClient.dio.post('/me/friend-invites/$inviteId/reject');
  }

  @override
  Future<void> removeFriend({
    required String friendUserId,
  }) async {
    await _apiClient.dio.delete('/me/friends/$friendUserId');
  }

  @override
  Future<FriendFeedPage> fetchFeed({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _apiClient.dio.get(
      '/me/feed',
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final raw = response.data;
    if (raw is! Map) {
      AppLogger.e(
        'Failed to parse feed payload',
        StateError('Invalid feed payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid feed payload.');
    }

    final map = Map<String, dynamic>.from(raw);
    final itemsRaw = map['items'];
    if (itemsRaw is! List) {
      AppLogger.e(
        'Failed to parse feed items payload',
        StateError('Invalid feed items payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid feed items payload.');
    }

    final items = itemsRaw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(_parseFeedItem)
        .toList(growable: false);

    final nextCursor = map['nextCursor'];
    return FriendFeedPage(
      items: items,
      nextCursor: nextCursor is String && nextCursor.isNotEmpty
          ? nextCursor
          : null,
    );
  }

  @override
  Future<FriendPageData> fetchFriendPage({
    required String userId,
    required DateTime day,
  }) async {
    final dateString = _formatDate(day);
    final profileResponse = await _apiClient.dio.get('/users/$userId');
    final profileRaw = profileResponse.data;
    if (profileRaw is! Map) {
      AppLogger.e(
        'Failed to parse friend profile payload',
        StateError('Invalid friend profile payload.'),
        StackTrace.current,
      );
      throw StateError('Invalid friend profile payload.');
    }

    final profileMap = Map<String, dynamic>.from(profileRaw);
    final profile = FriendPublicProfile(
      id: _requiredString(profileMap['id'], 'id'),
      handle: _requiredString(profileMap['handle'], 'handle'),
      avatarUrl: _requiredString(profileMap['avatarUrl'], 'avatarUrl'),
    );

    final tasksResponse = await _getListOrForbidden(
      '/users/$userId/tasks',
      queryParameters: {'date': dateString},
    );
    final eventsResponse = await _getListOrForbidden(
      '/users/$userId/events',
      queryParameters: {'date': dateString},
    );
    final sharedHabitsResponse = await _getListOrForbidden(
      '/users/$userId/shared-habits',
    );

    final tasks = tasksResponse.allowed
        ? _parseFriendTasks(tasksResponse.listData)
        : const <FriendTaskPreview>[];
    final events = eventsResponse.allowed
        ? _parseFriendEvents(eventsResponse.listData)
        : const <FriendEventPreview>[];
    final sharedHabits = sharedHabitsResponse.allowed
        ? _parseSharedHabits(sharedHabitsResponse.listData)
        : const <SharedHabitPreview>[];

    return FriendPageData(
      profile: profile,
      tasks: tasks,
      events: events,
      sharedHabits: sharedHabits,
      canViewTasks: tasksResponse.allowed,
      canViewEvents: eventsResponse.allowed,
      canViewSharedHabits: sharedHabitsResponse.allowed,
    );
  }

  @override
  Future<List<FriendEventPreview>> fetchFriendEvents({
    required String userId,
    required DateTime day,
  }) async {
    final response = await _getListOrForbidden(
      '/users/$userId/events',
      queryParameters: {'date': _formatDate(day)},
    );
    if (!response.allowed) {
      throw StateError('Friend calendar is private.');
    }
    return _parseFriendEvents(response.listData);
  }

  FriendFeedItem _parseFeedItem(Map<String, dynamic> map) {
    try {
      final actorRaw = map['actor'];
      if (actorRaw is! Map) {
        throw StateError('Invalid feed actor payload.');
      }
      final actor = Map<String, dynamic>.from(actorRaw);

      final relatedUser = _asMap(map['relatedUser']);
      final relatedHabit = _asMap(map['relatedHabit']);

      return FriendFeedItem(
        id: _requiredString(map['id'], 'id'),
        type: _parseFeedType(_requiredString(map['type'], 'type')),
        actorHandle: _requiredString(actor['handle'], 'actor.handle'),
        relatedUserHandle: relatedUser == null
            ? null
            : _requiredString(relatedUser['handle'], 'relatedUser.handle'),
        relatedHabitTitle: relatedHabit == null
            ? null
            : _requiredString(relatedHabit['title'], 'relatedHabit.title'),
        streakValue: _asInt(map['streakValue']),
        createdAt: _requiredDateTime(map['createdAt'], 'createdAt'),
      );
    } catch (error, stackTrace) {
      AppLogger.e(
        'Failed to parse FriendFeedItem data=${AppLogger.pretty(map)}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  List<FriendTaskPreview> _parseFriendTasks(List<dynamic> raw) {
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (map) {
            final habitMap = _asMap(map['habit']);
            final eventMap = _asMap(map['event']);
            return FriendTaskPreview(
              id: _requiredString(map['id'], 'id'),
              title: _requiredString(map['title'], 'title'),
              isCompleted: _requiredBool(map['isCompleted'], 'isCompleted'),
              habitTitle: habitMap == null
                  ? null
                  : _requiredString(habitMap['title'], 'habit.title'),
              habitColor: habitMap == null
                  ? null
                  : _requiredString(habitMap['color'], 'habit.color'),
              eventId: eventMap == null
                  ? null
                  : _requiredString(eventMap['id'], 'event.id'),
              eventStartsAt: eventMap == null
                  ? null
                  : _requiredDateTime(eventMap['startsAt'], 'event.startsAt'),
              eventEndsAt: eventMap == null
                  ? null
                  : _requiredDateTime(eventMap['endsAt'], 'event.endsAt'),
            );
          },
        )
        .toList(growable: false);
  }

  List<FriendEventPreview> _parseFriendEvents(List<dynamic> raw) {
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) {
          final categoryRaw = map['category'];
          if (categoryRaw is! Map) {
            throw StateError('Invalid friend event category payload.');
          }
          final category = Map<String, dynamic>.from(categoryRaw);
          return FriendEventPreview(
            id: _requiredString(map['id'], 'id'),
            title: _requiredString(map['title'], 'title'),
            startsAt: _requiredDateTime(map['startsAt'], 'startsAt'),
            endsAt: _requiredDateTime(map['endsAt'], 'endsAt'),
            categoryName: _requiredString(category['title'], 'category.title'),
            categoryColor: _requiredString(category['color'], 'category.color'),
          );
        })
        .toList(growable: false)
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  List<SharedHabitPreview> _parseSharedHabits(List<dynamic> raw) {
    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (map) => SharedHabitPreview(
            sharedHabitPairId: _requiredString(
              map['sharedHabitPairId'],
              'sharedHabitPairId',
            ),
            habitId: _requiredString(map['habitId'], 'habitId'),
            title: _requiredString(map['title'], 'title'),
            color: _requiredString(map['color'], 'color'),
            streakDays: _requiredInt(map['streakDays'], 'streakDays'),
            youCompletedToday: _requiredBool(
              map['youCompletedToday'],
              'youCompletedToday',
            ),
            friendCompletedToday: _requiredBool(
              map['friendCompletedToday'],
              'friendCompletedToday',
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<_ListAccessResult> _getListOrForbidden(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        path,
        queryParameters: queryParameters,
      );
      final raw = response.data;
      if (raw is! List) {
        throw StateError('Invalid list payload.');
      }
      return _ListAccessResult(
        allowed: true,
        listData: raw,
      );
    } on DioException catch (error, stackTrace) {
      if (error.response?.statusCode == 403) {
        AppLogger.w('Access denied for $path');
        return const _ListAccessResult(
          allowed: false,
          listData: <dynamic>[],
        );
      }
      AppLogger.e('Request failed for $path', error, stackTrace);
      rethrow;
    }
  }

  FriendFeedType _parseFeedType(String type) {
    return switch (type) {
      'friend_added' => FriendFeedType.friendAdded,
      'habit_streak' => FriendFeedType.habitStreak,
      'habit_created' => FriendFeedType.habitCreated,
      'shared_habit_reminder' => FriendFeedType.sharedHabitReminder,
      _ => throw StateError('Unsupported feed type: $type'),
    };
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _requiredString(dynamic value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  bool _requiredBool(dynamic value, String fieldName) {
    if (value is bool) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  int _requiredInt(dynamic value, String fieldName) {
    if (value is int) {
      return value;
    }
    throw StateError('Invalid "$fieldName" field.');
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return null;
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

  String _formatDate(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }
}

class _ListAccessResult {
  const _ListAccessResult({
    required this.allowed,
    required this.listData,
  });

  final bool allowed;
  final List<dynamic> listData;
}
