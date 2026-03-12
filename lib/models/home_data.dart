import 'home_event_item.dart';
import 'home_feed_item.dart';
import 'task.dart';

class HomeData {
  const HomeData({
    required this.day,
    required this.tasks,
    required this.events,
    required this.feedItems,
  });

  final DateTime day;
  final List<Task> tasks;
  final List<HomeEventItem> events;
  final List<HomeFeedItem> feedItems;
}