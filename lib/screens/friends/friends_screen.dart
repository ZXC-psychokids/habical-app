import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/friends/friends_cubit.dart';
import '../../cubits/friends/friends_state.dart';
import '../../models/friend_feed_item.dart';
import '../../models/friend_invite_item.dart';
import '../../models/friend_list_item.dart';
import '../../repositories/friends_repository.dart';
import 'friend_page_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({
    super.key,
    FriendsRepository? repository,
  }) : _repository = repository;

  final FriendsRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        _repository ?? RepositoryProvider.of<FriendsRepository>(context);

    return BlocProvider(
      create: (_) => FriendsCubit(repository: repository)..loadFriends(),
      child: _FriendsView(repository: repository),
    );
  }
}

class _FriendsView extends StatelessWidget {
  const _FriendsView({required this.repository});

  final FriendsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendsCubit, FriendsState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
          context.read<FriendsCubit>().clearError();
        }

        final info = state.infoMessage;
        if (info != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(info)),
          );
          context.read<FriendsCubit>().clearInfo();
        }
      },
      builder: (context, state) {
        final isLoading =
            state.status == FriendsStatus.loading &&
            state.items.isEmpty &&
            state.feedItems.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Friends'),
            actions: [
              IconButton(
                onPressed: () => _openInvitesDialog(context, state.incomingInvites),
                icon: const Icon(Icons.mail_outline),
                tooltip: 'Incoming invites',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<FriendsCubit>().loadFriends(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                _InviteByHandleCard(),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Friends'),
                if (state.items.isEmpty)
                  const Text('No friends yet.')
                else
                  ...state.items.map(
                    (friend) => _FriendTile(
                      friend: friend,
                      onOpen: () => _openFriendPage(context, friend),
                      onRemove: () =>
                          context.read<FriendsCubit>().removeFriend(friend.userId),
                    ),
                  ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Feed'),
                if (state.feedItems.isEmpty)
                  const Text('Feed is empty.')
                else
                  ...state.feedItems.map(_FeedTile.new),
                if (state.nextFeedCursor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton(
                      onPressed: () => context.read<FriendsCubit>().loadMoreFeed(),
                      child: const Text('Load more'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
          title: const Text('Incoming invites'),
          content: SizedBox(
            width: 360,
            child: invites.isEmpty
                ? const Text('No incoming invites.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: invites
                        .map(
                          (invite) => _InviteRow(
                            invite: invite,
                            onAccept: () async {
                              await cubit.acceptInvite(invite.id);
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                            onReject: () async {
                              await cubit.rejectInvite(invite.id);
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFriendPage(BuildContext context, FriendListItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendPageScreen(
          friendUserId: item.userId,
          friendsRepository: repository,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InviteByHandleCard extends StatefulWidget {
  @override
  State<_InviteByHandleCard> createState() => _InviteByHandleCardState();
}

class _InviteByHandleCardState extends State<_InviteByHandleCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send invite by handle',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'friend_handle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  await context.read<FriendsCubit>().sendInviteByHandle(
                    _controller.text,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  _controller.clear();
                },
                child: const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.onOpen,
    required this.onRemove,
  });

  final FriendListItem friend;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(Icons.person_outline),
        title: Text(friend.name),
        subtitle: Text(friend.userId),
        trailing: IconButton(
          tooltip: 'Remove',
          onPressed: onRemove,
          icon: const Icon(Icons.person_remove_outlined),
        ),
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final FriendInviteItem invite;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.fromName),
                Text(
                  invite.fromEmail,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onReject, child: const Text('Reject')),
          FilledButton(onPressed: onAccept, child: const Text('Accept')),
        ],
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile(this.item);

  final FriendFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.newspaper_outlined),
        title: Text(item.toPresentationText()),
        subtitle: Text(item.createdAt.toLocal().toString()),
      ),
    );
  }
}
