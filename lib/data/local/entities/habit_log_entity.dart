import 'package:isar/isar.dart';

part 'habit_log_entity.g.dart';

/// Isar persistence model for a single habit log entry.
///
/// The composite index `(habitId, date)` is unique so there is exactly one log
/// per habit per calendar day, and it doubles as the lookup index for "all logs
/// for a habit".
@collection
class HabitLogEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('date')],
  )
  late String habitId;

  @Index()
  late String userId;

  late String date; // 'YYYY-MM-DD'

  late String status; // LogStatus.name

  String? skipReason; // SkipReason.name
  String? skipReasonCustom;
  int? mood;
  String? notes;

  DateTime? loggedAt;
  DateTime? completedAt;
}
