import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_notification_plugin.dart';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'mtd_notify';
  static const String _channelName = 'MyTodo';

  static Future<void> init() async {
    tz.initializeTimeZones();
    _setLocalTimezone();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTap,
    );

    // Request permission
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create notification channel with sound
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Task reminders',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notify'),
      ),
    );

    debugPrint('[Notif] init done. tz=${tz.local.name}');
  }

  static void _setLocalTimezone() {
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    final Map<int, String> m = {
      -43200000: 'Pacific/Baker',
      -39600000: 'Pacific/Niue',
      -36000000: 'Pacific/Honolulu',
      -32400000: 'America/Anchorage',
      -28800000: 'America/Los_Angeles',
      -25200000: 'America/Denver',
      -21600000: 'America/Chicago',
      -18000000: 'America/New_York',
      -14400000: 'America/Halifax',
      -10800000: 'America/Sao_Paulo',
      -7200000: 'Atlantic/South_Georgia',
      -3600000: 'Atlantic/Azores',
      0: 'UTC',
      3600000: 'Europe/Paris',
      7200000: 'Europe/Athens',
      10800000: 'Europe/Moscow',
      12600000: 'Asia/Tehran',
      14400000: 'Asia/Dubai',
      16200000: 'Asia/Kabul',
      18000000: 'Asia/Karachi',
      19800000: 'Asia/Kolkata',
      20700000: 'Asia/Kathmandu',
      21600000: 'Asia/Dhaka',
      23400000: 'Asia/Rangoon',
      25200000: 'Asia/Bangkok',
      28800000: 'Asia/Shanghai',
      32400000: 'Asia/Tokyo',
      34200000: 'Australia/Darwin',
      36000000: 'Australia/Sydney',
      39600000: 'Pacific/Noumea',
      43200000: 'Pacific/Auckland',
    };
    String? tzName = m[offsetMs];
    if (tzName == null) {
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.zones.isNotEmpty && loc.zones.last.offset == offsetMs) {
          tzName = loc.name;
          break;
        }
      }
    }
    if (tzName != null) {
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
        debugPrint('[Notif] tz: $tzName');
      } catch (e) {
        debugPrint('[Notif] tz error: $e');
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle tap later
  }

  /// Schedule a notification for a task.
  /// [soundPath] — full file path to a custom sound, or null for default notify.wav.
  static Future<void> scheduleTaskNotification({
    required int taskId,
    required String taskTitle,
    required String date,
    required String time,
    required int leadMinutes,
    String? soundUri,
  }) async {
    try {
      await cancelNotification(taskId);

      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final scheduledDateTime =
      DateTime(year, month, day, hour, minute)
          .subtract(Duration(minutes: leadMinutes));

      final now = DateTime.now();
      if (scheduledDateTime.isBefore(now)) {
        debugPrint('[Notif] SKIPPED id=$taskId (in past)');
        return;
      }

      await CustomNotificationPlugin.schedule(
        id: taskId,
        title: taskTitle,
        body: '',
        scheduledTime: scheduledDateTime,
        soundUri: soundUri,
      );

      debugPrint(
          '[Notif] OK id=$taskId title="$taskTitle" at=$scheduledDateTime sound=$soundUri');
    } catch (e, st) {
      debugPrint('[Notif] ERROR: $e\n$st');
    }
  }

  /// Cancel a notification by task ID.
  static Future<void> cancelNotification(int taskId) async {
    try {
      await _plugin.cancel(taskId);
      await CustomNotificationPlugin.cancel(taskId);
    } catch (_) {}
  }

  /// Cancel all notifications.
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      await CustomNotificationPlugin.cancelAll();
    } catch (_) {}
  }

  /// Show an immediate notification (for testing).
  static Future<void> showTestNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notify'),
        ),
      ),
    );
  }

  /// Reschedule notifications for all active tasks.
  static Future<void> rescheduleAll({
    required List<Task> tasks,
    required int leadMinutes,
    Map<int, String?>? soundUris,
  }) async {
    await cancelAll();
    for (final task in tasks) {
      if (task.isComplete || task.time == null) continue;
      await scheduleTaskNotification(
        taskId: task.id!,
        taskTitle: task.title,
        date: task.date,
        time: task.time!,
        leadMinutes: leadMinutes,
        soundUri: soundUris?[task.id],
      );
    }
  }
}

/// Provider to access notification service.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});