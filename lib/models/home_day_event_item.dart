class HomeDayEventTaskRef {
  const HomeDayEventTaskRef({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

class HomeDayEventItem {
  const HomeDayEventItem({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.task,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final HomeDayEventTaskRef? task;
}
