// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Our own bridge to the phone's built-in features (no outside plugin):
// where I am right now, and the newest photos and videos for the "+" sheet.
// Nothing here talks to the internet; results go only to our app.
package app.burumy.burumy

import android.Manifest
import android.content.Context
import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class PhoneChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val main = Handler(Looper.getMainLooper())
    private val work = Executors.newSingleThreadExecutor()
    private var waiting: ((Boolean) -> Unit)? = null

    init {
        MethodChannel(messenger, "app.burumy/phone").setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "location" -> ask(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), any = true) { ok ->
                if (ok) locate(result) else result.error("denied", null, null)
            }
            "recent" -> ask(mediaPermissions(), any = true) { ok ->
                if (!ok) result.success(null) else work.execute {
                    val list = try { recent(call.argument<Int>("limit") ?: 60) } catch (e: Exception) { null }
                    main.post { result.success(list) }
                }
            }
            "load" -> work.execute {
                val got = try { load(call.argument<String>("id") ?: "") } catch (e: Exception) { null }
                main.post { if (got == null) result.error("gone", null, null) else result.success(got) }
            }
            "battery" -> {
                val bm = activity.getSystemService(Context.BATTERY_SERVICE) as? android.os.BatteryManager
                val pct = bm?.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
                result.success(if (pct in 0..100) pct else null)
            }
            "network" -> {
                // "wifi", "cellular" or "none" (for auto-download settings).
                val cm = activity.getSystemService(Context.CONNECTIVITY_SERVICE) as? android.net.ConnectivityManager
                val caps = cm?.getNetworkCapabilities(cm.activeNetwork)
                result.success(
                    when {
                        caps == null -> "none"
                        caps.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                        else -> "wifi"
                    }
                )
            }
            "settings" -> {
                activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + activity.packageName)))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ---- permissions ----

    private fun mediaPermissions(): Array<String> = when {
        Build.VERSION.SDK_INT >= 34 -> arrayOf(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO, Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)
        Build.VERSION.SDK_INT >= 33 -> arrayOf(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO)
        else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
    }

    private fun granted(p: String) = activity.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    /// Asks only when needed. [any]: one of them is enough (e.g. "only the
    /// photos I chose" on Android 14).
    private fun ask(perms: Array<String>, any: Boolean, then: (Boolean) -> Unit) {
        if (perms.any { granted(it) }) return then(true)
        if (waiting != null) return then(false)
        waiting = then
        activity.requestPermissions(perms, REQUEST)
    }

    fun onPermissionResult(code: Int, results: IntArray) {
        if (code != REQUEST) return
        val then = waiting ?: return
        waiting = null
        then(results.any { it == PackageManager.PERMISSION_GRANTED })
    }

    // ---- location ----

    private fun locate(result: MethodChannel.Result) {
        val lm = activity.getSystemService(LocationManager::class.java)
        val providers = buildList {
            if (Build.VERSION.SDK_INT >= 31) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
        }.filter { runCatching { lm.isProviderEnabled(it) }.getOrDefault(false) }
        if (providers.isEmpty()) return result.error("off", null, null)
        var done = false
        fun finish(l: Location?) {
            if (done) return
            done = true
            if (l == null) result.error("unavailable", null, null)
            else result.success(mapOf("lat" to l.latitude, "lon" to l.longitude, "accuracy" to (if (l.hasAccuracy()) l.accuracy.toDouble() else null)))
        }
        try {
            val provider = providers.first()
            if (Build.VERSION.SDK_INT >= 30) {
                lm.getCurrentLocation(provider, null, activity.mainExecutor) { finish(it) }
            } else {
                @Suppress("DEPRECATION")
                lm.requestSingleUpdate(provider, { finish(it) }, Looper.getMainLooper())
            }
            // No fix in 15 s: the freshest one the phone already has (at most 2 minutes old).
            main.postDelayed({
                val last = providers.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }.maxByOrNull { it.time }
                finish(last?.takeIf { System.currentTimeMillis() - it.time < 120_000 })
            }, 15_000)
        } catch (e: SecurityException) {
            finish(null)
        }
    }

    // ---- photos ----

    private fun recent(limit: Int): List<Map<String, Any?>> {
        val uri = MediaStore.Files.getContentUri("external")
        val cols = arrayOf(MediaStore.Files.FileColumns._ID, MediaStore.Files.FileColumns.MEDIA_TYPE, MediaStore.Video.VideoColumns.DURATION)
        val where = "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}, ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})"
        val out = mutableListOf<Map<String, Any?>>()
        activity.contentResolver.query(uri, cols, where, null, "${MediaStore.Files.FileColumns.DATE_ADDED} DESC")?.use { c ->
            while (c.moveToNext() && out.size < limit.coerceIn(1, 200)) {
                val id = c.getLong(0)
                val video = c.getInt(1) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                val item = itemUri(id, video)
                val thumb = runCatching { thumbnail(item, id, video) }.getOrNull() ?: continue
                out.add(mapOf("id" to "${if (video) "v" else "i"}$id", "thumb" to thumb, "video" to video, "ms" to (if (video) c.getLong(2) else null)))
            }
        }
        return out
    }

    private fun itemUri(id: Long, video: Boolean): Uri =
        ContentUris.withAppendedId(if (video) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)

    private fun thumbnail(item: Uri, id: Long, video: Boolean): ByteArray? {
        val bmp: Bitmap? = if (Build.VERSION.SDK_INT >= 29) {
            activity.contentResolver.loadThumbnail(item, Size(240, 240), null)
        } else if (video) {
            @Suppress("DEPRECATION")
            MediaStore.Video.Thumbnails.getThumbnail(activity.contentResolver, id, MediaStore.Video.Thumbnails.MINI_KIND, null)
        } else {
            @Suppress("DEPRECATION")
            MediaStore.Images.Thumbnails.getThumbnail(activity.contentResolver, id, MediaStore.Images.Thumbnails.MINI_KIND, null)
        }
        bmp ?: return null
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, 75, out)
        return out.toByteArray()
    }

    private fun load(key: String): Map<String, Any?>? {
        val video = key.startsWith("v")
        val id = key.drop(1).toLongOrNull() ?: return null
        val item = itemUri(id, video)
        var name = if (video) "video.mp4" else "photo.jpg"
        activity.contentResolver.query(item, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) c.getString(0)?.let { name = it }
        }
        val bytes = activity.contentResolver.openInputStream(item)?.use { it.readBytes() } ?: return null
        return mapOf("name" to name, "bytes" to bytes)
    }

    companion object {
        const val REQUEST = 4711
    }
}
