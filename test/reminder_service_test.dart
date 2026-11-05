import 'package:flutter_test/flutter_test.dart';
import 'package:dnb_plant_ai/reminder_service.dart';

void main() {
  group('ReminderService quiet hours', () {
    test('keeps reminders outside quiet hours unchanged', () {
      final input = DateTime(2026, 11, 5, 10, 30);
      expect(
        ReminderService.respectQuietHours(input, '۲۲:۰۰ تا ۰۸:۰۰'),
        input,
      );
    });

    test('moves an overnight quiet-hour reminder to the morning', () {
      final input = DateTime(2026, 11, 5, 7, 15);
      expect(
        ReminderService.respectQuietHours(input, '۲۲:۰۰ تا ۰۸:۰۰'),
        DateTime(2026, 11, 5, 8, 0),
      );
    });

    test('moves an evening reminder to the next morning', () {
      final input = DateTime(2026, 11, 5, 22, 30);
      expect(
        ReminderService.respectQuietHours(input, '۲۲:۰۰ تا ۰۸:۰۰'),
        DateTime(2026, 11, 6, 8, 0),
      );
    });

    test('supports quiet hours within the same day', () {
      final input = DateTime(2026, 11, 5, 13, 30);
      expect(
        ReminderService.respectQuietHours(input, '۱۲:۰۰ تا ۱۴:۰۰'),
        DateTime(2026, 11, 5, 14, 0),
      );
    });
  });
}
