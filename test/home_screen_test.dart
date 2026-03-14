import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habical/models/event.dart';
import 'package:habical/models/home_data.dart';
import 'package:habical/models/home_event_item.dart';
import 'package:habical/models/home_feed_item.dart';
import 'package:habical/models/task.dart';
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
          Task(
            id: 'task_1',
            title: 'Чтение',
            startsAt: DateTime(2026, 3, 14, 8),
            endsAt: DateTime(2026, 3, 14, 9),
            isCompleted: false,
          ),
        ],
        events: [
          HomeEventItem(
            event: Event(
              id: 'event_1',
              title: 'Пара по ML',
              startsAt: DateTime(2026, 3, 14, 11, 10),
              endsAt: DateTime(2026, 3, 14, 12, 25),
              userId: 'user_me',
            ),
            categoryName: 'Учёба',
            categoryColorValue: 0xFFF44336,
          ),
        ],
        feedItems: [
          HomeFeedItem(
            id: 'feed_1',
            friendName: 'Кирилл',
            message: 'выполняет «Чтение» уже 10 дней подряд!',
            kind: HomeFeedKind.streak,
            createdAt: DateTime(2026, 3, 14, 7),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          currentUserId: 'user_me',
          repository: repository,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Сегодня'), findsOneWidget);
    expect(find.text('Чтение'), findsOneWidget);
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
          Task(
            id: 'task_1',
            title: 'Чтение',
            startsAt: DateTime(2026, 3, 14, 8),
            endsAt: DateTime(2026, 3, 14, 9),
            isCompleted: false,
          ),
        ],
        events: const [],
        feedItems: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          currentUserId: 'user_me',
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
  Future<HomeData> fetchHomeData({
    required String userId,
    DateTime? day,
  }) async {
    return data;
  }

  @override
  Future<void> toggleTask({
    required String taskId,
  }) async {}

  @override
  Future<List<HomeEventItem>> fetchEventsInRange({
    required String userId,
    required DateTime fromInclusive,
    required DateTime toInclusive,
  }) async {
    return data.events;
  }

  @override
  Future<HomeEventItem> addEvent({
    required String userId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    EventRepeatRule repeatRule = EventRepeatRule.none,
    String categoryName = 'Календарь',
    int categoryColorValue = 0xFF5AA9E6,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    int categoryColorValue = 0xFF5AA9E6,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent({
    required String eventId,
    required bool deleteFollowingInSeries,
  }) {
    throw UnimplementedError();
  }
}