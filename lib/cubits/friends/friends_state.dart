import '../../models/friend_feed_item.dart';
import '../../models/friend_invite_item.dart';
import '../../models/friend_list_item.dart';

enum FriendsStatus { initial, loading, loaded, failure }

class FriendsState {
  const FriendsState({
    required this.status,
    required this.items,
    required this.incomingInvites,
    required this.feedItems,
    required this.nextFeedCursor,
    this.errorMessage,
    this.infoMessage,
  });

  factory FriendsState.initial() {
    return const FriendsState(
      status: FriendsStatus.initial,
      items: <FriendListItem>[],
      incomingInvites: <FriendInviteItem>[],
      feedItems: <FriendFeedItem>[],
      nextFeedCursor: null,
    );
  }

  final FriendsStatus status;
  final List<FriendListItem> items;
  final List<FriendInviteItem> incomingInvites;
  final List<FriendFeedItem> feedItems;
  final String? nextFeedCursor;
  final String? errorMessage;
  final String? infoMessage;

  FriendsState copyWith({
    FriendsStatus? status,
    List<FriendListItem>? items,
    List<FriendInviteItem>? incomingInvites,
    List<FriendFeedItem>? feedItems,
    String? nextFeedCursor,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
    bool clearNextFeedCursor = false,
  }) {
    return FriendsState(
      status: status ?? this.status,
      items: items ?? this.items,
      incomingInvites: incomingInvites ?? this.incomingInvites,
      feedItems: feedItems ?? this.feedItems,
      nextFeedCursor: clearNextFeedCursor
          ? null
          : (nextFeedCursor ?? this.nextFeedCursor),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
