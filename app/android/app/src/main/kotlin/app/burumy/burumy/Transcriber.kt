// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
package app.burumy.burumy

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteOrder

/// 음성 메시지를 글로 보기: Android 13+ on-device speech recognition only
/// (createOnDeviceSpeechRecognizer). The voice message is decoded to plain
/// sound on the phone and fed in through a pipe; nothing goes to a server.
/// Phones without an on-device recognizer answer null (button says it can't).
class Transcriber(private val ctx: Context) {
    private val main = Handler(Looper.getMainLooper())

    fun run(bytes: ByteArray, lang: String, done: (String?) -> Unit) {
        if (Build.VERSION.SDK_INT < 33 || !SpeechRecognizer.isOnDeviceRecognitionAvailable(ctx)) return done(null)
        Thread {
            val pcm = try { decode(bytes) } catch (e: Exception) { null }
            main.post { if (pcm == null) done(null) else listen(pcm.first, pcm.second, lang, done) }
        }.start()
    }

    /// 16-bit mono sound and its sample rate.
    private fun decode(bytes: ByteArray): Pair<ByteArray, Int>? {
        val f = File.createTempFile("stt", ".m4a", ctx.cacheDir)
        try {
            f.writeBytes(bytes)
            val ex = MediaExtractor()
            ex.setDataSource(f.path)
            var track = -1
            for (i in 0 until ex.trackCount) {
                if (ex.getTrackFormat(i).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) { track = i; break }
            }
            if (track < 0) return null
            ex.selectTrack(track)
            val inFormat = ex.getTrackFormat(track)
            val codec = MediaCodec.createDecoderByType(inFormat.getString(MediaFormat.KEY_MIME)!!)
            codec.configure(inFormat, null, null, 0)
            codec.start()
            val out = ByteArrayOutputStream()
            val info = MediaCodec.BufferInfo()
            var rate = inFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = inFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            var inputDone = false
            var outputDone = false
            while (!outputDone) {
                if (!inputDone) {
                    val i = codec.dequeueInputBuffer(10_000)
                    if (i >= 0) {
                        val buf = codec.getInputBuffer(i)!!
                        val n = ex.readSampleData(buf, 0)
                        if (n < 0) {
                            codec.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(i, 0, n, ex.sampleTime, 0)
                            ex.advance()
                        }
                    }
                }
                val o = codec.dequeueOutputBuffer(info, 10_000)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    rate = codec.outputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = codec.outputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                } else if (o >= 0) {
                    val buf = codec.getOutputBuffer(o)!!
                    buf.position(info.offset)
                    buf.limit(info.offset + info.size)
                    val shorts = buf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                    // Mix to one channel.
                    val frames = shorts.remaining() / channels
                    for (fi in 0 until frames) {
                        var sum = 0
                        for (c in 0 until channels) sum += shorts.get(fi * channels + c)
                        val v = (sum / channels)
                        out.write(v and 0xff)
                        out.write((v shr 8) and 0xff)
                    }
                    codec.releaseOutputBuffer(o, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                }
            }
            codec.stop()
            codec.release()
            ex.release()
            return Pair(out.toByteArray(), rate)
        } finally {
            f.delete()
        }
    }

    private fun listen(pcm: ByteArray, rate: Int, lang: String, done: (String?) -> Unit) {
        val pipe = ParcelFileDescriptor.createPipe()
        val rec = SpeechRecognizer.createOnDeviceSpeechRecognizer(ctx)
        val words = mutableListOf<String>()
        var finished = false
        fun finish(v: String?) {
            if (finished) return
            finished = true
            rec.destroy()
            try { pipe[0].close() } catch (_: Exception) {}
            done(v)
        }
        rec.setRecognitionListener(object : RecognitionListener {
            override fun onSegmentResults(segment: Bundle) {
                segment.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { if (it.isNotBlank()) words.add(it) }
            }
            override fun onEndOfSegmentedSession() = finish(words.joinToString(" "))
            override fun onResults(results: Bundle) {
                results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.let { if (it.isNotBlank()) words.add(it) }
                finish(words.joinToString(" "))
            }
            override fun onError(error: Int) {
                val noWords = error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT
                finish(if (words.isNotEmpty() || noWords) words.joinToString(" ") else null)
            }
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        val tag = when (lang) { "ko" -> "ko-KR"; "en" -> "en-US"; else -> lang }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, tag)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pipe[0])
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, rate)
            putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
        }
        Thread {
            try {
                ParcelFileDescriptor.AutoCloseOutputStream(pipe[1]).use { it.write(pcm) }
            } catch (_: Exception) {}
        }.start()
        rec.startListening(intent)
        // Safety net: never leave the button spinning.
        main.postDelayed({ finish(if (words.isEmpty()) null else words.joinToString(" ")) }, 120_000)
    }
}
