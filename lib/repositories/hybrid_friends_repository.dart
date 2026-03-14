import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import 'friends_repository.dart';
import 'in_memory_app_store.dart';

class HybridFriendsRepository implements FriendsRepository {
  HybridFriendsRepository({
    required FriendsRepository remoteRepository,
    required InMemoryAppStore store,
  }) : _remoteRepository = remoteRepository,
       _store = store;

  final FriendsRepository _remoteRepository;
  final InMemoryAppStore _store;

  final Map<String, String> _friendUserIdByAnyId = {};
  final Map<String, String> _friendNameByUserId = {};

  @override
  Future<List<FriendListItem>> fetchFriends({required String userId}) async {
    final remoteItems = await _remoteRepository.fetchFriends(userId: userId);
    final localItems = _store.friendsForUser(userId).toList(growable: false);

    final byUserId = <String, FriendListItem>{};

    for (final item in remoteItems) {
      byUserId[item.userId] = item;
      _friendUserIdByAnyId[item.id] = item.userId;
      _friendUserIdByAnyId[item.userId] = item.userId;
      _friendNameByUserId[item.userId] = item.name;
    }
    for (final item in localItems) {
      byUserId[item.userId] = item;
      _friendUserIdByAnyId[item.id] = item.userId;
      _friendUserIdByAnyId[item.userId] = item.userId;
      _friendNameByUserId[item.userId] = item.name;
    }

    final merged = byUserId.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    return merged;
  }

  @override
  Future<List<FriendInviteItem>> fetchIncomingInvites({
    required String userId,
  }) async {
    final remoteItems = await _remoteRepository.fetchIncomingInvites(
      userId: userId,
    );
    final localItems = _store.incomingInvitesForUser(userId).toList(
      growable: false,
    );

    final byId = <String, FriendInviteItem>{};

    for (final item in remoteItems) {
      byId[item.id] = item;
    }
    for (final item in localItems) {
      byId[item.id] = item;
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

    return merged;
  }

  @override
  Future<void> connectFriend({
    required String userId,
    required String friendId,
  }) async {
    _store.connectFriend(userId: userId, friendId: friendId);
  }

  @override
  Future<void> sendInviteByEmail({
    required String userId,
    required String email,
  }) async {
    try {
      await _remoteRepository.sendInviteByEmail(userId: userId, email: email);
    } catch (_) {
      // Для демо не падаем.
    }

    _store.sendInviteByEmail(userId: userId, email: email);
  }

  @override
  Future<void> acceptInvite({
    required String userId,
    required String inviteId,
  }) async {
    try {
      await _remoteRepository.acceptInvite(userId: userId, inviteId: inviteId);
    } catch (_) {
      // Для демо не падаем.
    }

    _store.acceptInvite(userId: userId, inviteId: inviteId);
  }

  @override
  Future<void> createSharedHabit({
    required String userId,
    required String friendId,
    required String title,
  }) async {
    final friendUserId = _friendUserIdByAnyId[friendId] ?? friendId;
    final localFriendId = _ensureLocalFriend(
      ownerUserId: userId,
      friendUserId: friendUserId,
    );

    try {
      await _remoteRepository.createSharedHabit(
        userId: userId,
        friendId: friendUserId,
        title: title,
      );
    } catch (_) {
      // Для демо не падаем.
    }

    _store.createSharedHabit(
      userId: userId,
      friendId: localFriendId,
      title: title,
    );
  }

  String _ensureLocalFriend({
    required String ownerUserId,
    required String friendUserId,
  }) {
    final items = _store.friendsByUser[ownerUserId] ?? const <FriendListItem>[];
    for (final item in items) {
      if (item.userId == friendUserId) {
        return item.id;
      }
    }

    final generatedId = 'friend_${_store.nextFriendId++}';
    final name = _friendNameByUserId[friendUserId] ?? 'Друг';

    final created = FriendListItem(
      id: generatedId,
      userId: friendUserId,
      name: name,
      status: FriendRelationStatus.connected,
      streakDays: 0,
      sharedHabitTitle: null,
    );

    _store.friendsByUser = {
      ..._store.friendsByUser,
      ownerUserId: [...items, created],
    };

    return generatedId;
  }
}
