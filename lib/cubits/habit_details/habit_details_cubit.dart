import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/habits_repository.dart';
import 'habit_details_state.dart';

class HabitDetailsCubit extends Cubit<HabitDetailsState> {
  HabitDetailsCubit({
    required HabitsRepository repository,
    required String habitId,
  }) : _repository = repository,
       _habitId = habitId,
       super(HabitDetailsState.initial());

  final HabitsRepository _repository;
  final String _habitId;

  Future<void> load() async {
    emit(state.copyWith(status: HabitDetailsStatus.loading, clearError: true));

    try {
      final data = await _repository.fetchHabitDetails(habitId: _habitId);
      emit(
        state.copyWith(
          status: HabitDetailsStatus.loaded,
          data: data,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HabitDetailsStatus.failure,
          errorMessage: 'Не удалось загрузить детали привычки.',
        ),
      );
    }
  }

  void showPrevMonth() {
    final prev = DateTime(
      state.visibleMonth.year,
      state.visibleMonth.month - 1,
      1,
    );
    emit(state.copyWith(visibleMonth: prev));
  }

  void showNextMonth() {
    final next = DateTime(
      state.visibleMonth.year,
      state.visibleMonth.month + 1,
      1,
    );
    emit(state.copyWith(visibleMonth: next));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
