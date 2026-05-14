import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habical/cubits/navigation/navigation_cubit.dart';
import 'package:habical/models/home_data.dart';
import 'package:habical/models/home_day_event_item.dart';
import 'package:habical/models/home_feed_entry.dart';
import 'package:habical/models/home_task_item.dart';
import 'package:habical/repositories/home_repository.dart';
import 'package:habical/screens/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows tasks, events and feed', (WidgetTester tester) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime.now(),
        tasks: [
          HomeTaskItem(
            id: 'task_1',
            title: 'Task reading',
            taskDate: DateTime.now(),
            position: 0,
            isCompleted: false,
          ),
        ],
        events: [
          HomeDayEventItem(
            id: 'event_1',
            title: 'ML lecture',
            startsAt: DateTime.now().add(const Duration(hours: 2)),
            endsAt: DateTime.now().add(const Duration(hours: 3)),
            categoryId: 'cat_1',
            categoryName: 'Study',
            categoryColor: '#F44336',
          ),
        ],
        feedEntries: [
          HomeFeedEntry(
            id: 'feed_1',
            type: HomeFeedType.habitCreated,
            actor: const HomeFeedUserRef(
              id: 'user_1',
              handle: 'kirill',
              avatarUrl: 'https://example.com/a.png',
            ),
            relatedHabit: const HomeFeedHabitRef(
              id: 'habit_1',
              title: 'Reading',
              color: '#FF3B30',
            ),
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_testApp(HomeScreen(repository: repository)));

    await tester.pumpAndSettle();

    expect(find.text('Habical'), findsOneWidget);
    expect(find.text('Task reading'), findsOneWidget);
    expect(find.text('ML lecture'), findsOneWidget);
    expect(find.text('Друзья'), findsOneWidget);
    expect(find.textContaining('kirill'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('HomeScreen hides friends block when showFriendsBlock is false', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime.now(),
        tasks: [
          HomeTaskItem(
            id: 'task_1',
            title: 'Task reading',
            taskDate: DateTime.now(),
            position: 0,
            isCompleted: false,
          ),
        ],
        events: const [],
        feedEntries: const [],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        HomeScreen(
          repository: repository,
          showFriendsBlock: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Друзья'), findsNothing);
    expect(find.text('Task reading'), findsOneWidget);
  });

  testWidgets('HomeScreen shows app bar title when enabled', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime.now(),
        tasks: const [],
        events: const [],
        feedEntries: const [],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        HomeScreen(
          repository: repository,
          showAppBar: true,
          appBarTitle: 'Главная',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Главная'), findsOneWidget);
  });

  testWidgets('Task toggle is disabled when canToggleTasks is false', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime.now(),
        tasks: [
          HomeTaskItem(
            id: 'task_1',
            title: 'Completed task',
            taskDate: DateTime.now(),
            position: 0,
            isCompleted: true,
          ),
        ],
        events: const [],
        feedEntries: const [],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        HomeScreen(
          repository: repository,
          canToggleTasks: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repository.toggleCalls, 0);
  });

  testWidgets('Task dialog validates empty title on save', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime.now(),
        tasks: const [],
        events: const [],
        feedEntries: const [],
      ),
    );

    await tester.pumpWidget(_testApp(HomeScreen(repository: repository)));

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Новая задача'), findsOneWidget);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Название задачи не может быть пустым'), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  return BlocProvider(
    create: (_) => NavigationCubit(),
    child: MaterialApp(home: child),
  );
}

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository({required this.data});

  final HomeData data;
  int toggleCalls = 0;

  @override
  Future<HomeData> fetchHomeData({required DateTime day}) async {
    return data;
  }

  @override
  Future<void> toggleTask({required String taskId}) async {
    toggleCalls++;
  }

  @override
  Future<HomeTaskItem> createTask({
    required String title,
    required DateTime taskDate,
    required int position,
    String? manualColor,
  }) async {
    return HomeTaskItem(
      id: 'new_task',
      title: title,
      taskDate: taskDate,
      position: position,
      isCompleted: false,
      manualColor: manualColor,
    );
  }

  @override
  Future<HomeTaskItem> updateTask({
    required String taskId,
    required HomeTaskUpdateInput input,
  }) async {
    return data.tasks.first.copyWith(title: input.title);
  }

  @override
  Future<void> deleteTask({required String taskId}) async {}

  @override
  Future<void> reorderTasks({required List<HomeTaskReorderItem> items}) async {}

  @override
  Future<HomeTaskItem> linkTaskToEvent({
    required String taskId,
    required String eventId,
  }) async {
    return data.tasks.first;
  }

  @override
  Future<void> unlinkTaskFromEvent({required String taskId}) async {}
}
