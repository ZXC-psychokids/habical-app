import '../../models/habit_list_item.dart';
import '../../models/habit_calendar_day_summary.dart';

enum HabitsStatus { initial, loading, loaded, failure }

class HabitsState {
  const HabitsState({
    required this.status,
    required this.items,
    required this.calendarSummary,
    required this.expandedHabitId,
    required this.isUpdatingHabit,
    this.errorMessage,
  });

  factory HabitsState.initial() {
    return const HabitsState(
      status: HabitsStatus.initial,
      items: <HabitListItem>[],
      calendarSummary: <HabitCalendarDaySummary>[],
      expandedHabitId: null,
      isUpdatingHabit: false,
    );
  }

  final HabitsStatus status;
  final List<HabitListItem> items;
  final List<HabitCalendarDaySummary> calendarSummary;
  final String? expandedHabitId;
  final bool isUpdatingHabit;
  final String? errorMessage;

  HabitsState copyWith({
    HabitsStatus? status,
    List<HabitListItem>? items,
    List<HabitCalendarDaySummary>? calendarSummary,
    String? expandedHabitId,
    bool clearExpandedHabit = false,
    bool? isUpdatingHabit,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HabitsState(
      status: status ?? this.status,
      items: items ?? this.items,
      calendarSummary: calendarSummary ?? this.calendarSummary,
      expandedHabitId: clearExpandedHabit
          ? null
          : (expandedHabitId ?? this.expandedHabitId),
      isUpdatingHabit: isUpdatingHabit ?? this.isUpdatingHabit,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
