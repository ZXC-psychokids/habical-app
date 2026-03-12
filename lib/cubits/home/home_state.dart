import '../../models/home_data.dart';

enum HomeStatus {
  initial,
  loading,
  loaded,
  failure,
}

class HomeState {
  const HomeState({
    required this.status,
    required this.selectedDay,
    this.data,
    this.errorMessage,
  });

  factory HomeState.initial() {
    final now = DateTime.now();
    return HomeState(
      status: HomeStatus.initial,
      selectedDay: DateTime(now.year, now.month, now.day),
    );
  }

  final HomeStatus status;
  final DateTime selectedDay;
  final HomeData? data;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    DateTime? selectedDay,
    HomeData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedDay: selectedDay ?? this.selectedDay,
      data: data ?? this.data,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}