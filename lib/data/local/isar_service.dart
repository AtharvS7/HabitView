import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'entities/habit_entity.dart';
import 'entities/habit_log_entity.dart';
import 'entities/insight_entity.dart';
import 'entities/settings_entity.dart';
import 'entities/user_progress_entity.dart';

/// Opens and exposes the single Isar instance backing the whole app.
///
/// The schema list below must include every `@collection`. The `*.g.dart`
/// schema symbols (e.g. [HabitEntitySchema]) are produced by `build_runner`;
/// run `dart run build_runner build` before the first compile.
class IsarService {
  IsarService._();

  static const String instanceName = 'habitview';

  static final List<CollectionSchema<dynamic>> schemas = [
    HabitEntitySchema,
    HabitLogEntitySchema,
    InsightEntitySchema,
    UserProgressEntitySchema,
    SettingsEntitySchema,
  ];

  /// Opens (or returns the already-open) Isar instance.
  static Future<Isar> open() async {
    final existing = Isar.getInstance(instanceName);
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      schemas,
      directory: dir.path,
      name: instanceName,
    );
  }
}
