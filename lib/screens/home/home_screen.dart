import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/home/home_cubit.dart';
import '../../cubits/home/home_state.dart';
import '../../models/home_feed_item.dart';
import '../../models/home_event_item.dart';
import '../../models/task.dart';
import '../../repositories/home_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.currentUserId = 'user_me',
    HomeRepository? repository,
  }) : _repository = repository;

  final String currentUserId;
  final HomeRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final repository =
        _repository ?? RepositoryProvider.of<HomeRepository>(context);

    return BlocProvider(
      create: (_) =>
          HomeCubit(repository: repository, userId: currentUserId)..loadHome(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          context.read<HomeCubit>().clearError();
        }
      },
      builder: (context, state) {
        final data = state.data;
        final isInitialLoad =
            state.status == HomeStatus.loading && data == null;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().loadHome(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Text(
                    _titleForDay(state.selectedDay),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isInitialLoad)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _MainDayCard(
                      tasks: data?.tasks ?? const [],
                      events: data?.events ?? const [],
                      onToggleTask: (taskId) {
                        context.read<HomeCubit>().toggleTask(taskId);
                      },
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Друзья',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if ((data?.feedItems ?? const []).isEmpty)
                      const _EmptyFeedCard()
                    else
                      ...data!.feedItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _FeedCard(item: item),
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

  String _titleForDay(DateTime day) {
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

    final weekday = weekdays[day.weekday - 1];
    final month = months[day.month - 1];
    return 'Сегодня ${day.day} $month, $weekday';
  }
}

class _MainDayCard extends StatelessWidget {
  const _MainDayCard({
    required this.tasks,
    required this.events,
    required this.onToggleTask,
  });

  final List<Task> tasks;
  final List<HomeEventItem> events;
  final ValueChanged<String> onToggleTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SizedBox(
        height: 330,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TasksColumn(
                tasks: tasks,
                onToggleTask: onToggleTask,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0x33000000),
            ),
            Expanded(
              child: _EventsColumn(events: events),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksColumn extends StatelessWidget {
  const _TasksColumn({
    required this.tasks,
    required this.onToggleTask,
  });

  final List<Task> tasks;
  final ValueChanged<String> onToggleTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _EmptyColumnText(text: 'На сегодня задач нет');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskRow(
              task: task,
              onChanged: () => onToggleTask(task.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsColumn extends StatelessWidget {
  const _EventsColumn({required this.events});

  final List<HomeEventItem> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyColumnText(text: 'На сегодня событий нет');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _EventRow(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onChanged,
  });

  final Task task;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onChanged(),
            side: const BorderSide(color: Colors.black54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              height: 1.2,
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: task.isCompleted ? Colors.black54 : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.item});

  final HomeEventItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: Color(item.categoryColorValue),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _timeRange(item.event.startsAt, item.event.endsAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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

  final HomeFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1A000000)),
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
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFD1D1D1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${item.friendName} ${item.message}',
              style: const TextStyle(
                fontSize: 16,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumnText extends StatelessWidget {
  const _EmptyColumnText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyFeedCard extends StatelessWidget {
  const _EmptyFeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: const Text('Пока нет новостей друзей.'),
    );
  }
}