class CreateHabitSubmission {
  const CreateHabitSubmission({required this.title, required this.startDate});

  final String title;
  final DateTime startDate;
}

class CreateHabitState {
  const CreateHabitState({
    required this.name,
    required this.startDate,
    required this.isSaving,
    this.errorMessage,
    this.submission,
  });

  factory CreateHabitState.initial() {
    final now = DateTime.now();
    return CreateHabitState(
      name: '',
      startDate: DateTime(now.year, now.month, now.day),
      isSaving: false,
    );
  }

  final String name;
  final DateTime startDate;
  final bool isSaving;
  final String? errorMessage;
  final CreateHabitSubmission? submission;

  CreateHabitState copyWith({
    String? name,
    DateTime? startDate,
    bool? isSaving,
    String? errorMessage,
    CreateHabitSubmission? submission,
    bool clearError = false,
    bool clearSubmission = false,
  }) {
    return CreateHabitState(
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submission: clearSubmission ? null : (submission ?? this.submission),
    );
  }
}
