import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/friends/friends_cubit.dart';
import '../../cubits/friends/friends_state.dart';
import '../../models/friend_invite_item.dart';
import '../../models/friend_list_item.dart';
import '../../repositories/friends_repository.dart';
import '../../widgets/appear_animations.dart';
import '../home/home_screen.dart';

const _kAccentBlue = Color(0xFF0277BD);

ButtonStyle _dialogTextButtonStyle() {
  return TextButton.styleFrom(foregroundColor: _kAccentBlue);
}

ButtonStyle _dialogFilledButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: _kAccentBlue,
    foregroundColor: Colors.white,
  );
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({
    super.key,
    this.currentUserId = 'user_me',
    FriendsRepository? repository,
  }) : _repository = repository;

  final String currentUserId;
  final FriendsRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        _repository ?? RepositoryProvider.of<FriendsRepository>(context);

    return BlocProvider(
      create: (_) =>
          FriendsCubit(repository: repository, userId: currentUserId)
            ..loadFriends(),
      child: const _FriendsView(),
    );
  }
}

class _FriendsView extends StatelessWidget {
  const _FriendsView();

  Future<void> _openFriendHome(
    BuildContext context,
    FriendListItem item,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(
          currentUserId: item.userId,
          showFriendsBlock: false,
          canToggleTasks: false,
          showAppBar: true,
          appBarTitle: item.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsCubit, FriendsState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          context.read<FriendsCubit>().clearError();
        }

        final info = state.infoMessage;
        if (info != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(info)));
          context.read<FriendsCubit>().clearInfo();
        }
      },
      builder: (context, state) {
        final isInitialLoad =
            state.status == FriendsStatus.loading && state.items.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          body: SafeArea(
            child: ScreenAppear(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    color: _kAccentBlue,
                    child: _Header(
                      inviteCount: state.incomingInvites.length,
                      onInvitesTap: () =>
                          _openInvitesDialog(context, state.incomingInvites),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => context.read<FriendsCubit>().loadFriends(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        children: [
                          if (isInitialLoad)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (state.items.isEmpty)
                            const DelayedAppear(
                              delay: Duration(milliseconds: 70),
                              child: _EmptyFriendsCard(),
                            )
                          else
                            ...state.items.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: DelayedAppear(
                                  delay: Duration(
                                    milliseconds: 70 + entry.key * 40,
                                  ),
                                  child: _FriendCard(
                                    item: entry.value,
                                    onTap: () =>
                                        _openFriendHome(context, entry.value),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          DelayedAppear(
                            delay: Duration(
                              milliseconds: 90 + state.items.length * 35,
                            ),
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => _openInviteByEmailDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBEBEBE),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Добавить друга',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInviteByEmailDialog(BuildContext context) async {
    final controller = TextEditingController();
    final cubit = context.read<FriendsCubit>();

    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Пригласить друга'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Введите email'),
            ),
            actions: [
              TextButton(
                style: _dialogTextButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: _dialogFilledButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Отправить инвайт'),
              ),
            ],
          );
        },
      );

      if (shouldSend == true) {
        await cubit.sendInviteByEmail(controller.text);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openInvitesDialog(
    BuildContext context,
    List<FriendInviteItem> invites,
  ) async {
    final cubit = context.read<FriendsCubit>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Входящие заявки'),
          content: SizedBox(
            width: 360,
            child: invites.isEmpty
                ? const Text('Пока нет входящих заявок.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: invites
                        .map(
                          (invite) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InviteRow(
                              invite: invite,
                              onAccept: () async {
                                await cubit.acceptInvite(invite.id);
                                if (context.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          actions: [
            TextButton(
              style: _dialogTextButtonStyle(),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.inviteCount, required this.onInvitesTap});

  final int inviteCount;
  final VoidCallback onInvitesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Друзья',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Заявки',
              onPressed: onInvitesTap,
              icon: const Icon(
                Icons.notifications_none,
                size: 30,
                color: Colors.white,
              ),
            ),
            if (inviteCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    '$inviteCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.onAccept});

  final FriendInviteItem invite;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.fromName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invite.fromEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4D4D4D),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: _dialogFilledButtonStyle(),
            onPressed: onAccept,
            child: const Text('Принять'),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.item, required this.onTap});

  final FriendListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x66000000)),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4D4D4D),
                      ),
                    ),
                  ],
                ),
              ),
              _TrailingAction(item: item),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (!item.isConnected) {
      return 'Можно добавить в друзья';
    }
    if (!item.hasSharedHabit) {
      return 'Совместной привычки пока нет';
    }
    return 'Совместная привычка «${item.sharedHabitTitle}»';
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({required this.item});

  final FriendListItem item;

  @override
  Widget build(BuildContext context) {
    if (!item.isConnected) {
      return IconButton(
        tooltip: 'Добавить в друзья',
        onPressed: () => context.read<FriendsCubit>().connectFriend(item.id),
        icon: const Icon(Icons.person_add, size: 30),
      );
    }

    if (!item.hasSharedHabit) {
      return IconButton(
        tooltip: 'Создать совместную привычку',
        onPressed: () => _openCreateSharedHabitDialog(context),
        icon: const Icon(Icons.add_box, size: 32),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department, size: 26),
        Text(
          item.streakLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _openCreateSharedHabitDialog(BuildContext context) async {
    final controller = TextEditingController();
    final cubit = context.read<FriendsCubit>();

    try {
      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Совместная привычка: ${item.name}'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Название привычки'),
            ),
            actions: [
              TextButton(
                style: _dialogTextButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: _dialogFilledButtonStyle(),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Создать'),
              ),
            ],
          );
        },
      );

      if (shouldCreate == true) {
        await cubit.createSharedHabit(
          friendId: item.id,
          title: controller.text,
        );
      }
    } finally {
      controller.dispose();
    }
  }
}

class _EmptyFriendsCard extends StatelessWidget {
  const _EmptyFriendsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: const Text('Список друзей пока пуст. Добавьте первого друга.'),
    );
  }
}