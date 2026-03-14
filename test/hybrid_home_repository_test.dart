import 'package:flutter_test/flutter_test.dart';
import 'package:habical/models/event.dart';
import 'package:habical/models/home_data.dart';
import 'package:habical/models/home_event_item.dart';
import 'package:habical/models/home_feed_item.dart';
import 'package:habical/models/task.dart';
import 'package:habical/repositories/home_repository.dart';
import 'package:habical/repositories/hybrid_home_repository.dart';
import 'package:habical/repositories/in_memory_app_store.dart';

void main() {
  group('HybridHomeRepository', () {
    test(
      'keeps remote feed and overlays changed local task plus new local event',
      () async {
        final now = DateTime(2026, 3, 14, 9);
        final store = InMemoryAppStore(now: now);
        final selectedDay = DateTime(2026, 3, 14);

        final localTask = store.tasksForUser('user_me').firstWhere(
          (task) =>
              task.startsAt.year == selectedDay.year &&
              task.startsAt.month == selectedDay.month &&
              task.startsAt.day == selectedDay.day &&
              task.isCompleted == false,
        );

        final repository = HybridHomeRepository(
          remoteRepository: _FakeHomeRepository(
            data: HomeData(
              day: selectedDay,
              tasks: [
                Task(
                  id: 'remote_task_same_slot',
                  title: localTask.title,
                  startsAt: localTask.startsAt,
                  endsAt: localTask.endsAt,
                  isCompleted: false,
                ),
                Task(
                  id: 'remote_task_only',
                  title: 'Remote task only',
                  startsAt: DateTime(2026, 3, 14, 7),
                  endsAt: DateTime(2026, 3, 14, 8),
                  isCompleted: false,
                ),
              ],
              events: [
                HomeEventItem(
                  event: Event(
                    id: 'remote_event_1',
                    title: 'Remote event',
                    startsAt: DateTime(2026, 3, 14, 10),
                    endsAt: DateTime(2026, 3, 14, 11),
                    userId: 'user_me',
                  ),
                  categoryName: 'Remote',
                  categoryColorValue: 0xFF0000FF,
                ),
              ],
              feedItems: [
                HomeFeedItem(
                  id: 'remote_feed_1',
                  friendName: 'Remote friend',
                  message: 'remote news',
                  kind: HomeFeedKind.streak,
                  createdAt: DateTime(2026, 3, 14, 8),
                ),
              ],
            ),
          ),
          store: store,
        );

        store.toggleTaskById(localTask.id);

        final newLocalEvent = store.addEvent(
          userId: 'user_me',
          title: 'Local event',
          startsAt: DateTime(2026, 3, 14, 18),
          endsAt: DateTime(2026, 3, 14, 19),
          repeatUnitKey: 'none',
          repeatInterval: 1,
          categoryName: 'Local',
          categoryColorValue: 0xFF00AA00,
        );

        final home = await repository.fetchHomeData(
          userId: 'user_me',
          day: selectedDay,
        );

        expect(
          home.tasks.any((task) => task.id == 'remote_task_only'),
          isTrue,
        );

        final matchedTask = home.tasks.firstWhere(
          (task) => task.id == 'remote_task_same_slot',
        );
        expect(matchedTask.isCompleted, isTrue);

        expect(
          home.events.any((item) => item.event.id == 'remote_event_1'),
          isTrue,
        );

        expect(
          home.events.any((item) => item.event.id == newLocalEvent.event.id),
          isTrue,
        );

        expect(
          home.feedItems.any((item) => item.id == 'remote_feed_1'),
          isTrue,
        );
      },
    );

    test(
      'toggleTask updates remote task through local matched task mapping',
      () async {
        final now = DateTime(2026, 3, 14, 9);
        final store = InMemoryAppStore(now: now);
        final selectedDay = DateTime(2026, 3, 14);

        final localTask = store.tasksForUser('user_me').firstWhere(
          (task) =>
              task.startsAt.year == selectedDay.year &&
              task.startsAt.month == selectedDay.month &&
              task.startsAt.day == selectedDay.day &&
              task.isCompleted == false,
        );

        final repository = HybridHomeRepository(
          remoteRepository: _FakeHomeRepository(
            data: HomeData(
              day: selectedDay,
              tasks: [
                Task(
                  id: 'remote_task_same_slot',
                  title: localTask.title,
                  startsAt: localTask.startsAt,
                  endsAt: localTask.endsAt,
                  isCompleted: false,
                ),
              ],
              events: const [],
              feedItems: const [],
            ),
          ),
          store: store,
        );

        await repository.fetchHomeData(
          userId: 'user_me',
          day: selectedDay,
        );

        await repository.toggleTask(taskId: 'remote_task_same_slot');

        final homeAfterToggle = await repository.fetchHomeData(
          userId: 'user_me',
          day: selectedDay,
        );

        final toggledTask = homeAfterToggle.tasks.firstWhere(
          (task) => task.id == 'remote_task_same_slot',
        );

        expect(toggledTask.isCompleted, isTrue);
      },
    );
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