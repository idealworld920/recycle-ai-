package com.idealworld.recycle_ai

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 4x2: 세 종류 D-day. */
class PickupMediumWidget : HomeWidgetProvider() {
    private val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2)
    private val labelIds = intArrayOf(R.id.m0_label, R.id.m1_label, R.id.m2_label)
    private val subIds = intArrayOf(R.id.m0_sub, R.id.m1_sub, R.id.m2_sub)
    private val ddayIds = intArrayOf(R.id.m0_dday, R.id.m1_dday, R.id.m2_dday)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pickup_widget_medium)
            val configured = widgetData.getBoolean("configured", false)
            views.setViewVisibility(R.id.medium_empty, if (configured) View.GONE else View.VISIBLE)

            for (i in 0 until 3) {
                val label = widgetData.getString("m${i}_label", "") ?: ""
                if (label.isEmpty()) {
                    views.setViewVisibility(rowIds[i], View.GONE)
                    continue
                }
                val today = widgetData.getBoolean("m${i}_today", false)
                val color = context.getColor(if (today) R.color.widget_today else R.color.widget_text)
                views.setViewVisibility(rowIds[i], View.VISIBLE)
                views.setTextViewText(labelIds[i], label)
                views.setTextViewText(subIds[i], widgetData.getString("m${i}_sub", ""))
                views.setTextViewText(ddayIds[i], widgetData.getString("m${i}_dday", ""))
                views.setTextColor(labelIds[i], color)
                views.setTextColor(ddayIds[i], color)
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
