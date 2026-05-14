import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_logger.dart';
import '../../models/home_data.dart';
import '../../models/home_task_item.dart';
import '../../repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required HomeRepository repository,
  }) : _repository = repository,
       super(HomeState.initial());

  final HomeRepository _repository;
  bool _isReordering = false;

  Future<void> loadHome({DateTime? day, bool showLoading = true}) async {
    final targetDay = _normalize(day ?? state.selectedDay);
    AppLogger.i('HomeCubit.loadHome started day=$targetDay');

    if (showLoading) {
      emit(
        state.copyWith(
          status: HomeStatus.loading,
          selectedDay: targetDay,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedDay: targetDay,
          clearError: true,
        ),
      );
    }

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
      AppLogger.i('HomeCubit.loadHome completed day=$targetDay');
    } catch (error, stackTrace) {
      AppLogger.e('HomeCubit.loadHome failed', error, stackTrace);
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
    final data = state.data;
    if (data == null) {
      return;
    }

    final index = data.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) {
      return;
    }

    final updatedTasks = [...data.tasks];
    final current = updatedTasks[index];
    updatedTasks[index] = current.copyWith(isCompleted: !current.isCompleted);

    emit(
      state.copyWith(
        status: HomeStatus.loaded,
        data: HomeData(
          day: data.day,
          tasks: updatedTasks,
          events: data.events,
          feedEntries: data.feedEntries,
          nextFeedCursor: data.nextFeedCursor,
        ),
        clearError: true,
      ),
    );

    try {
      await _repository.toggleTask(taskId: taskId);
      await loadHome(day: state.selectedDay, showLoading: false);
    } catch (error, stackTrace) {
      AppLogger.e('HomeCubit.toggleTask failed taskId=$taskId', error, stackTrace);
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          data: data,
        ),
      );
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
    } catch (error, stackTrace) {
      AppLogger.e('HomeCubit.createTask failed', error, stackTrace);
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
    } catch (error, stackTrace) {
      AppLogger.e('HomeCubit.updateTask failed taskId=$taskId', error, stackTrace);
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
    } catch (error, stackTrace) {
      AppLogger.e('HomeCubit.deleteTask failed taskId=$taskId', error, stackTrace);
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
    if (_isReordering) {
      return;
    }
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
    if (targetIndex == fromIndex) {
      return;
    }
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

    emit(
      state.copyWith(
        status: HomeStatus.loaded,
        data: data == null
            ? null
            : HomeData(
                day: data.day,
                tasks: reordered,
                events: data.events,
                feedEntries: data.feedEntries,
                nextFeedCursor: data.nextFeedCursor,
              ),
        clearError: true,
      ),
    );

    _isReordering = true;
    try {
      await _repository.reorderTasks(items: requestItems);
      await loadHome(day: state.selectedDay, showLoading: false);
    } catch (error, stackTrace) {
      AppLogger.e('HomeCubit.moveTask failed taskId=$taskId', error, stackTrace);
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Не удалось изменить порядок задач.',
        ),
      );
    } finally {
      _isReordering = false;
    }
  }

  Future<void> linkTaskToEvent({
    required String taskId,
    required String eventId,
  }) async {
    try {
      await _repository.linkTaskToEvent(taskId: taskId, eventId: eventId);
      await loadHome(day: state.selectedDay);
    } catch (error, stackTrace) {
      AppLogger.e(
        'HomeCubit.linkTaskToEvent failed taskId=$taskId eventId=$eventId',
        error,
        stackTrace,
      );
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
    } catch (error, stackTrace) {
      AppLogger.e(
        'HomeCubit.unlinkTaskFromEvent failed taskId=$taskId',
        error,
        stackTrace,
      );
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
