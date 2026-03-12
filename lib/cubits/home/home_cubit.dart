import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required HomeRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId,
       super(HomeState.initial());

  final HomeRepository _repository;
  final String _userId;

  Future<void> loadHome({DateTime? day}) async {
    final targetDay = _normalize(day ?? state.selectedDay);

    emit(
      state.copyWith(
        status: HomeStatus.loading,
        selectedDay: targetDay,
        clearError: true,
      ),
    );

    try {
      final data = await _repository.fetchHomeData(
        userId: _userId,
        day: targetDay,
      );

      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          selectedDay: targetDay,
          data: data,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          selectedDay: targetDay,
          errorMessage: 'Не удалось загрузить домашний экран.',
        ),
      );
    }
  }

  Future<void> toggleTask(String taskId) async {
    try {
      await _repository.toggleTask(taskId: taskId);
      await loadHome(day: state.selectedDay);
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось обновить задачу.',
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  DateTime _normalize(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}