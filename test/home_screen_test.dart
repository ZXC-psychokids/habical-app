import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habical/models/home_data.dart';
import 'package:habical/models/home_day_event_item.dart';
import 'package:habical/models/home_feed_entry.dart';
import 'package:habical/models/home_task_item.dart';
import 'package:habical/repositories/home_repository.dart';
import 'package:habical/screens/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows tasks, events and feed', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime(2026, 3, 14),
        tasks: [
          HomeTaskItem(
            id: 'task_1',
            title: 'Чтение',
            taskDate: DateTime(2026, 3, 14),
            position: 0,
            isCompleted: false,
          ),
        ],
        events: [
          HomeDayEventItem(
            id: 'event_1',
            title: 'Пара по ML',
            startsAt: DateTime(2026, 3, 14, 11, 10),
            endsAt: DateTime(2026, 3, 14, 12, 25),
            categoryId: 'cat_1',
            categoryName: 'Учёба',
            categoryColor: '#F44336',
          ),
        ],
        feedEntries: [
          HomeFeedEntry(
            id: 'feed_1',
            type: HomeFeedType.habitCreated,
            actor: const HomeFeedUserRef(
              id: 'user_1',
              handle: 'Кирилл',
              avatarUrl: 'https://example.com/a.png',
            ),
            relatedHabit: const HomeFeedHabitRef(
              id: 'habit_1',
              title: 'Чтение',
              color: '#FF3B30',
            ),
            createdAt: DateTime(2026, 3, 14, 7),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Сегодня'), findsOneWidget);
    expect(find.text('Чтение'), findsAtLeastNWidgets(1));
    expect(find.text('Пара по ML'), findsOneWidget);
    expect(find.text('Друзья'), findsOneWidget);
    expect(find.textContaining('Кирилл'), findsOneWidget);
    expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
  });

  testWidgets('HomeScreen hides friends block when showFriendsBlock is false', (
    WidgetTester tester,
  ) async {
    final repository = _FakeHomeRepository(
      data: HomeData(
        day: DateTime(2026, 3, 14),
        tasks: [
          HomeTaskItem(
            id: 'task_1',
            title: 'Чтение',
            taskDate: DateTime(2026, 3, 14),
            position: 0,
            isCompleted: false,
          ),
        ],
        events: const [],
        feedEntries: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          showFriendsBlock: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Друзья'), findsNothing);
    expect(find.text('Чтение'), findsOneWidget);
  });
}

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository({required this.data});

  final HomeData data;

  @override
  Future<HomeData> fetchHomeData({required DateTime day}) async {
    return data;
  }

  @override
  Future<void> toggleTask({required String taskId}) async {}

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
