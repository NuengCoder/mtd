import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class CustomNotificationPlugin {
  static const _channel = MethodChannel('com.nueng.mtd/notification');

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundUri,
  }) async {
    try {
      await _channel.invokeMethod('scheduleNotification', {
        'id': id,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.millisecondsSinceEpoch,
        'soundUri': soundUri,
      });
      debugPrint('[CustomNotif] Scheduled id=$id at=$scheduledTime sound=$soundUri');
    } catch (e) {
      debugPrint('[CustomNotif] ERROR: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _channel.invokeMethod('cancelNotification', {'id': id});
    } catch (e) {
      debugPrint('[CustomNotif] Cancel ERROR: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod('cancelAllNotifications');
    } catch (e) {
      debugPrint('[CustomNotif] CancelAll ERROR: $e');
    }
  }

  static Future<String?> registerSound(String filePath) async {
    try {
      final uri = await _channel.invokeMethod<String>('registerSound', {
        'path': filePath,
      });
      return uri;
    } catch (e) {
      debugPrint('[CustomNotif] registerSound ERROR: $e');
      return null;
    }
  }
}