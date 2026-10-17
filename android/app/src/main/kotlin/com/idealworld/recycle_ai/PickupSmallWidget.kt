package com.idealworld.recycle_ai

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 2x1: 가장 가까운 수거일 하나. */
class PickupSmallWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pickup_widget_small)
            val today = widgetData.getBoolean("small_today", false)
            val color = context.getColor(if (today) R.color.widget_today else R.color.widget_text)

            views.setTextViewText(R.id.small_label, widgetData.getString("small_label", "수거일"))
            views.setTextViewText(R.id.small_sub, widgetData.getString("small_sub", "앱에서 설정하세요"))
            views.setTextViewText(R.id.small_dday, widgetData.getString("small_dday", "-"))
            views.setTextColor(R.id.small_dday, color)
            views.setTextColor(R.id.small_label, color)

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
