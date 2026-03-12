import 'event.dart';

class HomeEventItem {
  const HomeEventItem({
    required this.event,
    required this.categoryName,
    required this.categoryColorValue,
  });

  final Event event;
  final String categoryName;
  final int categoryColorValue;
}