import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/core/utils/date_utils.dart';

void main() {
  group('DateUtils', () {
    test('toDateKey zero-pads month and day', () {
      expect(DateUtils.toDateKey(DateTime(2026, 6, 7)), '2026-06-07');
      expect(DateUtils.toDateKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('fromDateKey round-trips toDateKey', () {
      final date = DateTime(2026, 1, 9);
      expect(DateUtils.fromDateKey(DateUtils.toDateKey(date)), date);
    });

    test('todayKey has YYYY-MM-DD shape', () {
      final key = DateUtils.todayKey();
      expect(key.length, 10);
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key), isTrue);
    });

    test('isSameDay ignores time of day', () {
      expect(
        DateUtils.isSameDay(DateTime(2026, 6, 7, 1), DateTime(2026, 6, 7, 23)),
        isTrue,
      );
      expect(
        DateUtils.isSameDay(DateTime(2026, 6, 7), DateTime(2026, 6, 8)),
        isFalse,
      );
    });
  });
}
