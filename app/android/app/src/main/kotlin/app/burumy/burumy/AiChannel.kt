// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
package app.burumy.burumy

import android.os.Build
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/// AI 편집기: Google's built-in model on the phone (Gemini Nano through
/// AICore, ML Kit GenAI Prompt API). Text stays on the phone. Phones
/// without it (or older than Android 8) answer "unsupported" and the app
/// hides its AI buttons.
class AiChannel(messenger: BinaryMessenger) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var model: GenerativeModel? = null
    private var busy = false
    private var downloading = false

    init {
        MethodChannel(messenger, "app.burumy/ai").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> scope.launch { result.success(status()) }
                "run" -> {
                    val rules = call.argument<String>("rules") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    run(rules, text, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun client(): GenerativeModel? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        return model ?: try {
            Generation.getClient().also { model = it }
        } catch (_: Throwable) {
            null
        }
    }

    private suspend fun status(): String {
        val m = client() ?: return "unsupported"
        return try {
            when (m.checkStatus()) {
                FeatureStatus.AVAILABLE -> "ready"
                FeatureStatus.DOWNLOADING -> "preparing"
                FeatureStatus.DOWNLOADABLE -> {
                    // The phone can do it once Google's model is on it: fetch it
                    // in the background (from Google, not from us; no text sent).
                    if (!downloading) {
                        downloading = true
                        scope.launch {
                            try {
                                m.download().collect { }
                            } catch (_: Throwable) {
                            } finally {
                                downloading = false
                            }
                        }
                    }
                    "preparing"
                }
                else -> "unsupported"
            }
        } catch (_: Throwable) {
            "unsupported"
        }
    }

    private fun run(rules: String, text: String, result: MethodChannel.Result) {
        val m = client() ?: return result.error("unsupported", null, null)
        if (busy) return result.error("busy", null, null)
        busy = true
        scope.launch {
            try {
                // One prompt: what to do, then the person's message, clearly fenced.
                val prompt = "$rules\n\nMessage:\n<<<\n$text\n>>>"
                val out = m.generateContent(prompt).candidates.firstOrNull()?.text?.trim().orEmpty()
                if (out.isEmpty()) result.error("failed", null, null) else result.success(out)
            } catch (e: GenAiException) {
                result.error("failed", e.errorCode.toString(), null)
            } catch (_: Throwable) {
                result.error("failed", null, null)
            } finally {
                busy = false
            }
        }
    }
}
