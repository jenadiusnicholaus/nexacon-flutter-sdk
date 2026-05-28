package com.nexacon.nexacon_sdk

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FoldStatePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var sensorManager: SensorManager? = null
    private var accelerometerListener: AccelerometerListener? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nexacon_sdk/fold")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getCurrentFoldState" -> {
                val state = getCurrentState()
                result.success(state)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopListening()
    }

    private fun getCurrentState(): String {
        // For foldable devices, we would use DeviceStateManager or WindowManager
        // For now, we'll use a simplified approach with accelerometer
        // This is a basic implementation - production would use proper fold APIs
        return "flat" // Default state
    }

    private fun startListening() {
        val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (accelerometer != null) {
            accelerometerListener = AccelerometerListener()
            sensorManager?.registerListener(
                accelerometerListener,
                accelerometer,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }
    }

    private fun stopListening() {
        accelerometerListener?.let {
            sensorManager?.unregisterListener(it)
        }
        accelerometerListener = null
    }

    private inner class AccelerometerListener : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            event?.let {
                // Detect fold state based on accelerometer data
                // This is a simplified implementation
                val x = it.values[0]
                val y = it.values[1]
                val z = it.values[2]
                
                // Simple logic to detect orientation changes
                // In production, use proper fold detection APIs
                val newState = detectFoldState(x, y, z)
                if (newState != null) {
                    channel.invokeMethod("onFoldStateChanged", mapOf("state" to newState))
                }
            }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
            // Not needed
        }

        private fun detectFoldState(x: Float, y: Float, z: Float): String? {
            // Simplified fold detection based on device orientation
            // In production, use DeviceStateManager for proper fold detection
            return when {
                z > 8f -> "flat"
                z < -8f -> "folded"
                abs(z) < 4f -> "half_open"
                else -> null
            }
        }
    }
}
