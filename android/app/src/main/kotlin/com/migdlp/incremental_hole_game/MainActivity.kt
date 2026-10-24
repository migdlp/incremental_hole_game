package com.migdlp.incremental_hole_game

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var feedback: FeedbackBridge? = null
    private var motion: MotionSensorBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        feedback = FeedbackBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        motion = MotionSensorBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onPause() {
        feedback?.pause()
        motion?.pause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        feedback?.resume()
        motion?.resume()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        feedback?.close()
        feedback = null
        motion?.close()
        motion = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
