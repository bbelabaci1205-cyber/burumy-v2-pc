// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
package app.burumy.burumy

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/// 번역: Google ML Kit on-device translation. Words are translated on the
/// phone; only the language pack itself is downloaded once (Wi-Fi only).
/// English is built in; other languages ~30 MB each.
class TranslateChannel(messenger: BinaryMessenger) {
    private val translators = HashMap<String, Translator>()
    private val identifier by lazy { LanguageIdentification.getClient() }

    init {
        MethodChannel(messenger, "app.burumy/translate").setMethodCallHandler { call, result ->
            val text = call.argument<String>("text") ?: ""
            val from = TranslateLanguage.fromLanguageTag(call.argument<String>("from") ?: "")
            val to = TranslateLanguage.fromLanguageTag(call.argument<String>("to") ?: "")
            when (call.method) {
                "detect" -> identifier.identifyLanguage(text)
                    .addOnSuccessListener { result.success(if (it == "und") null else it) }
                    .addOnFailureListener { result.success(null) }
                "status" -> {
                    if (from == null || to == null) result.success("unsupported")
                    else haveModels(from, to) { have -> result.success(if (have) "ready" else "download") }
                }
                "download" -> {
                    if (from == null || to == null) result.success(false)
                    else client(from, to).downloadModelIfNeeded(DownloadConditions.Builder().requireWifi().build())
                        .addOnSuccessListener { result.success(true) }
                        .addOnFailureListener { result.success(false) }
                }
                "translate" -> {
                    if (from == null || to == null) result.error("unsupported", null, null)
                    else haveModels(from, to) { have ->
                        if (!have) result.error("download", null, null)
                        else client(from, to).translate(text)
                            .addOnSuccessListener { result.success(it) }
                            .addOnFailureListener { result.error("failed", it.message, null) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun client(from: String, to: String): Translator =
        translators.getOrPut("$from>$to") {
            Translation.getClient(TranslatorOptions.Builder().setSourceLanguage(from).setTargetLanguage(to).build())
        }

    /// Both language packs on the phone (English always is).
    private fun haveModels(from: String, to: String, done: (Boolean) -> Unit) {
        RemoteModelManager.getInstance().getDownloadedModels(TranslateRemoteModel::class.java)
            .addOnSuccessListener { models ->
                val have = models.map { it.language }.toSet() + TranslateLanguage.ENGLISH
                done(have.contains(from) && have.contains(to))
            }
            .addOnFailureListener { done(false) }
    }
}
