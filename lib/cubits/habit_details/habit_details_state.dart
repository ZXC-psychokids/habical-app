import '../../models/habit_details_data.dart';

enum HabitDetailsStatus { initial, loading, loaded, failure }

class HabitDetailsState {
  const HabitDetailsState({
    required this.status,
    required this.visibleMonth,
    this.data,
    this.errorMessage,
  });

  factory HabitDetailsState.initial() {
    final now = DateTime.now();
    return HabitDetailsState(
      status: HabitDetailsStatus.initial,
      visibleMonth: DateTime(now.year, now.month, 1),
    );
  }

  final HabitDetailsStatus status;
  final DateTime visibleMonth;
  final HabitDetailsData? data;
  final String? errorMessage;

  HabitDetailsState copyWith({
    HabitDetailsStatus? status,
    DateTime? visibleMonth,
    HabitDetailsData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HabitDetailsState(
      status: status ?? this.status,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
