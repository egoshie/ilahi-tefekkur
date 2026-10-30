package com.ilahi.tefekkur

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import java.util.Calendar

class HourlyVerseReceiver : BroadcastReceiver() {
    private val shortVerses = arrayOf(
        Triple("مَا وَدَّعَكَ رَبُّكَ", "Rabbin seni terk etmedi.", "Duhâ, 3"),
        Triple("إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", "Zorlukla beraber kolaylık vardır.", "İnşirah, 6"),
        Triple("إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ", "Allah sabredenlerle beraberdir.", "Bakara, 153"),
        Triple("لَا تَحْزَنْ إِنَّ ٱللَّهَ مَعَنَا", "Üzülme! Allah bizimledir.", "Tevbe, 40"),
        Triple("فَٱذْكُرُونِىٓ أَذْكُرْكُمْ", "Beni anın ki sizi anayım.", "Bakara, 152"),
        Triple("وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ", "O, her şeye kadirdir.", "Mülk, 1"),
        Triple("كُلُّ نَفْسٍ ذَآئِقَةُ ٱلْمَوْتِ", "Her nefis ölümü tadacaktır.", "Âl-i İmrân, 185"),
        Triple("فَإِنِّى قَرِيبٌ", "Şüphesiz Ben çok yakınım.", "Bakara, 186"),
        Triple("لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", "Şükrederseniz nimetimi artırırım.", "İbrâhîm, 7"),
        Triple("وَإِلَىٰ رَبِّكَ فَٱرْغَب", "Yalnızca Rabbine yönel.", "İnşirah, 8")
    )

    override fun onReceive(context: Context, intent: Intent) {
        val hourIndex = Calendar.getInstance().get(Calendar.HOUR_OF_DAY) % shortVerses.size
        val picked = shortVerses[hourIndex]

        val prefs = context.getSharedPreferences("ilahi_widget_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("arabic", picked.first)
            .putString("translation", picked.second)
            .putString("reference", picked.third)
            .putString("badge", "SAATLİK KISA AYET")
            .apply()

        VerseWidgetProvider.pushUpdateAll(context)

        val channelId = "lock_screen_hourly_short_verse"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Kilit Ekranı Saatlik Kısa Ayet Kartı",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("${picked.second} (${picked.third})")
            .setContentText(picked.first)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("${picked.first}\n\"${picked.second}\" — ${picked.third}")
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setSilent(true)
            .build()

        manager.notify(777, notification)
    }
}
