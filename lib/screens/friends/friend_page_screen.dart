import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/navigation/navigation_cubit.dart';
import '../../cubits/navigation/navigation_state.dart';
import '../../models/friend_page_data.dart';
import '../../repositories/friends_repository.dart';
import 'friend_bottom_nav_bar.dart';
import 'friend_calendar_screen.dart';

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
        _error = 'Не удалось загрузить профиль друга.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      bottomNavigationBar: const FriendBottomNavBar(
        selectedTab: NavigationTab.friends,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(25, 12, 25, 20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF0277BC),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 90),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0277BC),
                    ),
                  ),
                )
              else if (_error != null)
                _InfoBlock(
                  text: _error!,
                  textColor: const Color(0xFF777777),
                  backgroundColor: const Color(0xFFF3F3F3),
                )
              else if (data != null)
                _buildLoaded(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(FriendPageData data) {
    final sharedHabits = [...data.sharedHabits]
      ..sort((a, b) {
        if (a.streakDays != b.streakDays) {
          return b.streakDays.compareTo(a.streakDays);
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    final showTopBlock = data.hasTopBlockData;
    final showSharedBlock = data.canViewSharedHabits;
    final isFullyPrivate = data.isEverythingHidden;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FriendIdentity(data: data),
        const SizedBox(height: 14),
        if (isFullyPrivate)
          const _InfoBlock(
            text: 'Профиль пользователя приватный.',
            textColor: Color(0xFF777777),
            backgroundColor: Color(0xFFF3F3F3),
          )
        else ...[
          if (showTopBlock) ...[
            Text(
              _formatHomeDate(DateTime.now()),
              style: const TextStyle(
                fontSize: 36 / 1.56,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            _FriendDailyCard(
              canViewTasks: data.canViewTasks,
              canViewEvents: data.canViewEvents,
              tasks: data.tasks,
              events: data.events,
              onTapEvent: (event) {
                _openFriendCalendar(initialDay: event.startsAt);
              },
              onTapTaskWithEvent: (task) {
                final startsAt = task.eventStartsAt;
                if (startsAt == null) {
                  return;
                }
                _openFriendCalendar(initialDay: startsAt);
              },
            ),
            const SizedBox(height: 24),
          ],
          if (showSharedBlock) ...[
            const Text(
              'Ваши совместные привычки',
              style: TextStyle(
                fontSize: 32 / 1.56,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            if (sharedHabits.isEmpty)
              const _InfoBlock(
                text: 'Совместных привычек пока нет.',
                textColor: Color(0xFF777777),
                backgroundColor: Color(0xFFF3F3F3),
              )
            else
              ...sharedHabits.map(
                (habit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SharedHabitCard(
                    habit: habit,
                    onTap: () {
                      _openHabitFromRoot(habit.habitId);
                    },
                  ),
                ),
              ),
          ] else if (!showTopBlock)
            const _InfoBlock(
              text: 'Профиль пользователя приватный.',
              textColor: Color(0xFF777777),
              backgroundColor: Color(0xFFF3F3F3),
            ),
        ],
      ],
    );
  }

  void _openFriendCalendar({required DateTime initialDay}) {
    final data = _data;
    if (data == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendCalendarScreen(
          friendUserId: widget.friendUserId,
          friendHandle: data.profile.handle,
          friendsRepository: widget.friendsRepository,
          initialDay: initialDay,
        ),
      ),
    );
  }

  void _openHabitFromRoot(String habitId) {
    try {
      context.read<NavigationCubit>().openHabitsTab(focusHabitId: habitId);
    } catch (_) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  String _formatHomeDate(DateTime day) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    const weekdays = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(day.year, day.month, day.day);
    final base =
        '${day.day} ${months[day.month - 1]}, ${weekdays[day.weekday - 1]}';

    if (normalized == today) {
      return 'Сегодня $base';
    }
    return base;
  }
}

class _FriendIdentity extends StatelessWidget {
  const _FriendIdentity({required this.data});

  final FriendPageData data;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = data.profile.avatarUrl.trim().isNotEmpty;
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0277BC), width: 2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(58),
              child: hasAvatar
                  ? Image.network(
                      data.profile.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.profile.handle,
            style: const TextStyle(
              fontSize: 48 / 1.56,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7F3FB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 54,
        color: Color(0xFF0277BC),
      ),
    );
  }
}

class _FriendDailyCard extends StatelessWidget {
  const _FriendDailyCard({
    required this.canViewTasks,
    required this.canViewEvents,
    required this.tasks,
    required this.events,
    required this.onTapEvent,
    required this.onTapTaskWithEvent,
  });

  final bool canViewTasks;
  final bool canViewEvents;
  final List<FriendTaskPreview> tasks;
  final List<FriendEventPreview> events;
  final ValueChanged<FriendEventPreview> onTapEvent;
  final ValueChanged<FriendTaskPreview> onTapTaskWithEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
              child: !canViewTasks
                  ? const _HiddenMiniBlock(text: 'Задачи скрыты')
                  : _FriendTasksColumn(
                      tasks: tasks,
                      onTapTaskWithEvent: onTapTaskWithEvent,
                    ),
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFFE5E5EA),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 12, 10),
              child: !canViewEvents
                  ? const _HiddenMiniBlock(text: 'События скрыты')
                  : _FriendEventsColumn(
                      events: events,
                      onTapEvent: onTapEvent,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTasksColumn extends StatelessWidget {
  const _FriendTasksColumn({
    required this.tasks,
    required this.onTapTaskWithEvent,
  });

  final List<FriendTaskPreview> tasks;
  final ValueChanged<FriendTaskPreview> onTapTaskWithEvent;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Text(
        'На сегодня задач нет',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF8E8E93),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tasks.take(4).map((task) {
        final subtitle = _buildSubtitle(task);
        final stripeColor = _resolveTaskStripe(task);
        return InkWell(
          onTap: task.eventStartsAt == null ? null : () => onTapTaskWithEvent(task),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stripeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: task.isCompleted
                              ? const Color(0xFFB0B0B5)
                              : const Color(0xFF1C1C1E),
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFABABAB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  String? _buildSubtitle(FriendTaskPreview task) {
    if (task.eventStartsAt != null && task.eventEndsAt != null) {
      return '${_timeLabel(task.eventStartsAt!)} - ${_timeLabel(task.eventEndsAt!)}';
    }
    if (task.habitTitle != null && task.habitTitle!.trim().isNotEmpty) {
      return task.habitTitle;
    }
    return null;
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _resolveTaskStripe(FriendTaskPreview task) {
    if (task.habitColor != null) {
      return _hexToColor(task.habitColor!);
    }
    return const Color(0xFF5AA9E6);
  }
}

class _FriendEventsColumn extends StatelessWidget {
  const _FriendEventsColumn({
    required this.events,
    required this.onTapEvent,
  });

  final List<FriendEventPreview> events;
  final ValueChanged<FriendEventPreview> onTapEvent;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text(
        'На сегодня событий нет',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF8E8E93),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: events.take(4).map((event) {
        return InkWell(
          onTap: () => onTapEvent(event),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 3,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _hexToColor(event.categoryColor),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_timeLabel(event.startsAt)} - ${_timeLabel(event.endsAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFABABAB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _HiddenMiniBlock extends StatelessWidget {
  const _HiddenMiniBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFABABAB),
        ),
      ),
    );
  }
}

class _SharedHabitCard extends StatelessWidget {
  const _SharedHabitCard({
    required this.habit,
    required this.onTap,
  });

  final SharedHabitPreview habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
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
                color: _hexToColor(habit.color),
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 32 / 1.95,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _streakLabel(habit.streakDays),
                    style: const TextStyle(
                      color: Color(0xFFABABAB),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF000000),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _streakLabel(int days) {
    if (days <= 0) {
      return 'Ваш первый день';
    }
    return '$days день подряд';
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
  });

  final String text;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(29, 39, 51, 0.30),
            offset: Offset(0, 4),
            blurRadius: 10.1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

Color _hexToColor(String rawValue) {
  var value = rawValue.trim();
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) {
    return const Color(0xFFC7C7CC);
  }
  return Color(parsed);
}
