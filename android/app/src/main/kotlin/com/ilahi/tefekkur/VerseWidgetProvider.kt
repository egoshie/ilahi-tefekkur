package com.ilahi.tefekkur

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews

class VerseWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("ilahi_widget_prefs", Context.MODE_PRIVATE)
            val arabic = prefs.getString("arabic", "مَا وَدَّعَكَ رَبُّكَ")
            val translation = prefs.getString("translation", "Rabbin seni terk etmedi.")
            val reference = prefs.getString("reference", "Duhâ, 3")
            val badge = prefs.getString("badge", "SAATLİK KISA AYET")

            val views = RemoteViews(context.packageName, R.layout.verse_widget_layout)
            views.setTextViewText(R.id.widget_badge, "İLAHİ TEFEKKÜR • $badge")
            views.setTextViewText(R.id.widget_arabic, arabic)
            views.setTextViewText(R.id.widget_translation, "\"$translation\"")
            views.setTextViewText(R.id.widget_reference, "— $reference")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun pushUpdateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, VerseWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, manager, id)
            }
        }
    }
}
