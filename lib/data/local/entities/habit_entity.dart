import 'package:isar/isar.dart';

part 'habit_entity.g.dart';

/// Isar persistence model for a habit.
///
/// Stores enums as their `name` strings (mapping lives in [HabitMapper]) so the
/// Isar generator never needs to know about the domain enums and so on-disk /
/// backup data stays stable if enum ordering changes.
@collection
class HabitEntity {
  Id isarId = Isar.autoIncrement;

  /// Domain id (UUID). Unique; replace-on-conflict enables upsert-by-uid.
  @Index(unique: true, replace: true)
  late String uid;

  @Index()
  late String userId;

  late String name;

  late String category; // HabitCategory.name
  late String scheduleType; // ScheduleType.name

  List<int> daysOfWeek = const [];

  String? timeWindowStart;
  String? timeWindowEnd;

  late int difficulty;
  String? trigger;

  late bool isActive;

  DateTime? createdAt;
  DateTime? pausedAt;
}
