import 'package:flutter_test/flutter_test.dart';
import 'package:habical/repositories/friends_repository.dart';
import 'package:habical/repositories/home_repository.dart';
import 'package:habical/repositories/in_memory_app_store.dart';

void main() {
  test('shared habit appears on friend home after creation', () async {
    final now = DateTime(2026, 3, 13, 12);
    final store = InMemoryAppStore(now: now);
    final friendsRepository = InMemoryFriendsRepository(store: store);
    final homeRepository = InMemoryHomeRepository(store: store);

    await friendsRepository.createSharedHabit(
      userId: 'user_me',
      friendId: 'friend_2',
      title: 'Совместная привычка',
    );

    final day = DateTime(now.year, now.month, now.day);
    final friendHome = await homeRepository.fetchHomeData(
      userId: 'user_liza',
      day: day,
    );

    expect(
      friendHome.tasks.any((task) => task.title == 'Совместная привычка'),
      isTrue,
    );
  });
}