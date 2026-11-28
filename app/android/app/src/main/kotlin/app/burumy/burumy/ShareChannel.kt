// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
package app.burumy.burumy

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// 다른 앱에서 부루미로 보내기 (Telegram tips 350 + 182): another app's share
/// sheet sends photos, videos, files or words here. Each file is copied
/// into this app's own cache (other apps' links stop working once they
/// close), and the app asks "take" when it opens or comes back. Nothing
/// leaves the phone until the person picks chats and presses 보내기.
class ShareChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val waiting = mutableListOf<Map<String, String>>()

    init {
        MethodChannel(messenger, "app.burumy/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "take" -> {
                    val out = waiting.toList()
                    waiting.clear()
                    result.success(out)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// From onCreate / onNewIntent. A handled intent is emptied so turning
    /// the phone (the activity starts again) doesn't add it twice.
    fun handle(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return
        val uris = mutableListOf<Uri>()
        if (action == Intent.ACTION_SEND) {
            stream(intent)?.let { uris.add(it) }
        } else {
            uris.addAll(streams(intent))
        }
        val dir = File(activity.cacheDir, "share_in").apply { mkdirs() }
        for ((i, u) in uris.take(MAX_FILES).withIndex()) {
            // Only another app's content links: a file:// path or one of our
            // own links could point at this app's private files (chats, keys)
            // and get them sent by mistake (보안검수 2026-11-28).
            if (!fromOtherApp(u)) continue
            try {
                val name = clean(displayName(u) ?: "file_$i")
                val mime = activity.contentResolver.getType(u) ?: intent.type ?: "application/octet-stream"
                val out = File(dir, "${System.currentTimeMillis()}_${i}_$name")
                activity.contentResolver.openInputStream(u)?.use { input -> out.outputStream().use { input.copyTo(it) } } ?: continue
                waiting.add(mapOf("path" to out.absolutePath, "name" to name, "mime" to mime))
            } catch (_: Exception) {
            }
        }
        // Words or a link (a web page shared from the browser).
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim().orEmpty()
        if (text.isNotEmpty()) waiting.add(mapOf("text" to text.take(MAX_TEXT), "name" to "text", "mime" to "text/plain"))
        intent.action = null
    }

    @Suppress("DEPRECATION")
    private fun stream(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri

    @Suppress("DEPRECATION")
    private fun streams(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)) ?: emptyList()

    private fun displayName(u: Uri): String? {
        try {
            activity.contentResolver.query(u, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) return c.getString(0)
            }
        } catch (_: Exception) {
        }
        return u.lastPathSegment
    }

    private fun fromOtherApp(u: Uri): Boolean {
        if (u.scheme != "content") return false
        val auth = u.authority ?: return false
        return !auth.startsWith(activity.packageName)
    }

    /// A plain file name: no folders, nothing that walks out of our cache.
    private fun clean(name: String): String =
        name.substringAfterLast('/').replace(Regex("[^A-Za-z0-9._\\- 가-힣]"), "_").take(120).ifEmpty { "file" }

    companion object {
        /// Telegram also caps one share; more can be shared again.
        const val MAX_FILES = 20
        const val MAX_TEXT = 4096
    }
}
