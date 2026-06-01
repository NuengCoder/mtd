package com.nueng.mtd

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresPermission
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.net.toUri

class NotificationReceiver : BroadcastReceiver() {
    companion object {
        const val DEFAULT_CHANNEL_ID = "mtd_custom_notify_default"
        const val DEFAULT_CHANNEL_NAME = "MyTodo"
    }

    @RequiresPermission(Manifest.permission.POST_NOTIFICATIONS)
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val title = intent.getStringExtra("title") ?: "MyTodo"
        val body = intent.getStringExtra("body") ?: ""
        val soundUri = intent.getStringExtra("soundUri")

        val channelId = createNotificationChannel(context, soundUri)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            // Pre-O: builder.setSound() is the only way to set sound
            if (!soundUri.isNullOrEmpty()) {
                try {
                    builder.setSound(soundUri.toUri())
                } catch (e: Exception) {
                    Log.e(CustomNotificationPlugin.TAG, "Sound error: ${e.message}")
                    builder.setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
                }
            } else {
                builder.setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            }
        }
        // On O+ the channel handles the sound; builder.setDefaults/setSound is ignored

        try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
            Log.d(CustomNotificationPlugin.TAG, "Notification fired id=$id channel=$channelId sound=$soundUri")
        } catch (e: Exception) {
            Log.e(CustomNotificationPlugin.TAG, "Notify error: ${e.message}")
        }
    }

    private fun createNotificationChannel(context: Context, soundUri: String?): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return DEFAULT_CHANNEL_ID

        val manager = context.getSystemService(NotificationManager::class.java)

        val channelId: String
        val channelName: String

        if (!soundUri.isNullOrEmpty()) {
            channelId = "mtd_custom_${soundUri.hashCode().toUShort()}"
            channelName = "MyTodo Sound ${soundUri.hashCode().toUShort()}"

            val existing = manager.getNotificationChannel(channelId)
            if (existing != null) return channelId

            val uri: Uri = try {
                soundUri.toUri()
            } catch (_: Exception) {
                Log.e(CustomNotificationPlugin.TAG, "Invalid sound URI: $soundUri")
                return DEFAULT_CHANNEL_ID
            }

            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "MyTodo custom sound"
                setSound(
                    uri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
            Log.d(CustomNotificationPlugin.TAG, "Created channel $channelId for sound $soundUri")
            return channelId
        } else {
            channelId = DEFAULT_CHANNEL_ID

            val existing = manager.getNotificationChannel(channelId)
            if (existing != null) return channelId

            val defaultSoundUri = Uri.parse("android.resource://${context.packageName}/raw/notify")
            val channel = NotificationChannel(
                channelId,
                DEFAULT_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "MyTodo notifications"
                setSound(
                    defaultSoundUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
            Log.d(CustomNotificationPlugin.TAG, "Created default channel with notify.wav")
            return channelId
        }
    }
}