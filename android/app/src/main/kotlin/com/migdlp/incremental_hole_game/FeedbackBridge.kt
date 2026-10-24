package com.migdlp.incremental_hole_game

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.SoundPool
import android.os.Build
import android.os.Handler
import android.os.SystemClock
import android.os.Looper
import android.os.Vibrator
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Preloaded bounded SoundPool, two shared loops, one native haptic per batch. */
class FeedbackBridge(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "feed_the_hole/feedback")
    private val handler = Handler(Looper.getMainLooper())
    private val audio = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
    private var pool: SoundPool? = null
    private val samples = mutableMapOf<String, Int>()
    private val loaded = mutableSetOf<Int>()
    private val voices = mutableMapOf<Int, Int>()
    private val loops = mutableMapOf<String, Int>()
    private var background = false
    private var focus = false
    private var lastFocusAttempt = 0L
    private var pendingPrepare: MethodChannel.Result? = null
    private val targets = mutableMapOf<String, Float>()
    private val levels = mutableMapOf<String, Float>()
    private var ramping = false
    private val ramp = object : Runnable {
        override fun run() {
            ramping = false
            if (background || !focus) return
            var again = false
            for (key in listOf("absorb", "rolling")) {
                val target = targets[key] ?: 0f
                val old = levels[key] ?: 0f
                val level = old + (target - old) * .35f
                levels[key] = level
                var stream = loops[key]
                if (level > .0005f && stream == null) {
                    val sample = samples[key]
                    if (sample != null && loaded.contains(sample)) {
                        val next = pool?.play(sample, 0f, 0f, 110, -1, 1f) ?: 0
                        if (next != 0) { loops[key] = next; stream = next }
                    }
                }
                if (stream != null) {
                    if (target <= .0005f && level <= .0005f) {
                        pool?.stop(stream); loops.remove(key); levels[key] = 0f
                    } else { pool?.setVolume(stream, level, level) }
                }
                if (kotlin.math.abs(target - level) > .0002f) again = true
            }
            if (again) { ramping = true; handler.postDelayed(this, 12) }
        }
    }
    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_GAIN) {
            focus = true
            if (targets.values.any { it > .0005f } && !ramping && !background) { ramping = true; handler.post(ramp) }
        } else {
            focus = false
            val desired = targets.toMap()
            stopStreams(); targets.putAll(desired)
        }
    }
    private var request: AudioFocusRequest? = null
    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "prepare" -> {
                        pendingPrepare?.success(mapOf("loaded" to 0, "expected" to 1))
                        pendingPrepare = result
                        stopStreams(); pool?.release()
                        samples.clear(); loaded.clear()
                        val next = SoundPool.Builder().setMaxStreams(16).setAudioAttributes(attributes).build()
                        pool = next
                        val entries = call.argument<Map<String, Map<String, Any>>>("samples") ?: emptyMap()
                        var remaining = entries.size
                        var completed = false
                        fun finish() {
                            if (!completed && pendingPrepare === result) { completed = true; pendingPrepare = null; result.success(mapOf("loaded" to loaded.size, "expected" to entries.size)) }
                        }
                        next.setOnLoadCompleteListener { soundPool, id, status ->
                            if (pool === soundPool) {
                                if (status == 0) loaded.add(id)
                                remaining--
                                if (remaining <= 0) finish()
                            }
                        }
                        entries.forEach { (key, value) ->
                            val path = value["file"] as? String
                            if (path == null || !path.startsWith("assets/audio/sfx/") || path.contains("..")) { remaining--; return@forEach }
                            try {
                                activity.assets.openFd("flutter_assets/$path").use { fd ->
                                    val id = next.load(fd, 1)
                                    if (id == 0) remaining-- else samples[key] = id
                                }
                            } catch (_: Exception) { remaining-- }
                        }
                        if (remaining <= 0) finish()
                    }
                    "frame" -> {
                        if (!background) {
                            call.argument<List<Number>>("stop")?.forEach { token -> voices.remove(token.toInt())?.let { pool?.stop(it) } }
                            val plays = call.argument<List<Map<String, Any>>>("play") ?: emptyList()
                            val a = (call.argument<Number>("absorb")?.toFloat() ?: 0f).coerceIn(0f, .15f)
                            val r = (call.argument<Number>("rolling")?.toFloat() ?: 0f).coerceIn(0f, .1f)
                            if (plays.isNotEmpty() || a > 0f || r > 0f) ensureFocus()
                            if (focus) {
                                plays.take(16).forEach { cue ->
                                    val key = cue["sample"] as? String ?: return@forEach
                                    val sample = samples[key] ?: return@forEach
                                    if (!loaded.contains(sample)) return@forEach
                                    val token = (cue["token"] as Number).toInt()
                                    val gain = (cue["gain"] as Number).toFloat().coerceIn(0f, 1f)
                                    val rate = (cue["rate"] as Number).toFloat().coerceIn(.8f, 1.2f)
                                    val priority = (cue["priority"] as Number).toInt()
                                    val stream = pool?.play(sample, gain, gain, priority, 0, rate) ?: 0
                                    if (stream != 0) {
                                        voices[token] = stream
                                        val ms = ((cue["duration"] as Number).toDouble() * 1000).toLong().coerceIn(20, 1500)
                                        handler.postDelayed({ if (voices[token] == stream) voices.remove(token) }, ms)
                                    }
                                }
                                loop("absorb", a); loop("rolling", r)
                            }
                            val haptic = call.argument<String>("haptic")
                            if (haptic != null) {
                                @Suppress("DEPRECATION")
                                val vibrator = activity.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                                if (vibrator?.hasVibrator() == true) {
                                    activity.window.decorView.performHapticFeedback(
                                        if (haptic == "reward" && Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM
                                        else if (haptic == "reward") HapticFeedbackConstants.VIRTUAL_KEY
                                        else HapticFeedbackConstants.CLOCK_TICK
                                    )
                                }
                            }
                        }
                        result.success(null)
                    }
                    "stop" -> { stopStreams(); abandonFocus(); result.success(null) }
                    "dispose" -> { pendingPrepare?.success(mapOf("loaded" to 0, "expected" to 1)); pendingPrepare = null; stopStreams(); abandonFocus(); pool?.release(); pool = null; samples.clear(); loaded.clear(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                // A missing device/sample/focus must never break the game.
                result.success(null)
            }
        }
    }
    private fun loop(key: String, gain: Float) {
        targets[key] = gain
        if (!ramping) { ramping = true; handler.post(ramp) }
    }
    private fun ensureFocus() {
        if (focus || background) return
        val now = SystemClock.uptimeMillis()
        if (now - lastFocusAttempt < 1000) return
        lastFocusAttempt = now
        try {
        focus = if (Build.VERSION.SDK_INT >= 26) {
            val value = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attributes).setOnAudioFocusChangeListener(focusListener).build()
            request = value
            audio.requestAudioFocus(value) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            (audio.requestAudioFocus(focusListener, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
        }
        } catch (_: Exception) { focus = false }
    }
    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= 26) request?.let { audio.abandonAudioFocusRequest(it) }
        else { @Suppress("DEPRECATION") audio.abandonAudioFocus(focusListener) }
        focus = false; request = null; lastFocusAttempt = 0
    }
    private fun stopStreams() {
        handler.removeCallbacksAndMessages(null)
        voices.values.forEach { pool?.stop(it) }; loops.values.forEach { pool?.stop(it) }
        voices.clear(); loops.clear(); targets.clear(); levels.clear(); ramping = false
    }
    fun pause() { background = true; stopStreams(); abandonFocus() }
    fun resume() { background = false }
    fun close() { pendingPrepare?.success(mapOf("loaded" to 0, "expected" to 1)); pendingPrepare = null; pause(); pool?.release(); pool = null; channel.setMethodCallHandler(null) }
}
