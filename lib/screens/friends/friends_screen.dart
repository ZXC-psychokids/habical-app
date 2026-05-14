import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/friends/friends_cubit.dart';
import '../../cubits/friends/friends_state.dart';
import '../../cubits/navigation/navigation_cubit.dart';
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

class _FriendsView extends StatefulWidget {
  const _FriendsView({required this.repository});

  final FriendsRepository repository;

  @override
  State<_FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<_FriendsView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        final isInitialLoading = state.status == FriendsStatus.loading &&
            state.items.isEmpty &&
            state.incomingInvites.isEmpty;

        final sortedFriends = _sortFriends(state.items);
        final filteredInvites = _filterInvites(state.incomingInvites, _query);
        final filteredFriends = _filterFriends(sortedFriends, _query);

        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '\u0414\u0440\u0443\u0437\u044c\u044f',
                      style: TextStyle(
                        fontSize: 48 / 1.56,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0277BC),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(29, 39, 51, 0.30),
                          offset: Offset(0, 4),
                          blurRadius: 10.1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value.trim()),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF000000),
                          size: 24,
                        ),
                        contentPadding: EdgeInsets.only(top: 8, right: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => context.read<FriendsCubit>().loadFriends(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          if (isInitialLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0277BC),
                                ),
                              ),
                            ),
                          ...filteredInvites.map(
                            (invite) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InviteCard(
                                invite: invite,
                                onAccept: () async {
                                  await context
                                      .read<FriendsCubit>()
                                      .acceptInvite(invite.id);
                                },
                                onReject: () async {
                                  await context
                                      .read<FriendsCubit>()
                                      .rejectInvite(invite.id);
                                },
                              ),
                            ),
                          ),
                          ...filteredFriends.map(
                            (friend) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FriendCard(
                                friend: friend,
                                onTap: () => _openFriendPage(context, friend),
                              ),
                            ),
                          ),
                          if (filteredInvites.isEmpty && filteredFriends.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(
                                child: Text(
                                  '\u041d\u0438\u0447\u0435\u0433\u043e \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u043e',
                                  style: TextStyle(
                                    color: Color(0xFFABABAB),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _openInviteDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0277BC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0434\u0440\u0443\u0433\u0430',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
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

  List<FriendListItem> _sortFriends(List<FriendListItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      if (a.sharedHabitsCount != b.sharedHabitsCount) {
        return b.sharedHabitsCount.compareTo(a.sharedHabitsCount);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  List<FriendInviteItem> _filterInvites(List<FriendInviteItem> invites, String query) {
    if (query.isEmpty) {
      return invites;
    }
    final q = query.toLowerCase();
    return invites
        .where((item) => item.fromName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<FriendListItem> _filterFriends(List<FriendListItem> friends, String query) {
    if (query.isEmpty) {
      return friends;
    }
    final q = query.toLowerCase();
    return friends
        .where((item) => item.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _openFriendPage(BuildContext context, FriendListItem item) async {
    final navigationCubit = context.read<NavigationCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: navigationCubit,
          child: FriendPageScreen(
            friendUserId: item.userId,
            friendsRepository: widget.repository,
          ),
        ),
      ),
    );
  }

  Future<void> _openInviteDialog(BuildContext context) async {
    final cubit = context.read<FriendsCubit>();
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0434\u0440\u0443\u0433\u0430',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '@handle',
                    hintStyle: const TextStyle(color: Color(0xFFABABAB)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB5B5B5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF0277BC),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ButtonStyle(
                        foregroundColor: const WidgetStatePropertyAll(
                          Color(0xFF0277BC),
                        ),
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return const Color(0x220277BC);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return const Color(0x140277BC);
                          }
                          return Colors.transparent;
                        }),
                      ),
                      child: const Text(
                        '\u041e\u0442\u043c\u0435\u043d\u0430',
                        style: TextStyle(color: Color(0xFF0277BC)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () async {
                        final handle = controller.text.trim();
                        if (handle.isEmpty) {
                          return;
                        }
                        await cubit.sendInviteByHandle(handle);
                        if (context.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0277BC),
                      ),
                      child: const Text('\u041e\u0442\u043f\u0440\u0430\u0432\u0438\u0442\u044c'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onTap,
  });

  final FriendListItem friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = friend.sharedHabitsCount > 0
        ? '\u0421\u043e\u0432\u043c\u0435\u0441\u0442\u043d\u044b\u0445 \u043f\u0440\u0438\u0432\u044b\u0447\u0435\u043a ${friend.sharedHabitsCount}'
        : '\u0421\u043e\u0432\u043c\u0435\u0441\u0442\u043d\u044b\u0445 \u043f\u0440\u0438\u0432\u044b\u0447\u0435\u043a \u043d\u0435\u0442';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(29, 39, 51, 0.30),
              offset: Offset(0, 4),
              blurRadius: 10.1,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0277BC),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 16 / 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFABABAB),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final FriendInviteItem invite;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0277BC),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(29, 39, 51, 0.30),
            offset: Offset(0, 4),
            blurRadius: 10.1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF0277BC),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.fromName,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16 / 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '\u0412\u0445\u043e\u0434\u044f\u0449\u0430\u044f \u0437\u0430\u044f\u0432\u043a\u0430',
                  style: TextStyle(
                    color: Color(0xFFD6EEFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _CircleActionButton(
            icon: Icons.close_rounded,
            onTap: onReject,
          ),
          const SizedBox(width: 8),
          _CircleActionButton(
            icon: Icons.add_rounded,
            onTap: onAccept,
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async => onTap(),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icon,
            size: 22,
            color: const Color(0xFF0277BC),
          ),
        ),
      ),
    );
  }
}
