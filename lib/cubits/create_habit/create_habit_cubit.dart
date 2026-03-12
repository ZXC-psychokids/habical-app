import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_habit_state.dart';

class CreateHabitCubit extends Cubit<CreateHabitState> {
  CreateHabitCubit() : super(CreateHabitState.initial());

  void updateName(String value) {
    emit(state.copyWith(name: value, clearError: true, clearSubmission: true));
  }

  void updateStartDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    emit(
      state.copyWith(
        startDate: normalized,
        clearError: true,
        clearSubmission: true,
      ),
    );
  }

  void submit() {
    final title = state.name.trim();
    if (title.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Enter habit name.',
          clearSubmission: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(isSaving: true, clearError: true, clearSubmission: true),
    );
    emit(
      state.copyWith(
        isSaving: false,
        submission: CreateHabitSubmission(
          title: title,
          startDate: state.startDate,
        ),
      ),
    );
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void clearSubmission() {
    emit(state.copyWith(clearSubmission: true));
  }
}
