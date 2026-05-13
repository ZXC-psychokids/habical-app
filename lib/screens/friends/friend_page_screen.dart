import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/friend_page_data.dart';
import '../../repositories/friends_repository.dart';
import '../../repositories/habits_repository.dart';
import '../habits/shared_habit_details_screen.dart';

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
  bool _isCreatingSharedHabit = false;
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

  Future<void> _createSharedHabit() async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая совместная привычка'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название привычки',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(titleController.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isCreatingSharedHabit = true;
    });
    try {
      final habitsRepository = context.read<HabitsRepository>();
      await habitsRepository.createSharedHabit(
        friendUserId: widget.friendUserId,
        title: title,
        color: '#0A84FF',
        scheduleType: 'daily',
        intervalDays: 1,
        weekdays: const <int>[],
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Совместная привычка создана')),
      );
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось создать совместную привычку')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSharedHabit = false;
        });
      }
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
              Row(
                children: [
                  const Expanded(child: _SectionHeader(title: 'Shared Habits')),
                  TextButton(
                    onPressed: _isCreatingSharedHabit ? null : _createSharedHabit,
                    child: _isCreatingSharedHabit
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Создать'),
                  ),
                ],
              ),
              ...data.sharedHabits.map(
                (habit) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    final habitsRepository = context.read<HabitsRepository>();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SharedHabitDetailsScreen(
                          sharedHabitPairId: habit.sharedHabitPairId,
                          repository: habitsRepository,
                        ),
                      ),
                    );
                  },
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
