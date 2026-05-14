import 'package:flutter_test/flutter_test.dart';
import 'package:habical/cubits/create_habit/create_habit_cubit.dart';

void main() {
  group('CreateHabitCubit', () {
    test('shows validation error when user submits empty name', () {
      final cubit = CreateHabitCubit();

      cubit.submit();

      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.submission, isNull);

      cubit.close();
    });

    test('creates submission with trimmed title', () {
      final cubit = CreateHabitCubit();

      cubit.updateName('   New habit   ');
      cubit.submit();

      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.submission, isNotNull);
      expect(cubit.state.submission!.title, 'New habit');
      expect(cubit.state.submission!.color, '#5AA9E6');

      cubit.close();
    });

    test('updates start date without time part', () {
      final cubit = CreateHabitCubit();
      final picked = DateTime(2026, 3, 14, 18, 45);

      cubit.updateStartDate(picked);

      expect(cubit.state.startDate.year, 2026);
      expect(cubit.state.startDate.month, 3);
      expect(cubit.state.startDate.day, 14);
      expect(cubit.state.startDate.hour, 0);
      expect(cubit.state.startDate.minute, 0);

      cubit.close();
    });
  });
}
