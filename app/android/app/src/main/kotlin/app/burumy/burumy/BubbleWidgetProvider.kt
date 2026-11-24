// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Home-screen widget: draws one soap bubble per waiting friend (their
// colour and first letter only). It never knows what is inside a bubble.
package app.burumy.burumy

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class BubbleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val list = try { JSONArray(widgetData.getString("bubbles", "[]")) } catch (e: Exception) { JSONArray() }
        val art = draw(list)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.bubble_widget)
            views.setImageViewBitmap(R.id.bubble_art, art)
            val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("burumy://bubbles"))
            views.setOnClickPendingIntent(R.id.bubble_root, open)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun draw(list: JSONArray): Bitmap {
        val w = 440
        val h = 440
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        // Calm empty state: one faint bubble.
        if (list.length() == 0) {
            bubble(c, w / 2f, h / 2f, 70f, Color.parseColor("#8E8E93"), null, 0.35f)
            return bmp
        }
        // Fixed, gently scattered spots for up to 6 bubbles.
        val spots = listOf(
            floatArrayOf(0.30f, 0.32f, 0.22f), floatArrayOf(0.70f, 0.28f, 0.17f), floatArrayOf(0.55f, 0.66f, 0.20f),
            floatArrayOf(0.22f, 0.74f, 0.13f), floatArrayOf(0.84f, 0.62f, 0.12f), floatArrayOf(0.48f, 0.12f, 0.09f),
        )
        for (i in 0 until minOf(list.length(), spots.size)) {
            val o = list.getJSONObject(i)
            val color = try { Color.parseColor("#" + o.getString("c")) } catch (e: Exception) { Color.GRAY }
            val s = spots[i]
            bubble(c, s[0] * w, s[1] * h, s[2] * w, color, o.optString("l", null), 1f)
        }
        return bmp
    }

    private fun bubble(c: Canvas, x: Float, y: Float, r: Float, color: Int, letter: String?, alpha: Float) {
        fun a(col: Int, k: Float) = Color.argb((Color.alpha(col) * k * alpha).toInt(), Color.red(col), Color.green(col), Color.blue(col))
        val body = Paint(Paint.ANTI_ALIAS_FLAG)
        body.shader = RadialGradient(x, y, r, intArrayOf(a(color, 0.18f), a(color, 0.42f), a(color, 0.85f)), floatArrayOf(0f, 0.72f, 1f), Shader.TileMode.CLAMP)
        c.drawCircle(x, y, r, body)
        val rim = Paint(Paint.ANTI_ALIAS_FLAG)
        rim.style = Paint.Style.STROKE
        rim.strokeWidth = maxOf(2f, r * 0.06f)
        rim.color = a(color, 1f)
        c.drawCircle(x, y, r - rim.strokeWidth / 2, rim)
        val shine = Paint(Paint.ANTI_ALIAS_FLAG)
        shine.color = Color.argb((190 * alpha).toInt(), 255, 255, 255)
        c.drawOval(RectF(x - r * 0.62f, y - r * 0.58f, x - r * 0.08f, y - r * 0.26f), shine)
        if (letter != null && letter.isNotEmpty()) {
            val t = Paint(Paint.ANTI_ALIAS_FLAG)
            t.color = Color.WHITE
            t.textSize = r * 0.7f
            t.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            t.textAlign = Paint.Align.CENTER
            t.setShadowLayer(6f, 0f, 0f, color)
            c.drawText(letter, x, y - (t.descent() + t.ascent()) / 2, t)
        }
    }
}
