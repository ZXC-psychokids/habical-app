import 'home_day_event_item.dart';
import 'home_feed_entry.dart';
import 'home_task_item.dart';

class HomeData {
  const HomeData({
    required this.day,
    required this.tasks,
    required this.events,
    required this.feedEntries,
    this.nextFeedCursor,
  });

  final DateTime day;
  final List<HomeTaskItem> tasks;
  final List<HomeDayEventItem> events;
  final List<HomeFeedEntry> feedEntries;
  final String? nextFeedCursor;
}
