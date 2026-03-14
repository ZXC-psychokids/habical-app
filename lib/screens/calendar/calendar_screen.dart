import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/home_event_item.dart';
import '../../repositories/home_repository.dart';

enum CalendarScale { schedule, day, threeDays, week, month }

extension CalendarScaleMeta on CalendarScale {
  String get label => switch (this) {
    CalendarScale.schedule =>
      '\u0420\u0430\u0441\u043f\u0438\u0441\u0430\u043d\u0438\u0435',
    CalendarScale.day => '\u0414\u0435\u043d\u044c',
    CalendarScale.threeDays => '3 \u0434\u043d\u044f',
    CalendarScale.week => '\u041d\u0435\u0434\u0435\u043b\u044f',
    CalendarScale.month => '\u041c\u0435\u0441\u044f\u0446',
  };

  IconData get icon => switch (this) {
    CalendarScale.schedule => Icons.view_agenda_outlined,
    CalendarScale.day => Icons.view_day_outlined,
    CalendarScale.threeDays => Icons.view_column_outlined,
    CalendarScale.week => Icons.view_week_outlined,
    CalendarScale.month => Icons.grid_view,
  };
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.scale = CalendarScale.week,
    this.currentUserId = 'user_me',
    this.repository,
    this.onOpenDayFromMonthTap,
  });

  final CalendarScale scale;
  final String currentUserId;
  final HomeRepository? repository;
  final ValueChanged<DateTime>? onOpenDayFromMonthTap;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _hourHeight = 62.0;
  late DateTime _focusDate;
  late DateTime _now;
  Timer? _clockTimer;
  bool _didLoadInitial = false;
  bool _isLoadingEvents = false;
  String? _eventsError;
  List<HomeEventItem> _rangeEvents = const [];

  @override
  void initState() {
    super.initState();
    _focusDate = _dateOnly(DateTime.now());
    _now = DateTime.now();
    _startClockTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitial) {
      return;
    }
    _didLoadInitial = true;
    unawaited(_loadEventsForVisibleRange());
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scale != widget.scale ||
        oldWidget.currentUserId != widget.currentUserId) {
      unawaited(_loadEventsForVisibleRange());
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = _visibleDaysForScale();
    final events = _calendarEventCardsForDays(visibleDays);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          unawaited(_openQuickCreateEventSheet());
        },
        backgroundColor: const Color(0xFFF6F7F9),
        foregroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, size: 30),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              _NotionHeader(
                visibleDays: visibleDays,
                scale: widget.scale,
                focusDate: _focusDate,
                onToday: _jumpToToday,
                onPrevious: () => _shift(-1),
                onNext: () => _shift(1),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _buildScaleContent(
                    visibleDays: visibleDays,
                    events: events,
                  ),
                ),
              ),
              if (_isLoadingEvents)
                const LinearProgressIndicator(
                  minHeight: 1.5,
                  color: Color(0xFF5AA9E6),
                ),
              if (_eventsError != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFF1F1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    _eventsError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E2B2B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleContent({
    required List<DateTime> visibleDays,
    required List<CalendarEventCard> events,
  }) {
    final keySuffix = '${widget.scale.name}_${_dateKey(visibleDays.first)}';

    if (widget.scale == CalendarScale.schedule) {
      return KeyedSubtree(
        key: ValueKey('schedule_$keySuffix'),
        child: _ScheduleList(
          events: events,
          onTapEvent: _openEditEventSheet,
        ),
      );
    }

    if (widget.scale == CalendarScale.month) {
      return KeyedSubtree(
        key: ValueKey('month_${_focusDate.year}_${_focusDate.month}'),
        child: _MonthLikeBoard(
          days: visibleDays,
          events: events,
          focusDate: _focusDate,
          onTapEvent: (event) => _openDayFromMonthTap(event.startsAt),
          onTapDay: _openDayFromMonthTap,
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey('grid_$keySuffix'),
      child: _WeekTimeGrid(
        days: visibleDays,
        hourHeight: _hourHeight,
        events: events,
        now: _now,
        onTapSlot: (startAt) {
          unawaited(
            _openQuickCreateEventSheet(initialStart: startAt),
          );
        },
        onTapEvent: _openEditEventSheet,
      ),
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  List<DateTime> _visibleDaysForScale() {
    final current = _dateOnly(_focusDate);
    final monday = _monday(current);

    return switch (widget.scale) {
      CalendarScale.day => [current],
      CalendarScale.threeDays => [
        current,
        current.add(const Duration(days: 1)),
        current.add(const Duration(days: 2)),
      ],
      CalendarScale.week => List.generate(
        7,
        (index) => monday.add(Duration(days: index)),
      ),
      CalendarScale.month => _monthGridDays(current),
      CalendarScale.schedule => List.generate(
        7,
        (index) => monday.add(Duration(days: index)),
      ),
    };
  }

  void _shift(int direction) {
    if (widget.scale == CalendarScale.month) {
      setState(() {
        _focusDate = DateTime(_focusDate.year, _focusDate.month + direction, 1);
      });
      unawaited(_loadEventsForVisibleRange());
      return;
    }

    final deltaDays = switch (widget.scale) {
      CalendarScale.schedule => 7,
      CalendarScale.day => 1,
      CalendarScale.threeDays => 3,
      CalendarScale.week => 7,
      CalendarScale.month => 0,
    };
    setState(() {
      _focusDate = _focusDate.add(Duration(days: deltaDays * direction));
    });
    unawaited(_loadEventsForVisibleRange());
  }

  void _jumpToToday() {
    setState(() {
      _focusDate = _dateOnly(DateTime.now());
    });
    unawaited(_loadEventsForVisibleRange());
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _monday(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _monthGridDays(DateTime date) {
    final firstOfMonth = DateTime(date.year, date.month, 1);
    final lastOfMonth = DateTime(date.year, date.month + 1, 0);
    final firstGridDay = _monday(firstOfMonth);
    final trailingDays = DateTime.sunday - lastOfMonth.weekday;
    final lastGridDay = lastOfMonth.add(Duration(days: trailingDays));
    final totalDays = lastGridDay.difference(firstGridDay).inDays + 1;

    return List.generate(
      totalDays,
      (index) => firstGridDay.add(Duration(days: index)),
    );
  }

  void _startClockTicker() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  HomeRepository get _homeRepository {
    return widget.repository ?? RepositoryProvider.of<HomeRepository>(context);
  }

  Future<void> _loadEventsForVisibleRange() async {
    final visibleDays = _visibleDaysForScale();
    if (visibleDays.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });

    try {
      final result = await _homeRepository.fetchEventsInRange(
        userId: widget.currentUserId,
        fromInclusive: visibleDays.first,
        toInclusive: visibleDays.last,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rangeEvents = result;
        _isLoadingEvents = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingEvents = false;
        _eventsError =
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0441\u043e\u0431\u044b\u0442\u0438\u044f \u043a\u0430\u043b\u0435\u043d\u0434\u0430\u0440\u044f.';
      });
    }
  }

  List<CalendarEventCard> _calendarEventCardsForDays(List<DateTime> days) {
    final allowedDays = days.map(_dateOnly).toSet();
    final mapped =
        _rangeEvents
            .where(
              (item) => allowedDays.contains(_dateOnly(item.event.startsAt)),
            )
            .map((item) {
              final stripe = Color(item.categoryColorValue);
              return CalendarEventCard(
                eventId: item.event.id,
                title: item.event.title,
                startsAt: item.event.startsAt,
                endsAt: item.event.endsAt,
                color: _pastel(stripe),
                stripe: stripe,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final byDay = a.startsAt.compareTo(b.startsAt);
            if (byDay != 0) {
              return byDay;
            }
            return a.endsAt.compareTo(b.endsAt);
          });
    return mapped;
  }

  Color _pastel(Color color) {
    int blend(double channel) {
      final base = (channel * 255.0).round().clamp(0, 255);
      return ((base + 255 * 3) ~/ 4).clamp(0, 255);
    }

    return Color.fromARGB(
      0xFF,
      blend(color.r),
      blend(color.g),
      blend(color.b),
    );
  }

  DateTime _suggestStartDateTime() {
    final baseDay = _dateOnly(
      widget.scale == CalendarScale.month ? _now : _focusDate,
    );
    final nowDay = _dateOnly(_now);
    if (baseDay != nowDay) {
      return DateTime(baseDay.year, baseDay.month, baseDay.day, 9, 0);
    }

    var hour = _now.hour;
    var minute = _now.minute < 30 ? 30 : 0;
    if (_now.minute >= 30) {
      hour += 1;
    }
    if (hour > 23) {
      hour = 23;
      minute = 30;
    }
    return DateTime(baseDay.year, baseDay.month, baseDay.day, hour, minute);
  }

  Future<void> _openQuickCreateEventSheet({DateTime? initialStart}) async {
    final draft = await showModalBottomSheet<_CreateEventDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _NotionQuickCreateEventSheet(
          initialStart: initialStart ?? _suggestStartDateTime(),
        );
      },
    );

    if (draft == null) {
      return;
    }

    try {
      await _homeRepository.addEvent(
        userId: widget.currentUserId,
        title: draft.title,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        repeatRule: draft.repeatRule,
        categoryColorValue: draft.color.toARGB32(),
      );
      if (!mounted) {
        return;
      }
      await _loadEventsForVisibleRange();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0421\u043e\u0431\u044b\u0442\u0438\u0435 \u0434\u043e\u0431\u0430\u0432\u043b\u0435\u043d\u043e.',
          ),
          duration: Duration(milliseconds: 1300),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0434\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0441\u043e\u0431\u044b\u0442\u0438\u0435.',
          ),
        ),
      );
    }
  }

  void _openDayFromMonthTap(DateTime day) {
    final normalized = _dateOnly(day);
    setState(() {
      _focusDate = normalized;
    });
    widget.onOpenDayFromMonthTap?.call(normalized);
  }

  Future<void> _openEditEventSheet(CalendarEventCard card) async {
    // In month mode, tap should only drill down to the selected day.
    if (widget.scale == CalendarScale.month) {
      _openDayFromMonthTap(card.startsAt);
      return;
    }

    var deleteRequested = false;
    final draft = await showModalBottomSheet<_CreateEventDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _NotionQuickCreateEventSheet(
          initialStart: card.startsAt,
          initialEnd: card.endsAt,
          initialTitle: card.title,
          initialColor: card.stripe,
          showDelete: true,
          onDeleteRequested: () {
            deleteRequested = true;
          },
          submitLabel: '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c',
        );
      },
    );
    if (deleteRequested) {
      try {
        await _homeRepository.deleteEvent(
          eventId: card.eventId,
          deleteFollowingInSeries: true,
        );
        if (!mounted) {
          return;
        }
        await _loadEventsForVisibleRange();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u0421\u043e\u0431\u044b\u0442\u0438\u0435 \u0443\u0434\u0430\u043b\u0435\u043d\u043e.',
            ),
            duration: Duration(milliseconds: 1300),
          ),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0443\u0434\u0430\u043b\u0438\u0442\u044c \u0441\u043e\u0431\u044b\u0442\u0438\u0435.',
            ),
          ),
        );
      }
      return;
    }
    if (draft == null) {
      return;
    }

    try {
      await _homeRepository.updateEvent(
        eventId: card.eventId,
        title: draft.title,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        categoryColorValue: draft.color.toARGB32(),
      );

      if (!draft.repeatRule.isNone) {
        final nextStart = _nextOccurrenceStart(
          startsAt: draft.startsAt,
          repeatRule: draft.repeatRule,
        );
        final duration = draft.endsAt.difference(draft.startsAt);
        await _homeRepository.addEvent(
          userId: widget.currentUserId,
          title: draft.title,
          startsAt: nextStart,
          endsAt: nextStart.add(duration),
          repeatRule: draft.repeatRule,
          categoryColorValue: draft.color.toARGB32(),
        );
      }

      if (!mounted) {
        return;
      }
      await _loadEventsForVisibleRange();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0421\u043e\u0431\u044b\u0442\u0438\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u043e.',
          ),
          duration: Duration(milliseconds: 1300),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u0441\u043e\u0431\u044b\u0442\u0438\u0435.',
          ),
        ),
      );
    }
  }

  DateTime _nextOccurrenceStart({
    required DateTime startsAt,
    required EventRepeatRule repeatRule,
  }) {
    if (repeatRule.unit == EventRepeatUnit.day) {
      return startsAt.add(Duration(days: repeatRule.interval));
    }
    if (repeatRule.unit == EventRepeatUnit.week) {
      return startsAt.add(Duration(days: repeatRule.interval * 7));
    }
    if (repeatRule.unit == EventRepeatUnit.month) {
      final targetBase = DateTime(
        startsAt.year,
        startsAt.month + repeatRule.interval,
        1,
      );
      final daysInTargetMonth = DateTime(
        targetBase.year,
        targetBase.month + 1,
        0,
      ).day;
      final day = startsAt.day <= daysInTargetMonth
          ? startsAt.day
          : daysInTargetMonth;
      return DateTime(
        targetBase.year,
        targetBase.month,
        day,
        startsAt.hour,
        startsAt.minute,
      );
    }
    return startsAt;
  }
}

class _NotionHeader extends StatelessWidget {
  const _NotionHeader({
    required this.visibleDays,
    required this.scale,
    required this.focusDate,
    required this.onToday,
    required this.onPrevious,
    required this.onNext,
  });

  final List<DateTime> visibleDays;
  final CalendarScale scale;
  final DateTime focusDate;
  final VoidCallback onToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final firstDay = visibleDays.first;
    final lastDay = visibleDays.last;
    final titleDate = scale == CalendarScale.month ? focusDate : firstDay;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_month(titleDate.month)} ${titleDate.year}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onToday,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x15000000)),
                  ),
                  child: const Text(
                    '\u0421\u0435\u0433\u043e\u0434\u043d\u044f',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _rangeLabel(firstDay, lastDay),
                style: const TextStyle(
                  color: Color(0xFF6C7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Text(
                '\u041c\u0421\u041a',
                style: TextStyle(
                  color: Color(0xFF9AA1AD),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
        ],
      ),
    );
  }

  String _rangeLabel(DateTime firstDay, DateTime lastDay) {
    if (scale == CalendarScale.month) {
      return '${_month(focusDate.month)} ${focusDate.year}';
    }
    if (scale == CalendarScale.day) {
      return '${_weekday(firstDay.weekday)} ${firstDay.day} ${_month(firstDay.month)}';
    }
    if (firstDay.month == lastDay.month && firstDay.year == lastDay.year) {
      return '${_weekday(firstDay.weekday)} ${firstDay.day} - ${_weekday(lastDay.weekday)} ${lastDay.day} ${_month(firstDay.month)}';
    }
    return '${_weekday(firstDay.weekday)} ${firstDay.day} ${_month(firstDay.month)} - ${_weekday(lastDay.weekday)} ${lastDay.day} ${_month(lastDay.month)}';
  }

  String _month(int month) {
    const months = [
      '\u042f\u043d\u0432\u0430\u0440\u044c',
      '\u0424\u0435\u0432\u0440\u0430\u043b\u044c',
      '\u041c\u0430\u0440\u0442',
      '\u0410\u043f\u0440\u0435\u043b\u044c',
      '\u041c\u0430\u0439',
      '\u0418\u044e\u043d\u044c',
      '\u0418\u044e\u043b\u044c',
      '\u0410\u0432\u0433\u0443\u0441\u0442',
      '\u0421\u0435\u043d\u0442\u044f\u0431\u0440\u044c',
      '\u041e\u043a\u0442\u044f\u0431\u0440\u044c',
      '\u041d\u043e\u044f\u0431\u0440\u044c',
      '\u0414\u0435\u043a\u0430\u0431\u0440\u044c',
    ];
    return months[month - 1];
  }

  String _weekday(int weekday) {
    return switch (weekday) {
      DateTime.monday => '\u041f\u043d',
      DateTime.tuesday => '\u0412\u0442',
      DateTime.wednesday => '\u0421\u0440',
      DateTime.thursday => '\u0427\u0442',
      DateTime.friday => '\u041f\u0442',
      DateTime.saturday => '\u0421\u0431',
      _ => '\u0412\u0441',
    };
  }
}

class _WeekTimeGrid extends StatelessWidget {
  const _WeekTimeGrid({
    required this.days,
    required this.hourHeight,
    required this.events,
    required this.now,
    required this.onTapSlot,
    required this.onTapEvent,
  });

  final List<DateTime> days;
  final double hourHeight;
  final List<CalendarEventCard> events;
  final DateTime now;
  final ValueChanged<DateTime> onTapSlot;
  final ValueChanged<CalendarEventCard> onTapEvent;

  @override
  Widget build(BuildContext context) {
    final gridHeight = hourHeight * 24;
    final nowDay = DateTime(now.year, now.month, now.day);
    final todayIndex = days.indexWhere((day) {
      return day.year == nowDay.year &&
          day.month == nowDay.month &&
          day.day == nowDay.day;
    });
    final nowOffset = ((now.hour * 60 + now.minute) / 60.0) * hourHeight;

    return Column(
      children: [
        _DaysHeader(days: days),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: SizedBox(
              height: gridHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth - 56;
                  final dayWidth = days.isEmpty
                      ? 0.0
                      : contentWidth / days.length;
                  final lineTop = nowOffset.clamp(0.0, gridHeight - 1);
                  final markerLeft = 56 + (dayWidth * todayIndex);
                  final timeBadgeTop = (lineTop - 9).clamp(
                    0.0,
                    gridHeight - 18,
                  );

                  return Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TimeRail(hourHeight: hourHeight),
                          Expanded(
                            child: Row(
                              children: days
                                  .map((day) {
                                    final dayEvents = events
                                        .where((event) {
                                          return _sameDay(event.day, day);
                                        })
                                        .toList(growable: false);

                                    return Expanded(
                                      child: _DayEventsColumn(
                                        day: day,
                                        hourHeight: hourHeight,
                                        events: dayEvents,
                                        onTapSlot: onTapSlot,
                                        onTapEvent: onTapEvent,
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                      if (todayIndex >= 0) ...[
                        Positioned(
                          top: lineTop,
                          left: 56,
                          right: 0,
                          child: Container(
                            height: 1.5,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                        Positioned(
                          top: lineTop - 4,
                          left: markerLeft - 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: timeBadgeTop,
                          left: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatNow(now),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatNow(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _DaysHeader extends StatelessWidget {
  const _DaysHeader({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 0, 0, 0),
      child: Row(
        children: days
            .map((day) {
              final isToday =
                  day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              return Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    border: Border(
                      left: const BorderSide(color: Color(0x14000000)),
                      top: const BorderSide(color: Color(0x14000000)),
                      right: const BorderSide(color: Color(0x14000000)),
                      bottom: BorderSide(
                        color: isToday
                            ? const Color(0xFF3A8DDE)
                            : const Color(0x14000000),
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    color: isToday ? const Color(0xFFF4FAFF) : Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekday(day.weekday),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A909C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? const Color(0xFF2073C7)
                              : const Color(0xFF31353D),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  String _weekday(int weekday) {
    return switch (weekday) {
      DateTime.monday => '\u041f\u043d',
      DateTime.tuesday => '\u0412\u0442',
      DateTime.wednesday => '\u0421\u0440',
      DateTime.thursday => '\u0427\u0442',
      DateTime.friday => '\u041f\u0442',
      DateTime.saturday => '\u0421\u0431',
      _ => '\u0412\u0441',
    };
  }
}

class _TimeRail extends StatelessWidget {
  const _TimeRail({required this.hourHeight});

  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: List.generate(24, (hour) {
          return SizedBox(
            height: hourHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                _formatHour(hour),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9AA1AD),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatHour(int h) {
    if (h == 0) return '00:00';
    final hh = h.toString().padLeft(2, '0');
    return '$hh:00';
  }
}

class _DayEventsColumn extends StatelessWidget {
  const _DayEventsColumn({
    required this.day,
    required this.hourHeight,
    required this.events,
    required this.onTapSlot,
    required this.onTapEvent,
  });

  final DateTime day;
  final double hourHeight;
  final List<CalendarEventCard> events;
  final ValueChanged<DateTime> onTapSlot;
  final ValueChanged<CalendarEventCard> onTapEvent;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final tapY = details.localPosition.dy.clamp(0, hourHeight * 24);
            final minuteOfDay = ((tapY / hourHeight) * 60).floor();
            final rounded = ((minuteOfDay / 30).round() * 30).clamp(0, 1410);
            final hour = rounded ~/ 60;
            final minute = rounded % 60;
            onTapSlot(DateTime(day.year, day.month, day.day, hour, minute));
          },
          child: Column(
            children: List.generate(24, (hour) {
              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFF8FCFF) : Colors.white,
                  border: const Border(
                    left: BorderSide(color: Color(0x14000000)),
                    right: BorderSide(color: Color(0x14000000)),
                    top: BorderSide(color: Color(0x11000000)),
                  ),
                ),
              );
            }),
          ),
        ),
        ...events.map((event) {
          final top = (event.startHour + (event.startMinute / 60)) * hourHeight;
          final end = (event.endHour + (event.endMinute / 60)) * hourHeight;
          final height = (end - top).clamp(34.0, 220.0).floorToDouble();

          return Positioned(
            top: top + 1,
            left: 2,
            right: 2,
            height: height,
            child: _EventBlock(event: event, onTap: () => onTapEvent(event)),
          );
        }),
      ],
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.event, required this.onTap});

  final CalendarEventCard event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 44;
        return InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(7),
              border: Border(left: BorderSide(color: event.stripe, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF324055),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 1),
                  Text(
                    event.timeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF5F6D7D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthLikeBoard extends StatelessWidget {
  const _MonthLikeBoard({
    required this.days,
    required this.events,
    required this.focusDate,
    required this.onTapEvent,
    required this.onTapDay,
  });

  final List<DateTime> days;
  final List<CalendarEventCard> events;
  final DateTime focusDate;
  final ValueChanged<CalendarEventCard> onTapEvent;
  final ValueChanged<DateTime> onTapDay;

  @override
  Widget build(BuildContext context) {
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.skip(i).take(7).toList(growable: false));
    }

    return Column(
      children: [
        const SizedBox(height: 6),
        const _MonthWeekHeader(),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
            itemCount: weeks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final weekDays = weeks[index];
              return SizedBox(
                height: 124,
                child: Row(
                  children: weekDays
                      .map((day) {
                        final dayEvents = events
                            .where((event) => _sameDay(event.day, day))
                            .toList(growable: false);
                        return Expanded(
                          child: _MonthDayCell(
                            day: day,
                            inCurrentMonth: day.month == focusDate.month,
                            isToday: _sameDay(day, DateTime.now()),
                            events: dayEvents,
                            onTapEvent: onTapEvent,
                            onTap: () => onTapDay(day),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MonthWeekHeader extends StatelessWidget {
  const _MonthWeekHeader();

  @override
  Widget build(BuildContext context) {
    const days = [
      '\u041f\u043d',
      '\u0412\u0442',
      '\u0421\u0440',
      '\u0427\u0442',
      '\u041f\u0442',
      '\u0421\u0431',
      '\u0412\u0441',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: days
            .map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A909C),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.inCurrentMonth,
    required this.isToday,
    required this.events,
    required this.onTapEvent,
    required this.onTap,
  });

  final DateTime day;
  final bool inCurrentMonth;
  final bool isToday;
  final List<CalendarEventCard> events;
  final ValueChanged<CalendarEventCard> onTapEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = inCurrentMonth ? Colors.white : const Color(0xFFF6F7F9);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? const Color(0xFF3A8DDE) : const Color(0x14000000),
            width: isToday ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: inCurrentMonth
                      ? const Color(0xFF2E323A)
                      : const Color(0xFFADB3BF),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...events.take(3).map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
                  decoration: BoxDecoration(
                    color: event.color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border(
                      left: BorderSide(color: event.stripe, width: 2),
                    ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTapEvent(event),
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF324055),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.events, required this.onTapEvent});

  final List<CalendarEventCard> events;
  final ValueChanged<CalendarEventCard> onTapEvent;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = events[index];
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTapEvent(item),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x18000000)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.stripe,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_weekday(item.day.weekday)} ${item.day.day} - ${item.timeLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _weekday(int weekday) {
    return switch (weekday) {
      DateTime.monday => '\u041f\u043d',
      DateTime.tuesday => '\u0412\u0442',
      DateTime.wednesday => '\u0421\u0440',
      DateTime.thursday => '\u0427\u0442',
      DateTime.friday => '\u041f\u0442',
      DateTime.saturday => '\u0421\u0431',
      _ => '\u0412\u0441',
    };
  }
}

class _CreateEventDraft {
  const _CreateEventDraft({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.repeatRule,
    required this.color,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final EventRepeatRule repeatRule;
  final Color color;
}

class _NotionQuickCreateEventSheet extends StatefulWidget {
  const _NotionQuickCreateEventSheet({
    required this.initialStart,
    this.initialEnd,
    this.initialTitle = '',
    this.initialColor = const Color(0xFF5AA9E6),
    this.showDelete = false,
    this.onDeleteRequested,
    this.submitLabel = '\u0421\u043e\u0437\u0434\u0430\u0442\u044c',
  });

  final DateTime initialStart;
  final DateTime? initialEnd;
  final String initialTitle;
  final Color initialColor;
  final bool showDelete;
  final VoidCallback? onDeleteRequested;
  final String submitLabel;

  @override
  State<_NotionQuickCreateEventSheet> createState() =>
      _NotionQuickCreateEventSheetState();
}

class _NotionQuickCreateEventSheetState
    extends State<_NotionQuickCreateEventSheet> {
  static const _accentBlue = Color(0xFF0277BD);
  final TextEditingController _titleController = TextEditingController();
  late DateTime _start;
  late DateTime _end;
  EventRepeatRule _repeatRule = EventRepeatRule.none;
  Color _selectedColor = const Color(0xFF5AA9E6);

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _start = widget.initialStart;
    _end = widget.initialEnd ?? _start.add(const Duration(hours: 1));
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + insets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DCE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText:
                    '\u041d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0441\u043e\u0431\u044b\u0442\u0438\u044f',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(_start),
                  onTap: _pickDate,
                ),
                _QuickInfoChip(
                  icon: Icons.schedule_outlined,
                  label: _formatTime(_start),
                  onTap: _pickStartTime,
                ),
                _QuickInfoChip(
                  icon: Icons.schedule,
                  label: '\u0414\u043e ${_formatTime(_end)}',
                  onTap: _pickEndTime,
                ),
                _QuickInfoChip(
                  icon: Icons.repeat,
                  label: _repeatLabel(_repeatRule),
                  onTap: _pickRepeatRule,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '\u0426\u0432\u0435\u0442',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                ..._palette.map((color) {
                  final selected =
                      color.toARGB32() == _selectedColor.toARGB32();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1F2937)
                                : const Color(0x26000000),
                            width: selected ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.showDelete)
                  TextButton.icon(
                    onPressed: () {
                      widget.onDeleteRequested?.call();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      '\u0423\u0434\u0430\u043b\u0438\u0442\u044c',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                    ),
                  ),
                if (widget.showDelete) const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('\u041e\u0442\u043c\u0435\u043d\u0430'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _palette = [
    Color(0xFF5AA9E6),
    Color(0xFF31B387),
    Color(0xFFF29B38),
    Color(0xFFEF5350),
    Color(0xFF8A77E8),
  ];

  ThemeData _pickerTheme(BuildContext context) {
    final baseTheme = Theme.of(context);
    final blueScheme = ColorScheme.fromSeed(
      seedColor: _accentBlue,
      brightness: baseTheme.brightness,
    ).copyWith(
      surface: Colors.white,
    );

    return baseTheme.copyWith(
      colorScheme: blueScheme,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accentBlue),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: _accentBlue,
        headerForegroundColor: Colors.white,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
        dialBackgroundColor: Color(0xFFE3F2FD),
        hourMinuteColor: Color(0xFFE3F2FD),
        hourMinuteTextColor: Color(0xFF0D47A1),
        dayPeriodColor: Color(0xFFE3F2FD),
        dayPeriodTextColor: Color(0xFF0D47A1),
        entryModeIconColor: _accentBlue,
      ),
      bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: _pickerTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) {
      return;
    }
    final duration = _end.difference(_start);
    setState(() {
      _start = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _start.hour,
        _start.minute,
      );
      _end = _start.add(duration);
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return Theme(
          data: _pickerTheme(context),
          child: MediaQuery(
            data: mediaQuery.copyWith(alwaysUse24HourFormat: true),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
    if (picked == null) {
      return;
    }
    final duration = _end.difference(_start);
    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        picked.hour,
        picked.minute,
      );
      _end = _start.add(duration);
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return Theme(
          data: _pickerTheme(context),
          child: MediaQuery(
            data: mediaQuery.copyWith(alwaysUse24HourFormat: true),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _end = DateTime(
        _start.year,
        _start.month,
        _start.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickRepeatRule() async {
    final selected = await showModalBottomSheet<EventRepeatRule>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        const options = [
          EventRepeatRule.none,
          EventRepeatRule(unit: EventRepeatUnit.day, interval: 1),
          EventRepeatRule(unit: EventRepeatUnit.day, interval: 2),
          EventRepeatRule(unit: EventRepeatUnit.week, interval: 1),
          EventRepeatRule(unit: EventRepeatUnit.week, interval: 2),
          EventRepeatRule(unit: EventRepeatUnit.month, interval: 1),
        ];
        return Theme(
          data: _pickerTheme(context),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((rule) {
                    final selected =
                        rule.unit == _repeatRule.unit &&
                        rule.interval == _repeatRule.interval;
                    return ListTile(
                      title: Text(_repeatLabel(rule)),
                      trailing: selected
                          ? const Icon(Icons.check, color: _accentBlue)
                          : null,
                      onTap: () => Navigator.of(context).pop(rule),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() => _repeatRule = selected);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043d\u0430\u0437\u0432\u0430\u043d\u0438\u0435 \u0441\u043e\u0431\u044b\u0442\u0438\u044f.',
          ),
        ),
      );
      return;
    }

    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0412\u0440\u0435\u043c\u044f \u043e\u043a\u043e\u043d\u0447\u0430\u043d\u0438\u044f \u0434\u043e\u043b\u0436\u043d\u043e \u0431\u044b\u0442\u044c \u043f\u043e\u0437\u0436\u0435 \u043d\u0430\u0447\u0430\u043b\u0430.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _CreateEventDraft(
        title: title,
        startsAt: _start,
        endsAt: _end,
        repeatRule: _repeatRule,
        color: _selectedColor,
      ),
    );
  }

  static String _repeatLabel(EventRepeatRule rule) {
    if (rule.isNone) {
      return '\u0411\u0435\u0437 \u043f\u043e\u0432\u0442\u043e\u0440\u0430';
    }
    if (rule.unit == EventRepeatUnit.day && rule.interval == 1) {
      return '\u041a\u0430\u0436\u0434\u044b\u0439 \u0434\u0435\u043d\u044c';
    }
    if (rule.unit == EventRepeatUnit.day && rule.interval == 2) {
      return '\u0427\u0435\u0440\u0435\u0437 \u0434\u0435\u043d\u044c';
    }
    if (rule.unit == EventRepeatUnit.week && rule.interval == 1) {
      return '\u041a\u0430\u0436\u0434\u0443\u044e \u043d\u0435\u0434\u0435\u043b\u044e';
    }
    if (rule.unit == EventRepeatUnit.month && rule.interval == 1) {
      return '\u0420\u0430\u0437 \u0432 \u043c\u0435\u0441\u044f\u0446';
    }
    if (rule.unit == EventRepeatUnit.week) {
      return '\u041a\u0430\u0436\u0434\u044b\u0435 ${rule.interval} \u043d\u0435\u0434\u0435\u043b\u0438';
    }
    if (rule.unit == EventRepeatUnit.day) {
      return '\u041a\u0430\u0436\u0434\u044b\u0435 ${rule.interval} \u0434\u043d\u044f';
    }
    return '\u041a\u0430\u0436\u0434\u044b\u0435 ${rule.interval} \u043c\u0435\u0441\u044f\u0446\u0430';
  }

  static String _formatTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String _formatDate(DateTime dateTime) {
    const months = [
      '\u044f\u043d\u0432',
      '\u0444\u0435\u0432',
      '\u043c\u0430\u0440',
      '\u0430\u043f\u0440',
      '\u043c\u0430\u0439',
      '\u0438\u044e\u043d',
      '\u0438\u044e\u043b',
      '\u0430\u0432\u0433',
      '\u0441\u0435\u043d',
      '\u043e\u043a\u0442',
      '\u043d\u043e\u044f',
      '\u0434\u0435\u043a',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]}';
  }
}

class _QuickInfoChip extends StatelessWidget {
  const _QuickInfoChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x16000000)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF596273)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF414A5A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarEventCard {
  const CalendarEventCard({
    required this.eventId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.color,
    required this.stripe,
  });

  final String eventId;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final Color color;
  final Color stripe;

  DateTime get day {
    return DateTime(startsAt.year, startsAt.month, startsAt.day);
  }

  int get startHour => startsAt.hour;
  int get startMinute => startsAt.minute;
  int get endHour => endsAt.hour;
  int get endMinute => endsAt.minute;

  String get timeLabel {
    return '${_fmt(startsAt.hour, startsAt.minute)} - ${_fmt(endsAt.hour, endsAt.minute)}';
  }

  String _fmt(int h, int m) {
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
