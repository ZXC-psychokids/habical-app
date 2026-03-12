import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/habit_details/habit_details_cubit.dart';
import '../../cubits/habit_details/habit_details_state.dart';
import '../../models/models.dart';
import '../../repositories/habits_repository.dart';

class HabitDetailsScreen extends StatelessWidget {
  const HabitDetailsScreen({
    super.key,
    required this.habitId,
    required this.repository,
  });

  final String habitId;
  final HabitsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HabitDetailsCubit(repository: repository, habitId: habitId)..load(),
      child: const _HabitDetailsView(),
    );
  }
}

class _HabitDetailsView extends StatelessWidget {
  const _HabitDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitDetailsCubit, HabitDetailsState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          context.read<HabitDetailsCubit>().clearError();
        }
      },
      builder: (context, state) {
        final data = state.data;
        final isInitialLoad =
            state.status == HabitDetailsStatus.loading && data == null;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          appBar: AppBar(title: Text(data?.habit.title ?? 'Habit')),
          body: SafeArea(
            child: isInitialLoad
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data?.habit.title ?? '',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CalendarHeader(month: state.visibleMonth),
                        const SizedBox(height: 8),
                        _HabitCompletionCalendar(
                          month: state.visibleMonth,
                          today: _dayOnly(DateTime.now()),
                          tasks: data?.tasks ?? const [],
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HabitDetailsCubit>();
    return Row(
      children: [
        IconButton(
          onPressed: cubit.showPrevMonth,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              _monthLabel(month),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          onPressed: cubit.showNextMonth,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  String _monthLabel(DateTime date) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

class _HabitCompletionCalendar extends StatelessWidget {
  const _HabitCompletionCalendar({
    required this.month,
    required this.today,
    required this.tasks,
  });

  final DateTime month;
  final DateTime today;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = monthStart.weekday % 7;

    final statusByDay = _buildStatusByDay();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: Center(child: _Weekday('Su'))),
              Expanded(child: Center(child: _Weekday('Mo'))),
              Expanded(child: Center(child: _Weekday('Tu'))),
              Expanded(child: Center(child: _Weekday('We'))),
              Expanded(child: Center(child: _Weekday('Th'))),
              Expanded(child: Center(child: _Weekday('Fr'))),
              Expanded(child: Center(child: _Weekday('Sa'))),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final dayIndex = index - leadingEmpty + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(month.year, month.month, dayIndex);
              final status = statusByDay[_dayOnly(date)] ?? _DayStatus.none;
              return _DayCell(day: dayIndex, status: status, date: date);
            },
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: Colors.green),
              SizedBox(width: 6),
              Text('Completed'),
              SizedBox(width: 18),
              _LegendDot(color: Colors.red),
              SizedBox(width: 6),
              Text('Missed'),
            ],
          ),
        ],
      ),
    );
  }

  Map<DateTime, _DayStatus> _buildStatusByDay() {
    final map = <DateTime, _DayStatus>{};

    for (final task in tasks) {
      final day = _dayOnly(task.startsAt);
      if (day.isAfter(today)) {
        continue;
      }

      map[day] = task.isCompleted ? _DayStatus.completed : _DayStatus.missed;
    }

    return map;
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF666666),
      ),
    );
  }
}

enum _DayStatus { none, completed, missed }

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.status, required this.date});

  final int day;
  final _DayStatus status;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return SizedBox(
      key: ValueKey('day-$dateKey-${status.name}'),
      child: Center(
        child: switch (status) {
          _DayStatus.completed => _DayMarker(day: day, color: Colors.green),
          _DayStatus.missed => _DayMarker(day: day, color: Colors.red),
          _DayStatus.none => Text(
            '$day',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        },
      ),
    );
  }
}

class _DayMarker extends StatelessWidget {
  const _DayMarker({required this.day, required this.color});

  final int day;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
