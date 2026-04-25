import '../core/api_client.dart';
import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import 'friends_repository.dart';

class ApiFriendsRepository implements FriendsRepository {
  ApiFriendsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<FriendListItem>> fetchFriends({required String userId}) async {
    final response = await _apiClient.dio.get('/me/friends');
    final rawList = response.data;

    if (rawList is! List) {
      throw StateError('Некорректный формат списка друзей.');
    }

    final result = <FriendListItem>[];

    for (final item in rawList) {
      final map = Map<String, dynamic>.from(item as Map);
      final user = Map<String, dynamic>.from(map['user'] as Map);
      final otherUserId = user['id'] as String;
      final handle = (user['handle'] as String?)?.trim();
      final friendshipId = otherUserId;

      result.add(
        FriendListItem(
          id: friendshipId,
          userId: otherUserId,
          name: (handle == null || handle.isEmpty) ? 'Друг' : handle,
          status: FriendRelationStatus.connected,
          streakDays: (map['sharedHabitsCount'] as int?) ?? 0,
          sharedHabitTitle: null,
        ),
      );
    }

    return result;
  }

  @override
  Future<List<FriendInviteItem>> fetchIncomingInvites({
    required String userId,
  }) async {
    final response = await _apiClient.dio.get('/me/friend-invites');
    final rawList = response.data;

    if (rawList is! List) {
      throw StateError('Некорректный формат списка инвайтов.');
    }

    final result = <FriendInviteItem>[];

    for (final item in rawList) {
      final map = Map<String, dynamic>.from(item as Map);
      final sender = Map<String, dynamic>.from(map['sender'] as Map);

      final inviteId = map['id'] as String;
      final fromUserId = sender['id'] as String;
      final fromHandle = (sender['handle'] as String?)?.trim() ?? 'Пользователь';

      result.add(
        FriendInviteItem(
          id: inviteId,
          fromUserId: fromUserId,
          fromName: fromHandle,
          fromEmail: '@$fromHandle',
          sentAt: DateTime.parse(map['createdAt'] as String),
        ),
      );
    }

    return result;
  }

  @override
  Future<void> connectFriend({
    required String userId,
    required String friendId,
  }) async {
    throw UnimplementedError(
      'connectFriend не поддерживается API-контрактом в текущем виде.',
    );
  }

  @override
  Future<void> sendInviteByEmail({
    required String userId,
    required String email,
  }) async {
    final handle = _extractHandle(email);
    await _apiClient.dio.post(
      '/me/friend-invites',
      data: {
        'handle': handle,
      },
    );
  }

  @override
  Future<void> acceptInvite({
    required String userId,
    required String inviteId,
  }) async {
    await _apiClient.dio.post('/me/friend-invites/$inviteId/accept');
  }

  @override
  Future<void> createSharedHabit({
    required String userId,
    required String friendId,
    required String title,
  }) async {
    await _apiClient.dio.post(
      '/me/shared-habits',
      data: {
        'friendUserId': friendId,
        'title': title.trim(),
        'color': '#34C759',
        'scheduleType': 'daily',
        'intervalDays': 1,
        'weekdays': <int>[],
      },
    );
  }

  String _extractHandle(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.contains('@')) {
      return trimmed.split('@').first.trim();
    }
    return trimmed;
  }
}
