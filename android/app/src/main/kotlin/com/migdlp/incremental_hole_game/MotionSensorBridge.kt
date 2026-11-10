package com.migdlp.incremental_hole_game

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.exp

/** A capability probe requires an actual finite reading, not just a sensor name. */
class MotionSensorBridge(context: Context, messenger: BinaryMessenger) :
    EventChannel.StreamHandler, SensorEventListener {
    private val manager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    private val window = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())
    private val control = MethodChannel(messenger, "feed_the_hole/motion")
    private val events = EventChannel(messenger, "feed_the_hole/motion/events")
    private var chosen: Sensor? = null
    private var sink: EventChannel.EventSink? = null
    private var registered = false
    private var paused = false
    private var probeResult: MethodChannel.Result? = null
    private var probeListener: SensorEventListener? = null
    private var probeTimeout: Runnable? = null
    private var lastTimestamp = 0L
    private var filtered: DoubleArray? = null

    init {
        control.setMethodCallHandler { call, result ->
            if (call.method == "probe") {
                if (probeResult != null) result.error("busy", "Sensor probe in progress", null)
                else { probeResult = result; probe(candidates(), 0) }
            } else result.notImplemented()
        }
        events.setStreamHandler(this)
    }

    private fun candidates(): List<Sensor> = listOfNotNull(
        manager?.getDefaultSensor(Sensor.TYPE_GRAVITY),
        manager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    )

    private fun valid(event: SensorEvent): Boolean {
        if (event.values.size < 3 || event.values.take(3).any { !it.isFinite() }) return false
        val norm = event.values.take(3).sumOf { it.toDouble() * it }
        return norm >= 1 && norm <= 900
    }

    private fun clearProbeListener() {
        probeListener?.let { manager?.unregisterListener(it) }
        probeListener = null
        probeTimeout?.let { handler.removeCallbacks(it) }
        probeTimeout = null
    }

    private fun completeProbe(available: Boolean) {
        clearProbeListener()
        val result = probeResult
        probeResult = null
        result?.success(mapOf("available" to available))
    }

    private fun probe(sensors: List<Sensor>, index: Int) {
        clearProbeListener()
        if (index >= sensors.size || manager == null) { completeProbe(false); return }
        val sensor = sensors[index]
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (!valid(event) || probeResult == null) return
                chosen = sensor
                completeProbe(true)
            }
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        probeListener = listener
        val ok = try { manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_GAME) }
            catch (_: RuntimeException) { false }
        if (!ok) { probe(sensors, index + 1); return }
        val timeout = Runnable { probe(sensors, index + 1) }
        probeTimeout = timeout
        handler.postDelayed(timeout, 900)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        start()
    }

    override fun onCancel(arguments: Any?) {
        stop()
        sink = null
    }

    private fun stop() {
        if (registered) manager?.unregisterListener(this)
        registered = false
        lastTimestamp = 0
        filtered = null
    }

    fun pause() { paused = true; stop() }

    fun resume() {
        paused = false
        start()
    }

    private fun start() {
        if (paused || sink == null || registered || manager == null) return
        val choices = (listOfNotNull(chosen) + candidates()).distinctBy { it.type }
        for (sensor in choices) {
            val ok = try { manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME) }
                catch (_: RuntimeException) { false }
            if (ok) { chosen = sensor; registered = true; return }
        }
        sink?.success(mapOf("available" to false))
    }

    @Suppress("DEPRECATION")
    override fun onSensorChanged(event: SensorEvent) {
        if (paused || !registered || !valid(event)) return
        val values = DoubleArray(3) { event.values[it].toDouble() }
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val previous = filtered
            if (previous != null && lastTimestamp != 0L) {
                val dt = ((event.timestamp - lastTimestamp) / 1e9).coerceIn(0.0, 1.0)
                val weight = 1 - exp(-dt / .25)
                for (i in 0..2) values[i] = previous[i] + weight * (values[i] - previous[i])
            }
            filtered = values.copyOf()
        }
        lastTimestamp = event.timestamp
        sink?.success(mapOf(
            "available" to true,
            "x" to values[0], "y" to values[1], "z" to values[2],
            "rotation" to window.defaultDisplay.rotation
        ))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    fun close() {
        stop()
        completeProbe(false)
        sink = null
        events.setStreamHandler(null)
        control.setMethodCallHandler(null)
    }
}
