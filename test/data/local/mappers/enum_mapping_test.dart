import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/data/local/mappers/enum_mapping.dart';
import 'package:habitview/domain/models/habit.dart';
import 'package:habitview/domain/models/habit_log.dart';

void main() {
  group('enumByName', () {
    test('maps a stored name back to its enum value', () {
      expect(
        enumByName(HabitCategory.values, 'fitness', HabitCategory.other),
        HabitCategory.fitness,
      );
      expect(
        enumByName(LogStatus.values, 'skipped', LogStatus.done),
        LogStatus.skipped,
      );
    });

    test('falls back when the name is null or unknown', () {
      expect(
        enumByName(HabitCategory.values, null, HabitCategory.other),
        HabitCategory.other,
      );
      expect(
        enumByName(HabitCategory.values, 'not-a-real-category',
            HabitCategory.productivity),
        HabitCategory.productivity,
      );
    });
  });

  group('enumByNameOrNull', () {
    test('returns the matching value or null', () {
      expect(
        enumByNameOrNull(SkipReason.values, 'forgot'),
        SkipReason.forgot,
      );
      expect(enumByNameOrNull(SkipReason.values, null), isNull);
      expect(enumByNameOrNull(SkipReason.values, 'nope'), isNull);
    });
  });

  test('every enum value round-trips through its name', () {
    for (final c in HabitCategory.values) {
      expect(enumByName(HabitCategory.values, c.name, HabitCategory.other), c);
    }
    for (final s in SkipReason.values) {
      expect(enumByNameOrNull(SkipReason.values, s.name), s);
    }
  });
}
