package com.ilahi.tefekkur

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ilahi.tefekkur/native_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableHourlyLockScreenVerse" -> {
                        val arabic = call.argument<String>("arabic") ?: ""
                        val translation = call.argument<String>("translation") ?: ""
                        val reference = call.argument<String>("reference") ?: ""
                        val badge = call.argument<String>("badge") ?: "SAATLİK KISA AYET"

                        val prefs = getSharedPreferences("ilahi_widget_prefs", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("arabic", arabic)
                            .putString("translation", translation)
                            .putString("reference", reference)
                            .putString("badge", badge)
                            .apply()

                        VerseWidgetProvider.pushUpdateAll(applicationContext)

                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, HourlyVerseReceiver::class.java)
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            777,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        alarmManager.setInexactRepeating(
                            AlarmManager.RTC,
                            System.currentTimeMillis() + AlarmManager.INTERVAL_HOUR,
                            AlarmManager.INTERVAL_HOUR,
                            pendingIntent
                        )
                        result.success(true)
                    }
                    "stopHourlyLockScreenVerse" -> {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, HourlyVerseReceiver::class.java)
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            777,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        alarmManager.cancel(pendingIntent)
                        result.success(true)
                    }
                    "scheduleExactAdhan" -> {
                        val id = call.argument<Int>("id") ?: 101
                        val prayerName = call.argument<String>("prayerName") ?: "Namaz"
                        val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: System.currentTimeMillis()
                        val maqam = call.argument<String>("maqam") ?: "Hicaz Makamı"

                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, PrayerAlarmReceiver::class.java).apply {
                            putExtra("prayerName", prayerName)
                            putExtra("maqam", maqam)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            id,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                alarmManager.setExactAndAllowWhileIdle(
                                    AlarmManager.RTC_WAKEUP,
                                    triggerAtMillis,
                                    pendingIntent
                                )
                            } else {
                                alarmManager.setExact(
                                    AlarmManager.RTC_WAKEUP,
                                    triggerAtMillis,
                                    pendingIntent
                                )
                            }
                            result.success(true)
                        } catch (e: SecurityException) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
