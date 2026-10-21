package com.migdlp.incremental_hole_game

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var motion: MotionSensorBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        motion = MotionSensorBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onPause() {
        motion?.pause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        motion?.resume()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        motion?.close()
        motion = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
