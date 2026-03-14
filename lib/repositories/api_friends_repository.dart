import '../core/api_client.dart';
import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import '../models/habit.dart';
import 'friends_repository.dart';

class ApiFriendsRepository implements FriendsRepository {
  ApiFriendsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<FriendListItem>> fetchFriends({required String userId}) async {
    final response = await _apiClient.dio.get('/users/$userId/friends');
    final rawList = response.data;

    if (rawList is! List) {
      throw StateError('Некорректный формат списка друзей.');
    }

    final result = <FriendListItem>[];

    for (final item in rawList) {
      final map = Map<String, dynamic>.from(item as Map);

      final user1Id = map['user1Id'] as String;
      final user2Id = map['user2Id'] as String;
      final friendshipId = map['id'] as String;

      final otherUserId = user1Id == userId ? user2Id : user1Id;
      final otherUser = await _fetchUser(otherUserId);

      result.add(
        FriendListItem(
          id: friendshipId,
          userId: otherUserId,
          name: otherUser.name,
          status: FriendRelationStatus.connected,
          streakDays: 0,
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
    final response = await _apiClient.dio.get('/users/$userId/friend-invites');
    final rawList = response.data;

    if (rawList is! List) {
      throw StateError('Некорректный формат списка инвайтов.');
    }

    final result = <FriendInviteItem>[];

    for (final item in rawList) {
      final map = Map<String, dynamic>.from(item as Map);

      final inviteId = map['id'] as String;
      final fromUserId = map['user1Id'] as String;
      final fromUser = await _fetchUser(fromUserId);

      result.add(
        FriendInviteItem(
          id: inviteId,
          fromUserId: fromUserId,
          fromName: fromUser.name,
          fromEmail: '$fromUserId@example.com',
          sentAt: DateTime.now(),
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
    await _apiClient.dio.post(
      '/users/$userId/friend-invites',
      data: {
        'email': email.trim(),
      },
    );
  }

  @override
  Future<void> acceptInvite({
    required String userId,
    required String inviteId,
  }) async {
    await _apiClient.dio.post('/friend-invites/$inviteId/accept');
  }

  @override
  Future<void> createSharedHabit({
    required String userId,
    required String friendId,
    required String title,
  }) async {
    await _apiClient.dio.post(
      '/users/$userId/shared-habits',
      data: {
        'secondUserId': friendId,
        'title': title.trim(),
        'periodicityDays': 1,
        'initialStreakDays': 0,
      },
    );
  }

  Future<_ApiUser> _fetchUser(String userId) async {
    final response = await _apiClient.dio.get('/users/$userId');
    final raw = response.data;

    if (raw is! Map) {
      throw StateError('Некорректный формат пользователя.');
    }

    final map = Map<String, dynamic>.from(raw);
    return _ApiUser(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }
}

class _ApiUser {
  const _ApiUser({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}