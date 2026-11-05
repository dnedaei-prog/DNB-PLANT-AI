import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  static bool ready = false;
  static bool exactAllowed = false;

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    ready = true;
  }

  static int _minute(String value) {
    final normalized = value
        .replaceAll('۰','0').replaceAll('۱','1').replaceAll('۲','2')
        .replaceAll('۳','3').replaceAll('۴','4').replaceAll('۵','5')
        .replaceAll('۶','6').replaceAll('۷','7').replaceAll('۸','8')
        .replaceAll('۹','9').replaceAll('٠','0').replaceAll('١','1')
        .replaceAll('٢','2').replaceAll('٣','3').replaceAll('٤','4')
        .replaceAll('٥','5').replaceAll('٦','6').replaceAll('٧','7')
        .replaceAll('٨','8').replaceAll('٩','9');
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(normalized);
    if (m == null) return -1;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  static DateTime respectQuietHours(DateTime input, String quiet) {
    final parts = quiet.split('تا');
    if (parts.length != 2) return input;
    final start = _minute(parts[0]);
    final end = _minute(parts[1]);
    if (start < 0 || end < 0 || start == end) return input;
    final minute = input.hour * 60 + input.minute;
    final inside = start < end
        ? minute >= start && minute < end
        : minute >= start || minute < end;
    if (!inside) return input;
    var result = DateTime(input.year, input.month, input.day, end ~/ 60, end % 60);
    if (start > end && minute >= start) result = result.add(const Duration(days: 1));
    if (!result.isAfter(input)) result = result.add(const Duration(days: 1));
    return result;
  }

  static Future<void> schedule({
    required int id,
    required String plant,
    required String title,
    required DateTime when,
    required String repeat,
    required int priority,
    required String quietHours,
  }) async {
    if (!ready) await initialize();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    exactAllowed = await android?.requestExactAlarmsPermission() ?? false;
    final adjusted = respectQuietHours(when, quietHours);
    final channel = priority >= 2 ? 'dnb_urgent' : priority == 1 ? 'dnb_important' : 'dnb_normal';
    final details = NotificationDetails(android: AndroidNotificationDetails(
      channel,
      priority >= 2 ? 'هشدار فوری' : priority == 1 ? 'یادآوری مهم' : 'یادآوری عادی',
      channelDescription: 'یادآوری‌های مراقبت از گیاهان DNB',
      importance: priority >= 2 ? Importance.max : priority == 1 ? Importance.high : Importance.defaultImportance,
      priority: priority >= 2 ? Priority.max : priority == 1 ? Priority.high : Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    ));
    await plugin.zonedSchedule(
      id,
      'DNB • $plant',
      title,
      tz.TZDateTime.from(adjusted, tz.local),
      details,
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: repeat == 'روزانه'
          ? DateTimeComponents.time
          : repeat == 'هفتگی'
              ? DateTimeComponents.dayOfWeekAndTime
              : null,
    );
  }

  static Future<void> cancel(int id) => plugin.cancel(id);
  static Future<void> snooze({
    required int id,
    required String plant,
    required String title,
    required int priority,
    required String quietHours,
  }) async {
    await schedule(
      id: id + 1000000,
      plant: plant,
      title: 'یادآوری به تعویق افتاده: $title',
      when: DateTime.now().add(const Duration(hours: 1)),
      repeat: 'یک‌بار',
      priority: priority,
      quietHours: quietHours,
    );
  }
}
