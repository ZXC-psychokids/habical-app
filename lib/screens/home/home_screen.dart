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
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final data = state.data;
        final isInitialLoad =
            state.status == HomeStatus.loading && data == null;
        final isLoading = state.status == HomeStatus.loading;

        final feedEntries = [...(data?.feedEntries ?? const <HomeFeedEntry>[])]
          ..sort((a, b) {
            if (a.isPriorityReminder != b.isPriorityReminder) {
              return a.isPriorityReminder ? -1 : 1;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: showAppBar
              ? AppBar(title: Text(appBarTitle ?? 'Главная'))
              : null,
          body: SafeArea(
            child: isInitialLoad
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () async {
                          context.read<HomeCubit>().loadHome();
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            const Text(
                              'Habical',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0277BC),
                                letterSpacing: -0.4,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatHomeDate(state.selectedDay),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _DailyCardSection(
                              selectedDay: state.selectedDay,
                              tasks: data?.tasks ?? const <HomeTaskItem>[],
                              events:
                                  data?.events ?? const <HomeDayEventItem>[],
                              canToggleTasks: canToggleTasks,
                            ),
                            if (showFriendsBlock) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Друзья',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                      if (isLoading && data != null)
                        Positioned.fill(
                          child: Container(
                            color: const Color(0x40000000),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
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
    final base =
        '${day.day} ${months[day.month - 1]}, ${weekdays[day.weekday - 1]}';

    if (normalized == today) {
      return 'Сегодня $base';
    }

    return base;
  }
}

class _DailyCardSection extends StatelessWidget {
  const _DailyCardSection({
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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -80) {
          try {
            context.read<HomeCubit>().showNextDay();
          } catch (_) {}
        } else if (velocity > 80) {
          try {
            context.read<HomeCubit>().showPreviousDay();
          } catch (_) {}
        }
      },
      child: _DailyCard(
        selectedDay: selectedDay,
        tasks: tasks,
        events: events,
        canToggleTasks: canToggleTasks,
      ),
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TasksColumn(
              tasks: tasks,
              events: events,
              canToggleTasks: canToggleTasks,
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFFE5E5EA),
          ),
          Expanded(child: _EventsColumn(events: events)),
        ],
      ),
    );
  }
}

class _TasksColumn extends StatelessWidget {
  const _TasksColumn({
    required this.tasks,
    required this.events,
    required this.canToggleTasks,
  });

  final List<HomeTaskItem> tasks;
  final List<HomeDayEventItem> events;
  final bool canToggleTasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'На сегодня задач нет',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
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
              onReorder: (oldIndex, newIndex) {
                try {
                  var adjustedNew = newIndex;
                  if (adjustedNew > oldIndex) {
                    adjustedNew -= 1;
                  }
                  context.read<HomeCubit>().moveTask(
                    taskId: tasks[oldIndex].id,
                    newPosition: adjustedNew,
                  );
                } catch (_) {}
              },
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  key: ValueKey(task.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskRow(
                    task: task,
                    index: index,
                    canToggleTasks: canToggleTasks,
                    events: events,
                  ),
                );
              },
            ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              onPressed: () {
                _showTaskDialog(context, task: null, events: events);
              },
              icon: const Icon(Icons.add, size: 24, color: Color(0xFF0277BC)),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.index,
    required this.canToggleTasks,
    required this.events,
  });

  final HomeTaskItem task;
  final int index;
  final bool canToggleTasks;
  final List<HomeDayEventItem> events;

  @override
  Widget build(BuildContext context) {
    final color = _taskColor(task);
    final subtitle = _taskSubtitle(task);

    return InkWell(
      onTap: () {
        _showTaskDialog(context, task: task, events: events);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 3,
              height: 40,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: InkWell(
                onTap: canToggleTasks
                    ? () {
                        try {
                          context.read<HomeCubit>().toggleTask(task.id);
                        } catch (_) {}
                      }
                    : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    color: task.isCompleted ? color : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: Color(0xFFC7C7CC),
                ),
              ),
            ),
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

    return '${f(start)}–${f(end)}';
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
    return const Color(0xFFC7C7CC);
  }
}

class _EventsColumn extends StatelessWidget {
  const _EventsColumn({required this.events});

  final List<HomeDayEventItem> events;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'На сегодня событий нет',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...events.map((event) => _EventRow(event: event)).toList(),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final HomeDayEventItem event;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.endsAt.isBefore(now);
    final textColor = isPast
        ? const Color(0xFFB0B0B5)
        : const Color(0xFF1C1C1E);
    final subColor = isPast ? const Color(0xFFC7C7CC) : const Color(0xFF8E8E93);

    return InkWell(
      onTap: () {
        try {
          context.read<NavigationCubit>().selectTab(NavigationTab.calendar);
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 3,
              height: 40,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _timeRange(event.startsAt, event.endsAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
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
  }

  String _timeRange(DateTime start, DateTime end) {
    String f(DateTime value) {
      final h = value.hour.toString().padLeft(2, '0');
      final m = value.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${f(start)}–${f(end)}';
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
        try {
          final friendsRepository = RepositoryProvider.of<FriendsRepository>(
            context,
          );
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FriendPageScreen(
                friendUserId: item.actor.id,
                friendsRepository: friendsRepository,
              ),
            ),
          );
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: hasAccent ? const Color(0xFFFFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hasAccent
                ? const Color(0xFFFFE0CC)
                : const Color(0xFFE5E5EA),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 3,
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
                  fontSize: 13,
                  color: Color(0xFF1C1C1E),
                  height: 1.35,
                  fontFamily: 'Cera Pro',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0277BC),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
    );
  }
}

class _EmptyFeedCard extends StatelessWidget {
  const _EmptyFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Text(
        'Пока нет новостей друзей.',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF8E8E93),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

void _showTaskDialog(
  BuildContext context, {
  required HomeTaskItem? task,
  required List<HomeDayEventItem> events,
}) {
  showDialog<void>(
    context: context,
    barrierColor: const Color(0x60000000),
    builder: (dialogContext) {
      return _TaskEditDialog(task: task, events: events);
    },
  );
}

class _TaskEditDialog extends StatefulWidget {
  const _TaskEditDialog({required this.task, required this.events});

  final HomeTaskItem? task;
  final List<HomeDayEventItem> events;

  @override
  State<_TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<_TaskEditDialog> {
  late final TextEditingController titleController;
  late String selectedColor;
  String? selectedEventId;
  bool colorWasChangedByUser = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task?.title ?? '');
    selectedColor = widget.task?.manualColor ?? _palette14[0];
    selectedEventId = widget.task?.event?.id;
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHabitLocked = widget.task?.habit != null;
    final isEditing = widget.task != null;
    final eventLocked = selectedEventId != null;
    final canEditTitle = !isHabitLocked;
    final canEditColor = !isHabitLocked && !eventLocked;
    final canDelete = isEditing && !isHabitLocked;

    final selectedEventTitle = _getEventTitle();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _hexToColor(
                      canEditColor ? selectedColor : '#8E8E93',
                    ),
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
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Color palette
            if (canEditColor) ...[
              const Text(
                'Цвет',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
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
                    onTap: () => setState(() {
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
              const SizedBox(height: 14),
            ] else if (!isHabitLocked) ...[
              Text(
                'Цвет: ${_eventTitle()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Event link
            if (!isHabitLocked) ...[
              const Text(
                'Событие',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showEventPicker(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedEventTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF8E8E93),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Habit info
            if (widget.task?.habit != null) ...[
              const Text(
                'Привычка',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.task!.habit!.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        try {
                          context.read<NavigationCubit>().selectTab(
                            NavigationTab.habits,
                          );
                        } catch (_) {}
                      },
                      child: const Text(
                        'К привычкам',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0277BC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (canDelete)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      try {
                        context.read<HomeCubit>().deleteTask(widget.task!.id);
                      } catch (_) {}
                    },
                    child: const Text(
                      'Удалить',
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _save(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0277BC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTitle() {
    if (selectedEventId == null) {
      return 'Не привязано';
    }
    for (final item in widget.events) {
      if (item.id == selectedEventId) {
        return item.title;
      }
    }
    return 'Не привязано';
  }

  String _eventTitle() {
    if (selectedEventId == null) {
      return 'не привязана';
    }
    for (final item in widget.events) {
      if (item.id == selectedEventId) {
        return 'привязана к "${item.title}"';
      }
    }
    return 'привязана';
  }

  void _showEventPicker() {
    showDialog<String?>(
      context: context,
      builder: (pickerContext) {
        return Dialog(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Не привязывать'),
                onTap: () => Navigator.of(pickerContext).pop(''),
              ),
              ...widget.events.map(
                (event) => ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${_timeLabel(event.startsAt)}–${_timeLabel(event.endsAt)}',
                    style: const TextStyle(fontSize: 12),
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
    ).then((value) {
      if (value == null) return;

      if (value == '__create_new__') {
        Navigator.of(context).pop();
        try {
          context.read<NavigationCubit>().selectTab(NavigationTab.calendar);
        } catch (_) {}
        return;
      }

      setState(() {
        selectedEventId = value.isEmpty ? null : value;
      });
    });
  }

  void _save(BuildContext context) {
    final trimmedTitle = titleController.text.trim();
    if (trimmedTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название задачи не может быть пустым')),
      );
      return;
    }

    try {
      final cubit = context.read<HomeCubit>();
      final task = widget.task;

      if (task == null) {
        cubit
            .createTask(
              title: trimmedTitle,
              manualColor: selectedEventId == null ? selectedColor : null,
            )
            .then((created) {
              if (created != null && selectedEventId != null && mounted) {
                cubit.linkTaskToEvent(
                  taskId: created.id,
                  eventId: selectedEventId!,
                );
              }
              Navigator.of(context).pop();
            });
        return;
      }

      final hasTitleChanged = trimmedTitle != task.title;
      final canChangeManualColor =
          task.habit == null && selectedEventId == null;
      final hasColorChanged =
          canChangeManualColor &&
          colorWasChangedByUser &&
          selectedColor != task.manualColor;

      if (hasTitleChanged || hasColorChanged) {
        cubit.updateTask(
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
          cubit.unlinkTaskFromEvent(task.id);
        } else {
          cubit.linkTaskToEvent(taskId: task.id, eventId: selectedEventId!);
        }
      }

      Navigator.of(context).pop();
    } catch (_) {}
  }
}

const List<String> _palette14 = [
  '#FF3B30', // красный
  '#0A84FF', // синий
  '#34C759', // зеленый
  '#FFD60A', // желтый
  '#FF9500', // оранжевый
  '#AF52DE', // фиолетовый
  '#A2845E', // коричневый
  '#FF2D55', // розовый
  '#00C7BE', // бирюзовый
  '#8E8E93', // серый
  '#64B5F6', // светлый синий
  '#81C784', // светлый зеленый
  '#FFB74D', // светлый оранжевый
  '#BA68C8', // светлый фиолетовый
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
    return const Color(0xFFC7C7CC);
  }
  return Color(parsed);
}

String _timeLabel(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
