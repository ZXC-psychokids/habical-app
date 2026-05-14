import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/create_habit/create_habit_state.dart';
import '../../cubits/habits/habits_cubit.dart';
import '../../cubits/habits/habits_state.dart';
import '../../models/habit_calendar_day_summary.dart';
import '../../models/habit_list_item.dart';
import '../../repositories/habits_repository.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({
    super.key,
    this.currentUserId = 'user_me',
    HabitsRepository? repository,
    this.initialExpandedHabitId,
  }) : _repository = repository;

  final String currentUserId;
  final HabitsRepository? _repository;
  final String? initialExpandedHabitId;

  @override
  Widget build(BuildContext context) {
    final repository =
        _repository ?? RepositoryProvider.of<HabitsRepository>(context);

    return BlocProvider(
      create: (_) =>
          HabitsCubit(
            repository: repository,
            userId: currentUserId,
            initialExpandedHabitId: initialExpandedHabitId,
          )
            ..loadHabits(),
      child: const _HabitsView(),
    );
  }
}

class _HabitsView extends StatelessWidget {
  const _HabitsView();

  Future<void> _openCreateHabit(BuildContext context) async {
    final cubit = context.read<HabitsCubit>();
    final submission = await showDialog<CreateHabitSubmission>(
      context: context,
      barrierColor: const Color(0x60000000),
      builder: (_) => const _CreateHabitDialog(),
    );

    if (submission == null) {
      return;
    }
    await cubit.addHabit(
      title: submission.title,
      startDate: submission.startDate,
      color: submission.color,
      scheduleType: submission.scheduleType,
      intervalDays: submission.intervalDays,
      weekdays: submission.weekdays,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitsCubit, HabitsState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          context.read<HabitsCubit>().clearError();
        }
      },
      builder: (context, state) {
        final isInitialLoad =
            state.status == HabitsStatus.loading && state.items.isEmpty;

        final expandedId = state.expandedHabitId;
        HabitListItem? expandedItem;
        if (expandedId != null) {
          for (final item in state.items) {
            if (item.habit.id == expandedId) {
              expandedItem = item;
              break;
            }
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<HabitsCubit>().loadHabits(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                children: [
                  const Text(
                    'Привычки',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0277BC),
                      height: 1,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MiniHabitsCalendarCard(
                    summary: state.calendarSummary,
                    selectedHabitId: expandedItem?.habit.id,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Все привычки',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isInitialLoad)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.items.isEmpty)
                    const _EmptyHabitsCard()
                  else
                    ...state.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HabitCard(
                          item: item,
                          expanded: item.habit.id == expandedId,
                          isUpdating: state.isUpdatingHabit,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isUpdatingHabit
                          ? null
                          : () => _openCreateHabit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E5EA)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Добавить новую привычку',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
}

class _CreateHabitDialog extends StatefulWidget {
  const _CreateHabitDialog();

  @override
  State<_CreateHabitDialog> createState() => _CreateHabitDialogState();
}

class _CreateHabitDialogState extends State<_CreateHabitDialog> {
  static const double _dialogColorDotSize = 32;
  static const double _dialogColorSpacing = 12;
  late final TextEditingController _titleController;
  late DateTime _startDate;
  late String _selectedColor;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _titleController = TextEditingController();
    _startDate = DateTime(now.year, now.month, now.day);
    _selectedColor = _palette14.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Новая привычка',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              cursorColor: const Color(0xFF0277BC),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: 'Название привычки',
                errorText: _titleError,
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF0277BC),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Старт: ${_formatDate(_startDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: Color(0xFF8E8E93),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                crossAxisCount: 5,
                mainAxisSpacing: _dialogColorSpacing,
                crossAxisSpacing: _dialogColorSpacing,
                mainAxisExtent: _dialogColorDotSize,
              ),
              itemBuilder: (context, index) {
                final colorHex = _palette14[index];
                final selected = _selectedColor == colorHex;
                return Center(
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      customBorder: const CircleBorder(),
                      splashColor: const Color(0x220277BC),
                      hoverColor: const Color(0x140277BC),
                      child: SizedBox(
                        width: _dialogColorDotSize,
                        height: _dialogColorDotSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _hexToColor(colorHex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF0277BC)
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0277BC),
                  ),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
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
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final blueScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF0277BC),
          brightness: baseTheme.brightness,
        ).copyWith(surface: Colors.white);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: blueScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0277BC),
              ),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: Color(0xFF0277BC),
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = 'Введите название привычки';
      });
      return;
    }
    if (title.length > 120) {
      setState(() {
        _titleError = 'Название не должно быть длиннее 120 символов';
      });
      return;
    }

    Navigator.of(context).pop(
      CreateHabitSubmission(
        title: title,
        startDate: _startDate,
        color: _selectedColor,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _MiniHabitsCalendarCard extends StatelessWidget {
  const _MiniHabitsCalendarCard({
    required this.summary,
    required this.selectedHabitId,
  });

  final List<HabitCalendarDaySummary> summary;
  final String? selectedHabitId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekMonday = _monday(today);
    final firstDay = currentWeekMonday.subtract(const Duration(days: 7));
    final days = List.generate(28, (index) => firstDay.add(Duration(days: index)));

    final summaryByDay = <String, HabitCalendarDaySummary>{};
    for (final item in summary) {
      summaryByDay[_dateKey(item.date)] = item;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
      child: Column(
        children: [
          const Row(
            children: [
              _WeekdayCell('Пн'),
              _WeekdayCell('Вт'),
              _WeekdayCell('Ср'),
              _WeekdayCell('Чт'),
              _WeekdayCell('Пт'),
              _WeekdayCell('Сб'),
              _WeekdayCell('Вс'),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: 28,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 0,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final daySummary = summaryByDay[_dateKey(day)];
              final isCurrentMonth = day.month == today.month;
              final canHighlight = !day.isAfter(today);

              final inactiveTextColor = isCurrentMonth
                  ? const Color(0xFF232323)
                  : const Color(0xFFA7A7A7);

              if (!canHighlight || daySummary == null || daySummary.completedHabits.isEmpty) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: inactiveTextColor,
                    ),
                  ),
                );
              }

              final colors = selectedHabitId == null
                  ? daySummary.completedHabits
                  : daySummary.completedHabits
                        .where((item) => item.habitId == selectedHabitId)
                        .toList(growable: false);

              if (colors.isEmpty) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: inactiveTextColor,
                    ),
                  ),
                );
              }

              return Center(
                child: _MultiColorDayBadge(
                  day: day.day,
                  colors: colors
                      .take(4)
                      .map((item) => _hexToColor(item.color))
                      .toList(growable: false),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  DateTime _monday(DateTime date) {
    final base = DateTime(date.year, date.month, date.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }

  String _dateKey(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }

}

class _WeekdayCell extends StatelessWidget {
  const _WeekdayCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }
}

class _MultiColorDayBadge extends StatelessWidget {
  const _MultiColorDayBadge({
    required this.day,
    required this.colors,
  });

  final int day;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (colors.length == 1) {
      return _SingleColorBadge(day: day, color: colors.first);
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SegmentedCirclePainter(colors: colors),
            ),
          ),
          Center(
            child: Text(
              '$day',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleColorBadge extends StatelessWidget {
  const _SingleColorBadge({
    required this.day,
    required this.color,
  });

  final int day;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SegmentedCirclePainter extends CustomPainter {
  _SegmentedCirclePainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final step = (math.pi * 2) / colors.length;
    var start = -math.pi / 2;

    for (final color in colors) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      canvas.drawArc(rect, start, step, true, paint);
      start += step;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCirclePainter oldDelegate) {
    if (oldDelegate.colors.length != colors.length) {
      return true;
    }
    for (var i = 0; i < colors.length; i++) {
      if (colors[i] != oldDelegate.colors[i]) {
        return true;
      }
    }
    return false;
  }
}

class _HabitCard extends StatefulWidget {
  const _HabitCard({
    required this.item,
    required this.expanded,
    required this.isUpdating,
  });

  final HabitListItem item;
  final bool expanded;
  final bool isUpdating;

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> with TickerProviderStateMixin {
  bool _showRegularityOptions = false;

  @override
  void didUpdateWidget(covariant _HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.expanded && _showRegularityOptions) {
      _showRegularityOptions = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final habit = item.habit;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
      child: Column(
        children: [
          InkWell(
            onTap: widget.isUpdating
                ? null
                : () => context.read<HabitsCubit>().toggleExpandedHabit(habit.id),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _hexToColor(habit.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withAlpha(habit.isShared ? 150 : 255),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.streakLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFB0B0B0).withAlpha(habit.isShared ? 150 : 255),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: widget.expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                  size: 26,
                  color: const Color(0xFF202020).withAlpha(habit.isShared ? 150 : 255),
                ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return ClipRect(
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: widget.expanded
                ? Column(
                    key: const ValueKey('expanded'),
                    children: [
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: Color(0x18000000)),
                      const SizedBox(height: 10),
                      _ColorPaletteEditor(item: item, disabled: widget.isUpdating),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: widget.isUpdating
                            ? null
                            : () => setState(() => _showRegularityOptions = !_showRegularityOptions),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Регулярность',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                            ),
                            Text(
                              _scheduleLabel(habit.scheduleType, habit.intervalDays),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showRegularityOptions ? Icons.keyboard_arrow_down : Icons.chevron_right,
                              size: 18,
                              color: const Color(0xFF8A8A8A),
                            ),
                          ],
                        ),
                      ),
                      if (_showRegularityOptions) ...[
                        const SizedBox(height: 10),
                        _RegularityOptions(item: item, disabled: widget.isUpdating),
                      ],
                      if (habit.isShared) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Совместная с ${habit.sharedWithName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A7A7A),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.isUpdating
                              ? null
                              : () => context.read<HabitsCubit>().deleteHabit(habit.id),
                          child: const Text(
                            'Удалить',
                            style: TextStyle(
                              color: Color(0xFFB42318),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed')),
          ),
        ],
      ),
    );
  }
}

class _RegularityOptions extends StatelessWidget {
  const _RegularityOptions({required this.item, required this.disabled});

  final HabitListItem item;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final habit = item.habit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _RegularityChip(
              selected: habit.scheduleType == 'daily',
              text: 'Каждый день',
              onTap: disabled
                  ? null
                  : () => context.read<HabitsCubit>().updateHabit(
                        habitId: habit.id,
                        scheduleType: 'daily',
                        intervalDays: 1,
                        weekdays: const <int>[],
                      ),
            ),
            _RegularityChip(
              selected: habit.scheduleType == 'interval',
              text: 'Интервал',
              onTap: disabled
                  ? null
                  : () => context.read<HabitsCubit>().updateHabit(
                        habitId: habit.id,
                        scheduleType: 'interval',
                        intervalDays: habit.intervalDays <= 0 ? 1 : habit.intervalDays,
                        weekdays: const <int>[],
                      ),
            ),
            _RegularityChip(
              selected: habit.scheduleType == 'weekdays',
              text: 'По дням недели',
              onTap: disabled
                  ? null
                  : () => context.read<HabitsCubit>().updateHabit(
                        habitId: habit.id,
                        scheduleType: 'weekdays',
                        weekdays: habit.weekdays.isEmpty ? const <int>[1] : habit.weekdays,
                        intervalDays: 1,
                      ),
            ),
          ],
        ),
        if (habit.scheduleType == 'interval') ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Раз в',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF444444)),
              ),
              const SizedBox(width: 10),
              _IntervalButton(
                icon: Icons.remove,
                disabled: disabled || habit.intervalDays <= 1,
                onTap: () => context.read<HabitsCubit>().updateHabit(
                      habitId: habit.id,
                      scheduleType: 'interval',
                      intervalDays: habit.intervalDays <= 1 ? 1 : habit.intervalDays - 1,
                      weekdays: const <int>[],
                    ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${habit.intervalDays <= 0 ? 1 : habit.intervalDays}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              _IntervalButton(
                icon: Icons.add,
                disabled: disabled,
                onTap: () => context.read<HabitsCubit>().updateHabit(
                      habitId: habit.id,
                      scheduleType: 'interval',
                      intervalDays: (habit.intervalDays <= 0 ? 1 : habit.intervalDays) + 1,
                      weekdays: const <int>[],
                    ),
              ),
              const SizedBox(width: 8),
              const Text(
                'дн.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF444444)),
              ),
            ],
          ),
        ],
        if (habit.scheduleType == 'weekdays') ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: List.generate(7, (index) {
              final day = index + 1;
              final selected = habit.weekdays.contains(day);
              return InkWell(
                onTap: disabled
                    ? null
                    : () {
                        final next = [...habit.weekdays];
                        if (selected) {
                          next.remove(day);
                        } else {
                          next.add(day);
                        }
                        next.sort();
                        if (next.isEmpty) {
                          return;
                        }
                        context.read<HabitsCubit>().updateHabit(
                              habitId: habit.id,
                              weekdays: next,
                              scheduleType: 'weekdays',
                              intervalDays: 1,
                            );
                      },
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF0277BD) : const Color(0xFFE7E7E7),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _weekdayShort(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _RegularityChip extends StatelessWidget {
  const _RegularityChip({
    required this.selected,
    required this.text,
    this.onTap,
  });

  final bool selected;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0277BD) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF2A2A2A),
          ),
        ),
      ),
    );
  }
}

class _IntervalButton extends StatelessWidget {
  const _IntervalButton({
    required this.icon,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFE5E5E5) : const Color(0xFFDFEDF7),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: disabled ? const Color(0xFFAAAAAA) : const Color(0xFF0277BD)),
      ),
    );
  }
}

class _ColorPaletteEditor extends StatelessWidget {
  const _ColorPaletteEditor({
    required this.item,
    required this.disabled,
  });

  static const double _dotSize = 40;
  static const double _spacing = 12;

  final HabitListItem item;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _palette14.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
        mainAxisExtent: _dotSize,
      ),
      itemBuilder: (context, index) {
        return _paletteDot(
          context,
          _palette14[index],
          size: _dotSize,
          rightGap: 0,
        );
      },
    );
  }

  Widget _paletteDot(
    BuildContext context,
    String hex, {
    required double size,
    required double rightGap,
  }) {
    final selected = _normalizeHex(hex) == _normalizeHex(item.habit.color);
    return Padding(
      padding: EdgeInsets.only(right: rightGap),
      child: InkWell(
        onTap: disabled
            ? null
            : () => context.read<HabitsCubit>().updateHabit(
                  habitId: item.habit.id,
                  color: hex,
                ),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFF0277BD) : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _hexToColor(hex),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeHex(String value) {
    var v = value.trim().toUpperCase();
    if (!v.startsWith('#')) {
      v = '#$v';
    }
    return v;
  }
}

class _EmptyHabitsCard extends StatelessWidget {
  const _EmptyHabitsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
        'Пока нет привычек. Добавьте первую по кнопке ниже.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF5A5A5A),
        ),
      ),
    );
  }
}

String _scheduleLabel(String type, int interval) {
  if (type == 'daily') {
    return 'Каждый день';
  }
  if (type == 'interval') {
    return 'Раз в $interval дн.';
  }
  if (type == 'weekdays') {
    return 'По дням недели';
  }
  return 'Каждый день';
}

String _weekdayShort(int day) {
  return switch (day) {
    1 => 'Пн',
    2 => 'Вт',
    3 => 'Ср',
    4 => 'Чт',
    5 => 'Пт',
    6 => 'Сб',
    _ => 'Вс',
  };
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

const List<String> _palette14 = [
  '#FF6B6B', // red
  '#FFA62B', // orange
  '#FACC15', // yellow
  '#4CAF50', // green
  '#41D9E2', // turquoise
  '#5AA9E6', // light blue
  '#1D4ED8', // blue
  '#BD2BFF', // violet
  '#8B5E3C', // brown
  '#64748B', // gray-blue
];

