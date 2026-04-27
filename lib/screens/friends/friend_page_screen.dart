import 'package:flutter/material.dart';

import '../../models/friend_page_data.dart';
import '../../repositories/friends_repository.dart';

class FriendPageScreen extends StatefulWidget {
  const FriendPageScreen({
    super.key,
    required this.friendUserId,
    required this.friendsRepository,
  });

  final String friendUserId;
  final FriendsRepository friendsRepository;

  @override
  State<FriendPageScreen> createState() => _FriendPageScreenState();
}

class _FriendPageScreenState extends State<FriendPageScreen> {
  bool _isLoading = true;
  String? _error;
  FriendPageData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.friendsRepository.fetchFriendPage(
        userId: widget.friendUserId,
        day: DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = 'Failed to load friend page.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      appBar: AppBar(title: const Text('Friend Page')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (data != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(data.profile.handle),
                  subtitle: Text(data.profile.id),
                ),
              ),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Tasks'),
              ...data.tasks.map(
                (task) => CheckboxListTile(
                  value: task.isCompleted,
                  onChanged: null,
                  title: Text(task.title),
                  dense: true,
                ),
              ),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Events'),
              ...data.events.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.startsAt.toLocal()} - ${event.endsAt.toLocal()}',
                  ),
                  trailing: Text(event.categoryName),
                ),
              ),
              const SizedBox(height: 12),
              _SectionHeader(title: 'Shared Habits'),
              ...data.sharedHabits.map(
                (habit) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(habit.title),
                  subtitle: Text('Streak: ${habit.streakDays}'),
                  trailing: Text(
                    '${habit.youCompletedToday ? 'You' : '-'} / ${habit.friendCompletedToday ? 'Friend' : '-'}',
                  ),
                ),
              ),
            ],
          ],
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
