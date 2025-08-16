package com.example.self_running

import android.Manifest
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.example.self_running/sensor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCumulativeStepCount" -> getCumulativeStepCount(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun getCumulativeStepCount(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val granted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACTIVITY_RECOGNITION
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                // 不做运行时弹窗，直接返回 null，由上层兜底
                result.success(null)
                return
            }
        }

        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null) {
            result.success(null)
            return
        }

        var responded = false
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (responded) return
                responded = true
                sensorManager.unregisterListener(this)
                val value = if (event.values.isNotEmpty()) event.values[0].toInt() else 0
                result.success(value)
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
        }

        // 超时兜底：若短时间内无事件回调，返回 null
        val handler = Handler(Looper.getMainLooper())
        handler.postDelayed({
            if (!responded) {
                responded = true
                sensorManager.unregisterListener(listener)
                result.success(null)
            }
        }, 1200)

        sensorManager.registerListener(
            listener,
            sensor,
            SensorManager.SENSOR_DELAY_NORMAL
        )
    }
}
