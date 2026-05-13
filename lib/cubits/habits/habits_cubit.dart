import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_logger.dart';
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
    AppLogger.i('HabitsCubit.loadHabits started');
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
      AppLogger.i('HabitsCubit.loadHabits completed, count=${items.length}');
    } catch (error, stackTrace) {
      AppLogger.e('HabitsCubit.loadHabits failed', error, stackTrace);
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          errorMessage: 'Не удалось загрузить привычки.',
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
    } catch (error, stackTrace) {
      AppLogger.e('HabitsCubit.addHabit failed', error, stackTrace);
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          errorMessage: 'Не удалось добавить привычку.',
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
