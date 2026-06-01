import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';

/// Background task names
class BackgroundTasks {
  static const String autoDeploy = 'autoDeployWeeklyPlans';
  static const String homeworkReminder = 'homeworkReminder';
  static const String rescheduleNotifications = 'rescheduleNotifications';
}

/// Callback dispatcher — must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case BackgroundTasks.autoDeploy:
          await _executeAutoDeploy();
          break;
        case BackgroundTasks.homeworkReminder:
          await _executeHomeworkReminder();
          break;
      }
    } catch (e) {
      debugPrint('Background task error: $e');
    }
    return true;
  });
}

Future<void> _executeAutoDeploy() async {
  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;
  final now = DateTime.now();
  final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  final dayOfYear = int.parse(DateFormat('D').format(now));
  final isoWeek = ((dayOfYear - now.weekday + 10) / 7).floor();
  final isOddWeek = isoWeek % 2 != 0;

  final settingsResult = await db.query('settings', where: 'key = ?', whereArgs: ['week_type_flipped']);
  final flipped = settingsResult.isNotEmpty && settingsResult.first['value'] == '1';
  final effectiveOdd = flipped ? !isOddWeek : isOddWeek;

  final plans = await db.query('weekly_plans', where: 'auto_deploy = ?', whereArgs: [1]);

  final leadSettings = await db.query('settings', where: 'key = ?', whereArgs: ['notify_lead_minutes']);
  final leadMinutes = int.tryParse(leadSettings.firstOrNull?['value'] as String? ?? '0') ?? 0;

  // Preload all user sounds for URI resolution
  final allSoundsRows = await db.query('user_sounds');
  final soundMap = <int, String?>{};
  for (final row in allSoundsRows) {
    final id = row['id'] as int;
    soundMap[id] = row['media_uri'] as String?;
  }

  int totalDeployed = 0;
  final nowStr = DateTime.now().toIso8601String();

  for (int i = 0; i < 7; i++) {
    final date = DateTime(now.year, now.month, now.day + i);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final weekday = weekdays[date.weekday - 1];

    final existingResults = await db.query('tasks', where: 'date = ?', whereArgs: [dateStr]);
    final existingTitles = existingResults.map((e) => {
      'title': e['title'] as String,
      'time': e['time'] as String?,
    }).toList();

    for (final plan in plans) {
      final planName = plan['name'] as String;

      if (planName == 'Class (Odd)' && !effectiveOdd) continue;
      if (planName == 'Class (Even)' && effectiveOdd) continue;

      final tasks = await db.query(
        'weekly_plan_tasks',
        where: 'weekly_plan_id = ? AND (weekday = ? OR weekday = ?)',
        whereArgs: [plan['id'], weekday, 'all'],
      );

      for (final wt in tasks) {
        final title = wt['title'] as String;
        final time = wt['time'] as String?;

        final isDuplicate = existingTitles.any((t) => t['title'] == title && t['time'] == time);
        if (isDuplicate) continue;

        final taskId = await db.insert('tasks', {
          'title': title,
          'date': dateStr,
          'time': time,
          'notify_time': wt['notify_time'],
          'image_id': wt['image_id'],
          'sound_id': wt['sound_id'],
          'is_complete': 0,
          'created_at': nowStr,
          'updated_at': nowStr,
        });
        totalDeployed++;

        // Schedule notification for deployed tasks with a time set
        if (time != null && time.isNotEmpty) {
          final soundId = wt['sound_id'] as int?;
          final soundUri = soundId != null ? soundMap[soundId] : null;
          try {
            await NotificationService.scheduleTaskNotification(
              taskId: taskId,
              taskTitle: title,
              date: dateStr,
              time: time,
              leadMinutes: leadMinutes,
              soundUri: soundUri,
            );
          } catch (e) {
            debugPrint('[AutoDeploy] Notif failed for task=$taskId: $e');
          }
        }
      }
    }
  }

  debugPrint('[AutoDeploy] total=$totalDeployed');
}

Future<void> _executeHomeworkReminder() async {
  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;
  final homeworks = await db.query('homeworks', where: 'is_submitted = ?', whereArgs: [0]);
  final count = homeworks.length;
  debugPrint('[HomeworkReminder] pending=$count');
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  /// Schedule the daily auto-deploy at 00:30.
  static Future<void> scheduleAutoDeploy() async {
    await Workmanager().registerPeriodicTask(
      BackgroundTasks.autoDeploy,
      BackgroundTasks.autoDeploy,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
      initialDelay: _timeUntilNext(0, 30), // 00:30
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }

  /// Schedule the daily homework reminder at 07:00.
  static Future<void> scheduleHomeworkReminder() async {
    await Workmanager().registerPeriodicTask(
      BackgroundTasks.homeworkReminder,
      BackgroundTasks.homeworkReminder,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
      initialDelay: _timeUntilNext(7, 0), // 07:00
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }

  /// Calculate duration until the next occurrence of a given time (HH, mm).
  static Duration _timeUntilNext(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }

  /// Cancel all background tasks.
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}

final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  return BackgroundService();
});