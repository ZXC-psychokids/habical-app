import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/habit_list_item.dart';
import '../../repositories/habits_repository.dart';
import 'habits_state.dart';

class HabitsCubit extends Cubit<HabitsState> {
  HabitsCubit({required HabitsRepository repository, required String userId})
    : _repository = repository,
      _userId = userId,
      super(HabitsState.initial());

  final HabitsRepository _repository;
  final String _userId;

  HabitsRepository get repository => _repository;

  Future<void> loadHabits() async {
    emit(state.copyWith(status: HabitsStatus.loading, clearError: true));

    try {
      final items = await _repository.fetchHabits(userId: _userId);
      emit(
        state.copyWith(
          status: HabitsStatus.loaded,
          items: items,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          errorMessage: 'Failed to load habits.',
        ),
      );
    }
  }

  Future<void> addHabit({
    required String title,
    required DateTime startDate,
  }) async {
    try {
      await _repository.addHabit(
        userId: _userId,
        title: title,
        startDate: startDate,
      );
      await loadHabits();
    } catch (_) {
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          errorMessage: 'Failed to add habit.',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  HabitListItem? findItem(String habitId) {
    for (final item in state.items) {
      if (item.habit.id == habitId) {
        return item;
      }
    }
    return null;
  }
}
