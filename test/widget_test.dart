import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habical/app/app.dart';
import 'package:habical/repositories/habits_repository.dart';

void main() {
  testWidgets('Habits screen shows habits and streaks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Read 30 minutes'), findsOneWidget);
    expect(find.text('Gym workout'), findsOneWidget);
    expect(find.textContaining('days'), findsWidgets);
  });

  testWidgets('Habit details screen shows completion calendar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Read 30 minutes'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.byKey(ValueKey('day-$todayKey-completed')), findsOneWidget);

    final tomorrow = now.add(const Duration(days: 1));
    if (tomorrow.month == now.month && tomorrow.year == now.year) {
      final tomorrowKey =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      expect(find.byKey(ValueKey('day-$tomorrowKey-none')), findsOneWidget);
    }
  });

  testWidgets('Past days for daily habit are not left unmarked', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gym workout'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final previousDayInMonth = now.day > 1 ? now.day - 1 : 1;
    final targetDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${previousDayInMonth.toString().padLeft(2, '0')}';

    final noneFinder = find.byKey(ValueKey('day-$targetDate-none'));
    final completedFinder = find.byKey(ValueKey('day-$targetDate-completed'));
    final missedFinder = find.byKey(ValueKey('day-$targetDate-missed'));

    expect(noneFinder, findsNothing);
    expect(
      completedFinder.evaluate().isNotEmpty ||
          missedFinder.evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('Tap add habit button opens create habit screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add new habit'));
    await tester.pumpAndSettle();

    expect(find.text('New Habit'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Start date'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
  });

  testWidgets('Create habit adds new item to list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HabicalApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add new habit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('habit-name-field')),
      'Morning journaling',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Morning journaling'), findsOneWidget);
  });

  test('Repository creates daily tasks from selected start date', () async {
    final repository = InMemoryHabitsRepository(now: DateTime(2026, 3, 10));
    final habit = await repository.addHabit(
      userId: 'user_me',
      title: 'Daily habit',
      startDate: DateTime(2026, 3, 1),
    );

    final details = await repository.fetchHabitDetails(habitId: habit.id);
    expect(details.tasks, isNotEmpty);

    final firstSixDays = details.tasks
        .take(6)
        .map(
          (task) => DateTime(
            task.startsAt.year,
            task.startsAt.month,
            task.startsAt.day,
          ),
        )
        .toList(growable: false);

    expect(firstSixDays.first, DateTime(2026, 3, 1));
    for (var i = 1; i < firstSixDays.length; i++) {
      expect(firstSixDays[i].difference(firstSixDays[i - 1]).inDays, 1);
    }
  });
}
