import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/friends_repository.dart';
import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit({
    required FriendsRepository repository,
  }) : _repository = repository,
       super(FriendsState.initial());

  final FriendsRepository _repository;

  Future<void> loadFriends() async {
    emit(
      state.copyWith(
        status: FriendsStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      final friendsFuture = _repository.fetchFriends();
      final invitesFuture = _repository.fetchIncomingInvites();
      final feedFuture = _repository.fetchFeed(limit: 20);

      final friends = await friendsFuture;
      final invites = await invitesFuture;
      final feedPage = await feedFuture;

      emit(
        state.copyWith(
          status: FriendsStatus.loaded,
          items: friends,
          incomingInvites: invites,
          feedItems: feedPage.items,
          nextFeedCursor: feedPage.nextCursor,
          clearError: true,
          clearInfo: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to load friends data.',
        ),
      );
    }
  }

  Future<void> loadMoreFeed() async {
    final cursor = state.nextFeedCursor;
    if (cursor == null) {
      return;
    }

    try {
      final page = await _repository.fetchFeed(limit: 20, cursor: cursor);
      emit(
        state.copyWith(
          feedItems: [...state.feedItems, ...page.items],
          nextFeedCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to load more feed items.',
        ),
      );
    }
  }

  Future<void> sendInviteByHandle(String handle) async {
    try {
      await _repository.sendInviteByHandle(handle: handle);
      emit(
        state.copyWith(
          infoMessage: 'Invite sent.',
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to send invite.',
        ),
      );
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    try {
      await _repository.acceptInvite(inviteId: inviteId);
      await loadFriends();
      emit(
        state.copyWith(
          infoMessage: 'Invite accepted.',
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to accept invite.',
        ),
      );
    }
  }

  Future<void> rejectInvite(String inviteId) async {
    try {
      await _repository.rejectInvite(inviteId: inviteId);
      await loadFriends();
      emit(
        state.copyWith(
          infoMessage: 'Invite rejected.',
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to reject invite.',
        ),
      );
    }
  }

  Future<void> removeFriend(String friendUserId) async {
    try {
      await _repository.removeFriend(friendUserId: friendUserId);
      await loadFriends();
      emit(
        state.copyWith(
          infoMessage: 'Friend removed.',
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to remove friend.',
        ),
      );
    }
  }

  Future<void> refreshFriendPage(String friendUserId) async {
    try {
      await _repository.fetchFriendPage(
        userId: friendUserId,
        day: DateTime.now(),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Failed to load friend page.',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void clearInfo() {
    emit(state.copyWith(clearInfo: true));
  }
}
