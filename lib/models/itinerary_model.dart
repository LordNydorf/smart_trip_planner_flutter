import 'package:hive/hive.dart';

part 'itinerary_model.g.dart';

@HiveType(typeId: 0)
class Itinerary extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime endDate;

  @HiveField(3)
  final List<ItineraryDay> days;

  Itinerary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
  });
}

@HiveType(typeId: 1)
class ItineraryDay extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String summary;

  @HiveField(2)
  final List<ItineraryItem> items;

  ItineraryDay({
    required this.date,
    required this.summary,
    required this.items,
  });
}

@HiveType(typeId: 2)
class ItineraryItem extends HiveObject {
  @HiveField(0)
  final String time;

  @HiveField(1)
  final String activity;

  @HiveField(2)
  final String location;

  ItineraryItem({
    required this.time,
    required this.activity,
    required this.location,
  });
}
