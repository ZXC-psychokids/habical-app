import '../models/friend_feed_item.dart';
import '../models/friend_invite_item.dart';
import '../models/friend_list_item.dart';
import '../models/friend_page_data.dart';

abstract class FriendsRepository {
  Future<List<FriendListItem>> fetchFriends();

  Future<List<FriendInviteItem>> fetchIncomingInvites();

  Future<void> sendInviteByHandle({
    required String handle,
  });

  Future<void> acceptInvite({
    required String inviteId,
  });

  Future<void> rejectInvite({
    required String inviteId,
  });

  Future<void> removeFriend({
    required String friendUserId,
  });

  Future<FriendFeedPage> fetchFeed({
    int limit,
    String? cursor,
  });

  Future<FriendPageData> fetchFriendPage({
    required String userId,
    required DateTime day,
  });
}
