import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/habit_calendar_day_summary.dart';
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
      final now = DateTime.now();
      final from = _dayOnly(now.subtract(const Duration(days: 7)));
      final to = _dayOnly(now.add(const Duration(days: 14)));
      final results = await Future.wait([
        _repository.fetchHabits(userId: _userId),
        _repository.fetchCalendarSummary(
          fromInclusive: from,
          toInclusive: to,
        ),
      ]);
      final items = results[0] as List<HabitListItem>;
      final summary = results[1] as List<HabitCalendarDaySummary>;
      emit(
        state.copyWith(
          status: HabitsStatus.loaded,
          items: items,
          calendarSummary: summary,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          errorMessage: _mapError(error, fallback: 'Не удалось загрузить привычки.'),
        ),
      );
    }
  }

  Future<void> addHabit({
    required String title,
    required DateTime startDate,
    String color = '#5AA9E6',
    String scheduleType = 'daily',
    int intervalDays = 1,
    List<int> weekdays = const <int>[],
  }) async {
    try {
      await _repository.addHabit(
        userId: _userId,
        title: title,
        startDate: startDate,
        color: color,
        scheduleType: scheduleType,
        intervalDays: intervalDays,
        weekdays: weekdays,
      );
      await loadHabits();
    } catch (error) {
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          errorMessage: _mapError(error, fallback: 'Не удалось добавить привычку.'),
        ),
      );
    }
  }

  void toggleExpandedHabit(String habitId) {
    if (state.expandedHabitId == habitId) {
      emit(state.copyWith(clearExpandedHabit: true));
      return;
    }
    emit(state.copyWith(expandedHabitId: habitId));
  }

  Future<void> updateHabit({
    required String habitId,
    String? title,
    String? color,
    String? scheduleType,
    int? intervalDays,
    List<int>? weekdays,
  }) async {
    emit(state.copyWith(isUpdatingHabit: true, clearError: true));
    try {
      await _repository.updateHabit(
        habitId: habitId,
        title: title,
        color: color,
        scheduleType: scheduleType,
        intervalDays: intervalDays,
        weekdays: weekdays,
      );
      await loadHabits();
      emit(state.copyWith(isUpdatingHabit: false));
    } catch (error) {
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          isUpdatingHabit: false,
          errorMessage: _mapError(error, fallback: 'Не удалось обновить привычку.'),
        ),
      );
    }
  }

  Future<void> deleteHabit(String habitId) async {
    emit(state.copyWith(isUpdatingHabit: true, clearError: true));
    try {
      await _repository.deleteHabit(habitId: habitId);
      await loadHabits();
      emit(
        state.copyWith(
          isUpdatingHabit: false,
          clearExpandedHabit: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HabitsStatus.failure,
          isUpdatingHabit: false,
          errorMessage: _mapError(error, fallback: 'Не удалось удалить привычку.'),
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

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _mapError(Object error, {required String fallback}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'] ?? data['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return status == null ? message : '$message (HTTP $status)';
        }
      }
      if (status != null) {
        return '$fallback (HTTP $status)';
      }
    }

    if (error is StateError) {
      return '$fallback (${error.message})';
    }

    return fallback;
  }
}
