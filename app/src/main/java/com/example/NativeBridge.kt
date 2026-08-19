package com.example

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.webkit.JavascriptInterface
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

class NativeBridge(
  private val context: Context,
  private val onSyncReceived: ((dataType: String, data: String) -> Unit)? = null,
  private val onSnackbarMessage: ((String) -> Unit)? = null
) {
  companion object {
    const val CHANNEL_ID = "rossofuoco_portal_updates"
    const val CHANNEL_NAME = "Aggiornamenti Portale RossoFuoco"
    const val JS_INTERFACE_NAME = "AndroidBridge"

    fun createNotificationChannel(context: Context) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
          CHANNEL_ID,
          CHANNEL_NAME,
          NotificationManager.IMPORTANCE_HIGH
        ).apply {
          description = "Notifiche e avvisi di servizio dal portale RossoFuoco"
          enableVibration(true)
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
      }
    }
  }

  init {
    createNotificationChannel(context)
  }

  @JavascriptInterface
  fun postNotification(title: String, message: String) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
        // Fallback to local snackbar if notification permission is not yet granted
        onSnackbarMessage?.invoke("$title: $message")
        return
      }
    }

    try {
      val intent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
      }
      val pendingIntent = PendingIntent.getActivity(
        context,
        System.currentTimeMillis().toInt(),
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      )

      val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle(title.ifEmpty { "RossoFuoco Personale" })
        .setContentText(message)
        .setStyle(NotificationCompat.BigTextStyle().bigText(message))
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .setAutoCancel(true)
        .setContentIntent(pendingIntent)
        .build()

      val notificationManager = NotificationManagerCompat.from(context)
      notificationManager.notify((System.currentTimeMillis() % 100000).toInt(), notification)
    } catch (e: Exception) {
      onSnackbarMessage?.invoke("$title: $message")
    }
  }

  @JavascriptInterface
  fun syncData(dataType: String, payloadJson: String) {
    CoroutineScope(Dispatchers.Main).launch {
      onSyncReceived?.invoke(dataType, payloadJson)
      onSnackbarMessage?.invoke("Dati sincronizzati: $dataType")
    }
  }

  @JavascriptInterface
  fun showToast(message: String) {
    CoroutineScope(Dispatchers.Main).launch {
      Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
  }

  @JavascriptInterface
  fun showSnackbar(message: String) {
    CoroutineScope(Dispatchers.Main).launch {
      onSnackbarMessage?.invoke(message)
    }
  }

  @JavascriptInterface
  fun getAppInfo(): String {
    val json = JSONObject()
    json.put("appName", "RossoFuoco Personale")
    json.put("version", "1.0")
    json.put("platform", "Android")
    json.put("hybridSync", true)
    json.put("timestamp", System.currentTimeMillis())
    return json.toString()
  }
}
