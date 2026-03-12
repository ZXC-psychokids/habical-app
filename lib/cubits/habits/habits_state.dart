import '../../models/habit_list_item.dart';

enum HabitsStatus { initial, loading, loaded, failure }

class HabitsState {
  const HabitsState({
    required this.status,
    required this.items,
    this.errorMessage,
  });

  factory HabitsState.initial() {
    return const HabitsState(
      status: HabitsStatus.initial,
      items: <HabitListItem>[],
    );
  }

  final HabitsStatus status;
  final List<HabitListItem> items;
  final String? errorMessage;

  HabitsState copyWith({
    HabitsStatus? status,
    List<HabitListItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HabitsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
