import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/home_task_item.dart';
import '../../repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required HomeRepository repository,
  }) : _repository = repository,
       super(HomeState.initial());

  final HomeRepository _repository;

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
      final data = await _repository.fetchHomeData(day: targetDay);

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

  Future<void> showPreviousDay() async {
    await loadHome(day: state.selectedDay.subtract(const Duration(days: 1)));
  }

  Future<void> showNextDay() async {
    await loadHome(day: state.selectedDay.add(const Duration(days: 1)));
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

  Future<HomeTaskItem?> createTask({
    required String title,
    String? manualColor,
  }) async {
    final current = state.data;
    final nextPosition = current == null ? 0 : current.tasks.length;

    try {
      final created = await _repository.createTask(
        title: title,
        taskDate: state.selectedDay,
        position: nextPosition,
        manualColor: manualColor,
      );
      await loadHome(day: state.selectedDay);
      return created;
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось создать задачу.',
        ),
      );
      return null;
    }
  }

  Future<void> updateTask({
    required String taskId,
    required HomeTaskUpdateInput input,
  }) async {
    try {
      await _repository.updateTask(taskId: taskId, input: input);
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

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId: taskId);
      await loadHome(day: state.selectedDay);
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось удалить задачу.',
        ),
      );
    }
  }

  Future<void> moveTask({
    required String taskId,
    required int newPosition,
  }) async {
    final data = state.data;
    if (data == null) {
      return;
    }

    final clamped = newPosition < 0 ? 0 : newPosition;
    final reordered = [...data.tasks];
    final fromIndex = reordered.indexWhere((task) => task.id == taskId);
    if (fromIndex < 0) {
      return;
    }

    final item = reordered.removeAt(fromIndex);
    final targetIndex = clamped > reordered.length ? reordered.length : clamped;
    reordered.insert(targetIndex, item);

    final requestItems = reordered
        .asMap()
        .entries
        .map(
          (entry) => HomeTaskReorderItem(
            taskId: entry.value.id,
            position: entry.key,
            taskDate: state.selectedDay,
          ),
        )
        .toList(growable: false);

    try {
      await _repository.reorderTasks(items: requestItems);
      await loadHome(day: state.selectedDay);
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось изменить порядок задач.',
        ),
      );
    }
  }

  Future<void> linkTaskToEvent({
    required String taskId,
    required String eventId,
  }) async {
    try {
      await _repository.linkTaskToEvent(taskId: taskId, eventId: eventId);
      await loadHome(day: state.selectedDay);
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось привязать задачу к событию.',
        ),
      );
    }
  }

  Future<void> unlinkTaskFromEvent(String taskId) async {
    try {
      await _repository.unlinkTaskFromEvent(taskId: taskId);
      await loadHome(day: state.selectedDay);
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось отвязать задачу от события.',
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
