import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_logger.dart';
import '../../repositories/friends_repository.dart';
import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit({
    required FriendsRepository repository,
  }) : _repository = repository,
       super(FriendsState.initial());

  final FriendsRepository _repository;

  Future<void> loadFriends() async {
    AppLogger.i('FriendsCubit.loadFriends started');
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
      AppLogger.i('FriendsCubit.loadFriends completed');
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.loadFriends failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось загрузить данные друзей.',
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
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.loadMoreFeed failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось загрузить новости друзей.',
        ),
      );
    }
  }

  Future<void> sendInviteByHandle(String handle) async {
    try {
      await _repository.sendInviteByHandle(handle: handle);
      emit(
        state.copyWith(
          infoMessage: 'Заявка отправлена.',
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.sendInviteByHandle failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось отправить заявку.',
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
          infoMessage: 'Друг добавлен.',
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.acceptInvite failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось принять заявку в друзья.',
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
          infoMessage: 'Заявка отклонена.',
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.rejectInvite failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось отклонить заявку в друзья.',
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
          infoMessage: 'Друг удалён.',
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.removeFriend failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось удалить друга.',
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
    } catch (error, stackTrace) {
      AppLogger.e('FriendsCubit.refreshFriendPage failed', error, stackTrace);
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось загрузить профиль друга.',
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
