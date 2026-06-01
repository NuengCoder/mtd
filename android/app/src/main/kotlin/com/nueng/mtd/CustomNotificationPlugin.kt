package com.nueng.mtd

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CustomNotificationPlugin(
    private val context: Context
) {
    companion object {
        const val TAG = "CustomNotif"
        const val ACTION_NOTIFY = "com.nueng.mtd.NOTIFY"
    }

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleNotification" -> scheduleNotification(call, result)
            "cancelNotification" -> cancelNotification(call, result)
            "cancelAllNotifications" -> cancelAllNotifications(result)
            "registerSound" -> registerSound(call, result)
            else -> result.notImplemented()
        }
    }

    private fun scheduleNotification(call: MethodCall, result: MethodChannel.Result) {
        try {
            val id = call.argument<Int>("id") ?: 0
            val title = call.argument<String>("title") ?: ""
            val body = call.argument<String>("body") ?: ""
            val scheduledTimeMs = call.argument<Long>("scheduledTime") ?: 0L
            val soundUri = call.argument<String>("soundUri")

            val intent = Intent(context, NotificationReceiver::class.java).apply {
                putExtra("id", id)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("soundUri", soundUri)
                action = ACTION_NOTIFY
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                scheduledTimeMs,
                pendingIntent
            )

            Log.d(TAG, "Scheduled id=$id at=$scheduledTimeMs soundUri=$soundUri")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Schedule error: ${e.message}")
            result.error("ERROR", e.message, null)
        }
    }

    private fun cancelNotification(call: MethodCall, result: MethodChannel.Result) {
        try {
            val id = call.argument<Int>("id") ?: 0
            val intent = Intent(context, NotificationReceiver::class.java).apply {
                action = ACTION_NOTIFY
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun cancelAllNotifications(result: MethodChannel.Result) {
        try {
            // Cancel all possible notification IDs (1-1000 range)
            for (id in 1..1000) {
                val intent = Intent(context, NotificationReceiver::class.java).apply {
                    action = ACTION_NOTIFY
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    id,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager.cancel(pendingIntent)
            }
            NotificationManagerCompat.from(context).cancelAll()
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun registerSound(call: MethodCall, result: MethodChannel.Result) {
        try {
            val path = call.argument<String>("path") ?: ""
            val file = java.io.File(path)
            if (!file.exists()) {
                result.success(null)
                return
            }

            val mimeType = getMimeTypeForExtension(file.extension) ?: "audio/*"

            val values = android.content.ContentValues().apply {
                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, "mtd_${file.name}")
                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, "Notifications/")
                put(android.provider.MediaStore.MediaColumns.IS_PENDING, true)
                put(android.provider.MediaStore.Audio.Media.IS_NOTIFICATION, true)
                put(android.provider.MediaStore.Audio.Media.IS_RINGTONE, false)
                put(android.provider.MediaStore.Audio.Media.IS_ALARM, false)
                put(android.provider.MediaStore.Audio.Media.IS_MUSIC, false)
                put(android.provider.MediaStore.Audio.Media.ARTIST, "MyTodo")
            }

            val uri = context.contentResolver.insert(
                android.provider.MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                values
            )

            if (uri != null) {
                // Write the audio data
                context.contentResolver.openOutputStream(uri)?.use { output ->
                    file.inputStream().use { input ->
                        input.copyTo(output)
                    }
                }
                // Mark as not pending (available for system use)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    val updatedValues = android.content.ContentValues().apply {
                        put(android.provider.MediaStore.MediaColumns.IS_PENDING, false)
                    }
                    context.contentResolver.update(uri, updatedValues, null, null)
                }
                Log.d(TAG, "MediaStore registered: $uri")
                result.success(uri.toString())
            } else {
                Log.e(TAG, "MediaStore insert returned null for: $path")
                result.success(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "MediaStore error: ${e.message}")
            result.success(null)
        }
    }

    private fun getMimeTypeForExtension(ext: String): String? {
        return when (ext.lowercase()) {
            "mp3"  -> "audio/mpeg"
            "wav"  -> "audio/wav"
            "m4a"  -> "audio/mp4"
            "aac"  -> "audio/aac"
            "ogg"  -> "audio/ogg"
            "flac" -> "audio/flac"
            "wma"  -> "audio/x-ms-wma"
            "amr"  -> "audio/amr"
            "mid"  -> "audio/midi"
            "midi" -> "audio/midi"
            else   -> null
        }
    }
}