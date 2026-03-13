import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/friends_repository.dart';
import 'friends_state.dart';

class FriendsCubit extends Cubit<FriendsState> {
  FriendsCubit({
    required FriendsRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId,
       super(FriendsState.initial());

  final FriendsRepository _repository;
  final String _userId;

  Future<void> loadFriends() async {
    emit(
      state.copyWith(
        status: FriendsStatus.loading,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      final items = await _repository.fetchFriends(userId: _userId);
      final invites = await _repository.fetchIncomingInvites(userId: _userId);
      emit(
        state.copyWith(
          status: FriendsStatus.loaded,
          items: items,
          incomingInvites: invites,
          clearError: true,
          clearInfo: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось загрузить друзей.',
        ),
      );
    }
  }

  Future<void> connectFriend(String friendId) async {
    try {
      await _repository.connectFriend(userId: _userId, friendId: friendId);
      await loadFriends();
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось добавить друга.',
        ),
      );
    }
  }

  Future<void> sendInviteByEmail(String email) async {
    try {
      await _repository.sendInviteByEmail(userId: _userId, email: email);
      emit(
        state.copyWith(
          infoMessage: 'Инвайт отправлен. Ожидаем подтверждения.',
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось отправить инвайт.',
        ),
      );
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    try {
      await _repository.acceptInvite(userId: _userId, inviteId: inviteId);
      await loadFriends();
      emit(
        state.copyWith(
          infoMessage: 'Друг добавлен.',
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось принять заявку.',
        ),
      );
    }
  }

  Future<void> createSharedHabit({
    required String friendId,
    required String title,
  }) async {
    try {
      await _repository.createSharedHabit(
        userId: _userId,
        friendId: friendId,
        title: title,
      );
      await loadFriends();
    } catch (_) {
      emit(
        state.copyWith(
          status: FriendsStatus.failure,
          errorMessage: 'Не удалось создать совместную привычку.',
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
