import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/home/home_cubit.dart';
import '../../cubits/home/home_state.dart';
import '../../cubits/navigation/navigation_cubit.dart';
import '../../cubits/navigation/navigation_state.dart';
import '../../models/home_day_event_item.dart';
import '../../models/home_feed_entry.dart';
import '../../models/home_task_item.dart';
import '../../repositories/friends_repository.dart';
import '../../repositories/home_repository.dart';
import '../friends/friend_page_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.showFriendsBlock = true,
    this.canToggleTasks = true,
    this.showAppBar = false,
    this.appBarTitle,
    HomeRepository? repository,
  }) : _repository = repository;

  final bool showFriendsBlock;
  final bool canToggleTasks;
  final bool showAppBar;
  final String? appBarTitle;
  final HomeRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        _repository ?? RepositoryProvider.of<HomeRepository>(context);

    return BlocProvider(
      create: (_) => HomeCubit(repository: repository)..loadHome(),
      child: _HomeView(
        showFriendsBlock: showFriendsBlock,
        canToggleTasks: canToggleTasks,
        showAppBar: showAppBar,
        appBarTitle: appBarTitle,
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.showFriendsBlock,
    required this.canToggleTasks,
    required this.showAppBar,
    required this.appBarTitle,
  });

  final bool showFriendsBlock;
  final bool canToggleTasks;
  final bool showAppBar;
  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          context.read<HomeCubit>().clearError();
        }
      },
      builder: (context, state) {
        final data = state.data;
        final isInitialLoad = state.status == HomeStatus.loading && data == null;

        final feedEntries = [...(data?.feedEntries ?? const <HomeFeedEntry>[])]
          ..sort((a, b) {
            if (a.isPriorityReminder != b.isPriorityReminder) {
              return a.isPriorityReminder ? -1 : 1;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: showAppBar ? AppBar(title: Text(appBarTitle ?? 'Главная')) : null,
          body: SafeArea(
            child: isInitialLoad
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<HomeCubit>().loadHome(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        const Text(
                          'Habical',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0277BC),
                            letterSpacing: -0.8,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatHomeDate(state.selectedDay),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            height: 1.04,
                            letterSpacing: -0.4,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < -80) {
                              context.read<HomeCubit>().showPreviousDay();
                            } else if (velocity > 80) {
                              context.read<HomeCubit>().showNextDay();
                            }
                          },
                          child: _DailyCard(
                            selectedDay: state.selectedDay,
                            tasks: data?.tasks ?? const <HomeTaskItem>[],
                            events: data?.events ?? const <HomeDayEventItem>[],
                            canToggleTasks: canToggleTasks,
                          ),
                        ),
                        if (showFriendsBlock) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Друзья',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (feedEntries.isEmpty)
                            const _EmptyFeedCard()
                          else
                            ...feedEntries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FeedCard(item: entry),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
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
    final base = '${day.day} ${months[day.month - 1]}, ${weekdays[day.weekday - 1]}';

    if (normalized == today) {
      return 'Сегодня $base';
    }

    return base;
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.selectedDay,
    required this.tasks,
    required this.events,
    required this.canToggleTasks,
  });

  final DateTime selectedDay;
  final List<HomeTaskItem> tasks;
  final List<HomeDayEventItem> events;
  final bool canToggleTasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1A000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TasksSide(
                selectedDay: selectedDay,
                tasks: tasks,
                canToggleTasks: canToggleTasks,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0x22000000),
            ),
            Expanded(
              child: _EventsSide(
                selectedDay: selectedDay,
                events: events,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksSide extends StatelessWidget {
  const _TasksSide({
    required this.selectedDay,
    required this.tasks,
    required this.canToggleTasks,
  });

  final DateTime selectedDay;
  final List<HomeTaskItem> tasks;
  final bool canToggleTasks;

  @override
  Widget build(BuildContext context) {
    final events = context.read<HomeCubit>().state.data?.events ?? const <HomeDayEventItem>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 16),
              child: Text(
                'На сегодня задач нет',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF787878),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) async {
                var adjustedNew = newIndex;
                if (adjustedNew > oldIndex) {
                  adjustedNew -= 1;
                }
                await context.read<HomeCubit>().moveTask(
                  taskId: tasks[oldIndex].id,
                  newPosition: adjustedNew,
                );
              },
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  key: ValueKey(task.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskTile(
                    task: task,
                    canToggleTasks: canToggleTasks,
                    onTap: () => _openTaskEditorSheet(
                      context: context,
                      task: task,
                      events: events,
                    ),
                    onToggle: () => context.read<HomeCubit>().toggleTask(task.id),
                    dragHandle: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 17,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              onPressed: () => _openTaskEditorSheet(
                context: context,
                task: null,
                events: events,
              ),
              icon: const Icon(Icons.add, size: 23, color: Color(0xFF818181)),
              style: IconButton.styleFrom(
                minimumSize: const Size(30, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.canToggleTasks,
    required this.onTap,
    required this.onToggle,
    required this.dragHandle,
  });

  final HomeTaskItem task;
  final bool canToggleTasks;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final color = _taskColor(task);
    final subtitle = _taskSubtitle(task);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(top: 1, bottom: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: color,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: task.isCompleted
                          ? const Color(0xFF8E8E8E)
                          : const Color(0xFF151515),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9A9A9A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: InkWell(
                onTap: canToggleTasks ? onToggle : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    color: task.isCompleted ? color : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 2),
            dragHandle,
          ],
        ),
      ),
    );
  }

  String? _taskSubtitle(HomeTaskItem task) {
    final parts = <String>[];

    if (task.habit != null) {
      parts.add(task.habit!.title);
    }

    if (task.event != null) {
      parts.add(_timeRange(task.event!.startsAt, task.event!.endsAt));
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' · ');
  }

  String _timeRange(DateTime start, DateTime end) {
    String f(DateTime value) {
      final h = value.hour.toString().padLeft(2, '0');
      final m = value.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${f(start)}-${f(end)}';
  }

  Color _taskColor(HomeTaskItem task) {
    if (task.habit != null) {
      return _hexToColor(task.habit!.color);
    }
    if (task.event != null) {
      return const Color(0xFF5AA9E6);
    }
    if (task.manualColor != null) {
      return _hexToColor(task.manualColor!);
    }
    return const Color(0xFFB0B0B0);
  }
}

class _EventsSide extends StatelessWidget {
  const _EventsSide({
    required this.selectedDay,
    required this.events,
  });

  final DateTime selectedDay;
  final List<HomeDayEventItem> events;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 16),
              child: Text(
                'На сегодня событий нет',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF787878),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...events.map((event) => _EventTile(event: event)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final HomeDayEventItem event;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.endsAt.isBefore(now);
    final textColor = isPast ? const Color(0xFFB4B4B4) : const Color(0xFF151515);
    final subColor = isPast ? const Color(0xFFC7C7C7) : const Color(0xFF9B9B9B);

    return InkWell(
      onTap: () {
        context.read<NavigationCubit>().selectTab(NavigationTab.calendar);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4,
              height: 44,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _timeRange(event.startsAt, event.endsAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8D8D8D), size: 20),
          ],
        ),
      ),
    );
  }

  String _timeRange(DateTime start, DateTime end) {
    String f(DateTime value) {
      final h = value.hour.toString().padLeft(2, '0');
      final m = value.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${f(start)}-${f(end)}';
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item});

  final HomeFeedEntry item;

  @override
  Widget build(BuildContext context) {
    final hasAccent = item.isPriorityReminder;

    return InkWell(
      onTap: () {
        final friendsRepository = RepositoryProvider.of<FriendsRepository>(context);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FriendPageScreen(
              friendUserId: item.actor.id,
              friendsRepository: friendsRepository,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasAccent ? const Color(0xFFFFF4E8) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasAccent ? const Color(0xFFFFC680) : const Color(0x1A000000),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(url: item.actor.avatarUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.toPresentationText(),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1D1D1D),
                  height: 1.25,
                  fontFamily: 'Cera Pro',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Color(0xFF6B6B6B)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFF0A84FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_outline, color: Colors.white),
    );
  }
}

class _EmptyFeedCard extends StatelessWidget {
  const _EmptyFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: const Text(
        'Пока нет новостей друзей.',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF707070),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Future<void> _openTaskEditorSheet({
  required BuildContext context,
  required HomeTaskItem? task,
  required List<HomeDayEventItem> events,
}) async {
  final cubit = context.read<HomeCubit>();
  final titleController = TextEditingController(text: task?.title ?? '');
  var selectedColor = task?.manualColor ?? '#FF9F0A';
  var selectedEventId = task?.event?.id;
  var colorWasChangedByUser = false;

  final isHabitLocked = task?.habit != null;
  final isEditing = task != null;

  final result = await showModalBottomSheet<_TaskSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final eventLocked = selectedEventId != null;
          final canEditTitle = !isHabitLocked;
          final canEditColor = !isHabitLocked && !eventLocked;
          final canDelete = isEditing && !isHabitLocked;

          final selectedEventTitle = () {
            if (selectedEventId == null) {
              return 'Не привязано';
            }
            for (final item in events) {
              if (item.id == selectedEventId) {
                return item.title;
              }
            }
            return 'Не привязано';
          }();

          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(
              14,
              12,
              14,
              14 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x22000000)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _hexToColor(canEditColor ? selectedColor : '#B0B0B0'),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: titleController,
                        enabled: canEditTitle,
                        decoration: const InputDecoration(
                          hintText: 'Новая задача',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(_TaskSheetResult.save),
                      icon: const Icon(Icons.check, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                IgnorePointer(
                  ignoring: !canEditColor,
                  child: Opacity(
                    opacity: canEditColor ? 1 : 0.45,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _palette14.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final colorHex = _palette14[index];
                        final selected = selectedColor == colorHex;

                        return InkWell(
                          onTap: () => setSheetState(() {
                            selectedColor = colorHex;
                            colorWasChangedByUser = true;
                          }),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _hexToColor(colorHex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF0277BC)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Событие',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(selectedEventTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final pickedEventId = await showModalBottomSheet<String?>(
                      context: sheetContext,
                      backgroundColor: Colors.white,
                      builder: (pickerContext) {
                        return SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                title: const Text('Не привязывать'),
                                onTap: () => Navigator.of(pickerContext).pop(''),
                              ),
                              ...events.map(
                                (event) => ListTile(
                                  title: Text(event.title),
                                  subtitle: Text(
                                    '${_timeLabel(event.startsAt)}-${_timeLabel(event.endsAt)}',
                                  ),
                                  onTap: () => Navigator.of(pickerContext).pop(event.id),
                                ),
                              ),
                              ListTile(
                                title: const Text('Создать новое событие'),
                                onTap: () {
                                  Navigator.of(pickerContext).pop('__create_new__');
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (pickedEventId == null) {
                      return;
                    }

                    if (pickedEventId == '__create_new__') {
                      Navigator.of(sheetContext).pop(_TaskSheetResult.goCalendar);
                      return;
                    }

                    if (pickedEventId.isEmpty) {
                      setSheetState(() => selectedEventId = null);
                      return;
                    }

                    setSheetState(() => selectedEventId = pickedEventId);
                  },
                ),
                if (task?.habit != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Привычка'),
                    subtitle: Text(task!.habit!.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(sheetContext).pop(_TaskSheetResult.goHabits),
                  ),
                if (canDelete)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(_TaskSheetResult.delete),
                      child: const Text(
                        'Удалить задачу',
                        style: TextStyle(color: Color(0xFFBC2C2C)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );

  if (!context.mounted || result == null) {
    return;
  }

  if (result == _TaskSheetResult.goCalendar) {
    context.read<NavigationCubit>().selectTab(NavigationTab.calendar);
    return;
  }

  if (result == _TaskSheetResult.goHabits) {
    context.read<NavigationCubit>().selectTab(NavigationTab.habits);
    return;
  }

  if (result == _TaskSheetResult.delete && task != null) {
    await cubit.deleteTask(task.id);
    return;
  }

  if (result != _TaskSheetResult.save) {
    return;
  }

  final trimmedTitle = titleController.text.trim();
  if (trimmedTitle.isEmpty) {
    return;
  }

  if (task == null) {
    final created = await cubit.createTask(
      title: trimmedTitle,
      manualColor: selectedEventId == null ? selectedColor : null,
    );

    if (selectedEventId != null && created != null && context.mounted) {
      await cubit.linkTaskToEvent(taskId: created.id, eventId: selectedEventId!);
    }

    return;
  }

  final hasTitleChanged = trimmedTitle != task.title;
  final canChangeManualColor = task.habit == null && selectedEventId == null;
  final hasColorChanged = canChangeManualColor &&
      colorWasChangedByUser &&
      selectedColor != task.manualColor;

  if (hasTitleChanged || hasColorChanged) {
    await cubit.updateTask(
      taskId: task.id,
      input: HomeTaskUpdateInput(
        title: hasTitleChanged ? trimmedTitle : null,
        manualColor: hasColorChanged ? selectedColor : null,
      ),
    );
  }

  final currentEventId = task.event?.id;
  if (selectedEventId != currentEventId) {
    if (selectedEventId == null) {
      await cubit.unlinkTaskFromEvent(task.id);
    } else {
      await cubit.linkTaskToEvent(taskId: task.id, eventId: selectedEventId!);
    }
  }
}

enum _TaskSheetResult {
  save,
  delete,
  goCalendar,
  goHabits,
}

const List<String> _palette14 = [
  '#FF3B30',
  '#0A84FF',
  '#34C759',
  '#FFD60A',
  '#FF9F0A',
  '#BF5AF2',
  '#8AC926',
  '#8E8E93',
  '#8B5E3C',
  '#FF2D55',
  '#40CBE0',
  '#A0AEC0',
  '#6366F1',
  '#F725D0',
];

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
    return const Color(0xFFB0B0B0);
  }
  return Color(parsed);
}

String _timeLabel(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
