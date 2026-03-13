import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import 'in_memory_app_store.dart';

abstract class FriendsRepository {
  Future<List<FriendListItem>> fetchFriends({required String userId});

  Future<List<FriendInviteItem>> fetchIncomingInvites({required String userId});

  Future<void> connectFriend({
    required String userId,
    required String friendId,
  });

  Future<void> sendInviteByEmail({
    required String userId,
    required String email,
  });

  Future<void> acceptInvite({
    required String userId,
    required String inviteId,
  });

  Future<void> createSharedHabit({
    required String userId,
    required String friendId,
    required String title,
  });
}

class InMemoryFriendsRepository implements FriendsRepository {
  InMemoryFriendsRepository({DateTime? now, InMemoryAppStore? store})
    : _store = store ?? InMemoryAppStore(now: now);

  final InMemoryAppStore _store;

  @override
  Future<List<FriendListItem>> fetchFriends({required String userId}) async {
    return _store.friendsForUser(userId).toList(growable: false);
  }

  @override
  Future<List<FriendInviteItem>> fetchIncomingInvites({
    required String userId,
  }) async {
    return _store.incomingInvitesForUser(userId).toList(growable: false);
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
    _store.sendInviteByEmail(userId: userId, email: email);
  }

  @override
  Future<void> acceptInvite({
    required String userId,
    required String inviteId,
  }) async {
    _store.acceptInvite(userId: userId, inviteId: inviteId);
  }

  @override
  Future<void> createSharedHabit({
    required String userId,
    required String friendId,
    required String title,
  }) async {
    _store.createSharedHabit(
      userId: userId,
      friendId: friendId,
      title: title,
    );
  }
}
