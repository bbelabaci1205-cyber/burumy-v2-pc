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
                    val list = try { recent(call.argument<Int>("limit") ?: 60, call.argument<String>("album")) } catch (e: Exception) { null }
                    main.post { result.success(list) }
                }
            }
            "albums" -> ask(mediaPermissions(), any = true) { ok ->
                if (!ok) result.success(null) else work.execute {
                    val list = try { albums() } catch (e: Exception) { null }
                    main.post { result.success(list) }
                }
            }
            "transcribe" -> ask(arrayOf(Manifest.permission.RECORD_AUDIO), any = true) { ok ->
                if (!ok) result.success(null)
                else Transcriber(activity).run(call.argument<ByteArray>("bytes") ?: ByteArray(0), call.argument<String>("lang") ?: "ko") { result.success(it) }
            }
            "scanDocument" -> scanDocument(result)
            // 캘린더에 추가: the phone's calendar app opens its "new event"
            // screen filled in; no calendar permission is needed.
            "addEvent" -> {
                val intent = Intent(Intent.ACTION_INSERT)
                    .setData(android.provider.CalendarContract.Events.CONTENT_URI)
                    .putExtra(android.provider.CalendarContract.Events.TITLE, call.argument<String>("title") ?: "")
                    .putExtra(android.provider.CalendarContract.EXTRA_EVENT_BEGIN_TIME, (call.argument<Number>("start") ?: 0).toLong())
                    .putExtra(android.provider.CalendarContract.EXTRA_EVENT_END_TIME, (call.argument<Number>("end") ?: 0).toLong())
                    .putExtra(android.provider.CalendarContract.Events.EVENT_LOCATION, call.argument<String>("place") ?: "")
                result.success(runCatching { activity.startActivity(intent) }.isSuccess)
            }
            "stripAudio" -> work.execute {
                val out = try { stripAudio(call.argument<ByteArray>("bytes") ?: ByteArray(0)) } catch (e: Exception) { null }
                main.post { result.success(out) }
            }
            "videoFrames" -> work.execute {
                val out = try {
                    videoFrames(call.argument<ByteArray>("bytes") ?: ByteArray(0), call.argument<Int>("count") ?: 10, call.argument<Int>("height") ?: 96)
                } catch (e: Exception) { emptyList() }
                main.post { result.success(out) }
            }
            "editVideo" -> editVideo(
                call.argument<ByteArray>("bytes") ?: ByteArray(0),
                (call.argument<Number>("startMs") ?: 0).toLong(),
                (call.argument<Number>("endMs") ?: -1).toLong(),
                call.argument<Int>("turns") ?: 0,
                call.argument<Boolean>("flip") ?: false,
                call.argument<Boolean>("mute") ?: false,
                call.argument<Int>("height") ?: 0,
                result,
            )
            "cutout" -> cutout(call.argument<ByteArray>("bytes") ?: ByteArray(0), result)
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
            "saveImage" -> work.execute {
                val uri = try { savePicture(call.argument<ByteArray>("bytes") ?: ByteArray(0), call.argument<String>("name") ?: "image.png") } catch (e: Exception) { null }
                main.post { result.success(uri != null) }
            }
            "share" -> work.execute {
                // A picture goes into Photos first (no file provider needed),
                // then the share sheet sends it with the words.
                val bytes = call.argument<ByteArray>("bytes")
                val uri = if (bytes == null) null else try { savePicture(bytes, call.argument<String>("name") ?: "image.png") } catch (e: Exception) { null }
                main.post {
                    try {
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = if (uri != null) (call.argument<String>("mime") ?: "image/png") else "text/plain"
                            call.argument<String>("text")?.let { putExtra(Intent.EXTRA_TEXT, it) }
                            if (uri != null) {
                                putExtra(Intent.EXTRA_STREAM, uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                        }
                        activity.startActivity(Intent.createChooser(send, null))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
            }
            "settings" -> {
                activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + activity.packageName)))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ---- Photos ----

    /// Saves a PNG into Pictures/Burumy (Android 10+ needs no permission).
    private fun savePicture(bytes: ByteArray, name: String): Uri? {
        if (bytes.isEmpty() || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val values = android.content.ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Burumy")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val resolver = activity.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return null
        resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return null
        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri
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

    // ---- 문서 스캔 ----
    // Google's document scanner (Play services) finds the page edges,
    // flattens each page and hands back one PDF. It runs on the phone.
    private var scanned: MethodChannel.Result? = null

    private fun scanDocument(result: MethodChannel.Result) {
        if (scanned != null) return result.success(null)
        val options = com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(true)
            .setResultFormats(com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
            .setScannerMode(com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()
        com.google.mlkit.vision.documentscanner.GmsDocumentScanning.getClient(options).getStartScanIntent(activity)
            .addOnSuccessListener { sender ->
                scanned = result
                activity.startIntentSenderForResult(sender, SCAN, null, 0, 0, 0)
            }
            .addOnFailureListener { result.success(null) }
    }

    fun onActivityResult(code: Int, ok: Boolean, data: Intent?) {
        if (code != SCAN) return
        val done = scanned ?: return
        scanned = null
        val pdf = if (ok) com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult.fromActivityResultIntent(data)?.pdf?.uri else null
        if (pdf == null) return done.success(null)
        work.execute {
            val bytes = try { activity.contentResolver.openInputStream(pdf)?.use { it.readBytes() } } catch (e: Exception) { null }
            main.post { done.success(bytes) }
        }
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

    // ---- 소리 끄기 (GIF) ----

    /** The video with only its picture track, copied as is (no re-encode).
     *  Temp files live in the app's cache folder and are removed at once. */
    private fun stripAudio(bytes: ByteArray): ByteArray? {
        val dir = activity.cacheDir
        val src = java.io.File(dir, "mute-in-${System.nanoTime()}.mp4")
        val dst = java.io.File(dir, "mute-out-${System.nanoTime()}.mp4")
        try {
            src.writeBytes(bytes)
            val ex = android.media.MediaExtractor()
            ex.setDataSource(src.path)
            var track = -1
            for (i in 0 until ex.trackCount) {
                val mime = ex.getTrackFormat(i).getString(android.media.MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/")) { track = i; break }
            }
            if (track < 0) { ex.release(); return null }
            val format = ex.getTrackFormat(track)
            val mux = android.media.MediaMuxer(dst.path, android.media.MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            if (format.containsKey("rotation-degrees")) mux.setOrientationHint(format.getInteger("rotation-degrees"))
            val out = mux.addTrack(format)
            mux.start()
            ex.selectTrack(track)
            val size = if (format.containsKey(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)) format.getInteger(android.media.MediaFormat.KEY_MAX_INPUT_SIZE) else 4 * 1024 * 1024
            val buf = java.nio.ByteBuffer.allocate(size.coerceAtLeast(1024 * 1024))
            val info = android.media.MediaCodec.BufferInfo()
            while (true) {
                info.size = ex.readSampleData(buf, 0)
                if (info.size < 0) break
                info.offset = 0
                info.presentationTimeUs = ex.sampleTime
                info.flags = if ((ex.sampleFlags and android.media.MediaExtractor.SAMPLE_FLAG_SYNC) != 0) android.media.MediaCodec.BUFFER_FLAG_KEY_FRAME else 0
                mux.writeSampleData(out, buf, info)
                ex.advance()
            }
            mux.stop()
            mux.release()
            ex.release()
            return dst.readBytes()
        } finally {
            src.delete()
            dst.delete()
        }
    }

    /** Video editor strip (Telegram tip 56): small JPEGs from along the video. */
    private fun videoFrames(bytes: ByteArray, count: Int, height: Int): List<ByteArray> {
        val src = java.io.File(activity.cacheDir, "frames-${System.nanoTime()}.mp4")
        val r = android.media.MediaMetadataRetriever()
        try {
            src.writeBytes(bytes)
            r.setDataSource(src.path)
            val ms = r.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: return emptyList()
            val out = ArrayList<ByteArray>()
            for (i in 0 until count.coerceIn(1, 30)) {
                val us = ms * 1000 * (2 * i + 1) / (2L * count)
                val frame = (if (Build.VERSION.SDK_INT >= 27) r.getScaledFrameAtTime(us, android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC, height * 3, height)
                             else r.getFrameAtTime(us, android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC)) ?: continue
                val w = (frame.width * height / frame.height.coerceAtLeast(1)).coerceAtLeast(1)
                val small = if (frame.height > height) Bitmap.createScaledBitmap(frame, w, height, true) else frame
                val o = ByteArrayOutputStream()
                small.compress(Bitmap.CompressFormat.JPEG, 70, o)
                out.add(o.toByteArray())
                if (small !== frame) small.recycle()
                frame.recycle()
            }
            return out
        } finally {
            r.release()
            src.delete()
        }
    }

    /** 동영상 자르기·회전 (Telegram tip 56): a new H.264 MP4 with only
     *  [startMs, endMs) kept, turned quarter turns to the left (counter-
     *  clockwise) and mirrored, made on this phone by Media3 Transformer
     *  before encryption, so the cut-off parts never leave it. */
    /** Video bit rate (bit/s) for the light copies (tips 114, 479, 480). */
    private fun bitrateFor(height: Int): Int = when {
        height <= 360 -> 600_000
        height <= 480 -> 1_000_000
        height <= 720 -> 2_200_000
        else -> 4_500_000
    }

    /** Upright width x height of the first video track (rotation applied). */
    private fun uprightSize(file: java.io.File): Pair<Int, Int>? = try {
        val r = android.media.MediaMetadataRetriever()
        try {
            r.setDataSource(file.path)
            val w = r.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
            val h = r.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
            val rot = r.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
            if (w <= 0 || h <= 0) null else if (rot % 180 != 0) Pair(h, w) else Pair(w, h)
        } finally {
            r.release()
        }
    } catch (e: Exception) { null }

    // height > 0: the short side becomes this many lines (a smaller copy).
    private fun editVideo(bytes: ByteArray, startMs: Long, endMs: Long, turns: Int, flip: Boolean, mute: Boolean, height: Int, result: MethodChannel.Result) {
        val dir = activity.cacheDir
        val src = java.io.File(dir, "edit-in-${System.nanoTime()}.mp4")
        val dst = java.io.File(dir, "edit-out-${System.nanoTime()}.mp4")
        fun done(out: ByteArray?) {
            src.delete()
            dst.delete()
            main.post { result.success(out) }
        }
        work.execute {
            try { src.writeBytes(bytes) } catch (e: Exception) { return@execute done(null) }
            // Transformer runs on a thread with a Looper: the main one.
            main.post {
                try {
                    val clip = androidx.media3.common.MediaItem.ClippingConfiguration.Builder()
                        .setStartPositionMs(startMs.coerceAtLeast(0))
                        .apply { if (endMs >= 0) setEndPositionMs(endMs) }
                        .build()
                    val item = androidx.media3.common.MediaItem.Builder().setUri(Uri.fromFile(src)).setClippingConfiguration(clip).build()
                    val effects = ArrayList<androidx.media3.common.Effect>()
                    val q = ((turns % 4) + 4) % 4
                    if (q != 0 || flip) {
                        effects.add(
                            androidx.media3.effect.ScaleAndRotateTransformation.Builder()
                                .setScale(if (flip) -1f else 1f, 1f)
                                .setRotationDegrees(q * 90f)
                                .build()
                        )
                    }
                    // Smaller copy: short side = height, even sizes, never bigger.
                    val upright = if (height > 0) uprightSize(src) else null
                    if (upright != null && minOf(upright.first, upright.second) > height) {
                        val k = height.toDouble() / minOf(upright.first, upright.second)
                        val w = (Math.round(upright.first * k / 2.0) * 2).toInt()
                        val h = (Math.round(upright.second * k / 2.0) * 2).toInt()
                        effects.add(androidx.media3.effect.Presentation.createForWidthAndHeight(w, h, androidx.media3.effect.Presentation.LAYOUT_SCALE_TO_FIT))
                    }
                    val edited = androidx.media3.transformer.EditedMediaItem.Builder(item)
                        .setRemoveAudio(mute)
                        .setEffects(androidx.media3.transformer.Effects(emptyList(), effects))
                        .build()
                    val t = androidx.media3.transformer.Transformer.Builder(activity)
                        .setVideoMimeType(androidx.media3.common.MimeTypes.VIDEO_H264)
                        .apply {
                            if (height > 0) {
                                setEncoderFactory(
                                    androidx.media3.transformer.DefaultEncoderFactory.Builder(activity)
                                        .setRequestedVideoEncoderSettings(
                                            androidx.media3.transformer.VideoEncoderSettings.Builder().setBitrate(bitrateFor(height)).build()
                                        )
                                        .build()
                                )
                            }
                        }
                        .addListener(object : androidx.media3.transformer.Transformer.Listener {
                            override fun onCompleted(composition: androidx.media3.transformer.Composition, exportResult: androidx.media3.transformer.ExportResult) {
                                work.execute { done(try { dst.readBytes() } catch (e: Exception) { null }) }
                            }
                            override fun onError(composition: androidx.media3.transformer.Composition, exportResult: androidx.media3.transformer.ExportResult, exportException: androidx.media3.transformer.ExportException) {
                                work.execute { done(null) }
                            }
                        })
                        .build()
                    t.start(edited, dst.path)
                } catch (e: Exception) {
                    work.execute { done(null) }
                }
            }
        }
    }

    // ---- photos ----

    private val mediaOnly = "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}, ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})"

    /** Extra filter for one gallery album (Telegram tip 324); null = all. */
    private fun albumWhere(album: String?): Pair<String, Array<String>?> = when {
        album == null || album == "recents" -> mediaOnly to null
        album == "videos" -> "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}" to null
        album == "favorites" && Build.VERSION.SDK_INT >= 30 -> "$mediaOnly AND ${MediaStore.MediaColumns.IS_FAVORITE} = 1" to null
        album == "screenshots" -> "$mediaOnly AND ${MediaStore.MediaColumns.BUCKET_DISPLAY_NAME} = ?" to arrayOf("Screenshots")
        album.startsWith("b:") -> "$mediaOnly AND ${MediaStore.MediaColumns.BUCKET_ID} = ?" to arrayOf(album.substring(2))
        else -> "0" to null
    }

    private fun count(where: Pair<String, Array<String>?>): Int =
        activity.contentResolver.query(MediaStore.Files.getContentUri("external"), arrayOf(MediaStore.Files.FileColumns._ID), where.first, where.second, null)?.use { it.count } ?: 0

    /** The phone's albums with how many photos and videos each holds:
     *  최근 항목, 즐겨찾기, 동영상, 스크린샷, then every folder (biggest first). */
    private fun albums(): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        for (id in listOf("recents", "favorites", "videos", "screenshots")) {
            if (id == "favorites" && Build.VERSION.SDK_INT < 30) continue
            val n = count(albumWhere(id))
            if (n > 0 || id == "recents") out.add(mapOf("id" to id, "name" to null, "count" to n))
        }
        val buckets = linkedMapOf<String, Pair<String, Int>>()
        activity.contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            arrayOf(MediaStore.MediaColumns.BUCKET_ID, MediaStore.MediaColumns.BUCKET_DISPLAY_NAME),
            mediaOnly, null, null,
        )?.use { c ->
            while (c.moveToNext()) {
                val id = c.getString(0) ?: continue
                val name = c.getString(1) ?: continue
                if (name == "Screenshots") continue
                val was = buckets[id]
                buckets[id] = name to ((was?.second ?: 0) + 1)
            }
        }
        for ((id, v) in buckets.entries.sortedByDescending { it.value.second }) {
            out.add(mapOf("id" to "b:$id", "name" to v.first, "count" to v.second))
        }
        return out
    }

    private fun recent(limit: Int, album: String? = null): List<Map<String, Any?>> {
        val uri = MediaStore.Files.getContentUri("external")
        val cols = arrayOf(MediaStore.Files.FileColumns._ID, MediaStore.Files.FileColumns.MEDIA_TYPE, MediaStore.Video.VideoColumns.DURATION)
        val (where, args) = albumWhere(album)
        val out = mutableListOf<Map<String, Any?>>()
        activity.contentResolver.query(uri, cols, where, args, "${MediaStore.Files.FileColumns.DATE_ADDED} DESC")?.use { c ->
            while (c.moveToNext() && out.size < limit.coerceIn(1, 200)) {
                val id = c.getLong(0)
                val video = c.getInt(1) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                val item = itemUri(id, video)
                val thumb = runCatching { thumbnail(item, id, video) }.getOrNull() ?: continue
                out.add(mapOf("id" to "${if (video) "v" else "i"}$id", "thumb" to thumb, "video" to video, "ms" to (if (video) c.getLong(2) else null), "live" to (!video && isMotionPhoto(item))))
            }
        }
        return out
    }

    /** 움직이는 사진: a Motion Photo says so in the XMP near the start of
     *  the JPEG ("MotionPhoto" / older "MicroVideo"); only the first 64 KB
     *  are read. The clip itself is split off in Dart when chosen. */
    private fun isMotionPhoto(item: Uri): Boolean = runCatching {
        activity.contentResolver.openInputStream(item)?.use { s ->
            val buf = ByteArray(64 * 1024)
            var n = 0
            while (n < buf.size) { val r = s.read(buf, n, buf.size - n); if (r <= 0) break; n += r }
            val head = String(buf, 0, n, Charsets.ISO_8859_1)
            head.contains("MotionPhoto") || head.contains("MicroVideo")
        } ?: false
    }.getOrDefault(false)

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
        const val SCAN = 4712
    }
    /** 스티커 만들기: the main person or thing, cut out on this phone with ML Kit
     *  subject segmentation (runs on the phone, the photo is not uploaded).
     *  PNG with a see-through background, or null when nothing was found. */
    private fun cutout(bytes: ByteArray, result: MethodChannel.Result) {
        val src = try { android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size) } catch (e: Exception) { null }
        if (src == null) return result.success(null)
        // Big photos are slow and the sticker is at most 512 px anyway.
        val scale = minOf(1f, 1536f / maxOf(src.width, src.height))
        val bmp = if (scale < 1f) Bitmap.createScaledBitmap(src, (src.width * scale).toInt(), (src.height * scale).toInt(), true) else src
        val options = com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions.Builder()
            .enableForegroundBitmap()
            .build()
        val segmenter = com.google.mlkit.vision.segmentation.subject.SubjectSegmentation.getClient(options)
        segmenter.process(com.google.mlkit.vision.common.InputImage.fromBitmap(bmp, 0))
            .addOnSuccessListener { r ->
                val fg = r.foregroundBitmap
                if (fg == null) { result.success(null); return@addOnSuccessListener }
                work.execute {
                    val out = ByteArrayOutputStream()
                    fg.compress(Bitmap.CompressFormat.PNG, 100, out)
                    main.post { result.success(out.toByteArray()) }
                }
            }
            .addOnFailureListener { result.success(null) }
            .addOnCompleteListener { segmenter.close() }
    }
}
