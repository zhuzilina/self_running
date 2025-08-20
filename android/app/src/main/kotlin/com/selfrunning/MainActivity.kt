package com.selfrunning

import android.Manifest
import android.content.Context
import android.content.Intent
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
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import org.json.JSONArray

class MainActivity : FlutterFragmentActivity() {
    private val sensorChannelName = "com.selfrunning/sensor"
    private val healthConnectChannelName = "com.selfrunning/health_connect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 传感器通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sensorChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCumulativeStepCount" -> getCumulativeStepCount(result)
                    "getSensorStatus" -> getSensorStatus(result)
                    else -> result.notImplemented()
                }
            }
        
        // Health Connect通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, healthConnectChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isHealthConnectAvailable" -> isHealthConnectAvailable(result)
                    "requestHealthConnectPermissions" -> requestHealthConnectPermissions(result)
                    "getTodaySteps" -> getTodaySteps(result)
                    "getStepsInRange" -> getStepsInRange(call, result)
                    "getRecentHeartRate" -> getRecentHeartRate(result)
                    "getTodayCalories" -> getTodayCalories(result)
                    "getTodayDistance" -> getTodayDistance(result)
                    "checkHealthConnectPermissions" -> checkHealthConnectPermissions(result)
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

    private fun getSensorStatus(result: MethodChannel.Result) {
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        result.success(sensor != null)
    }

    private fun isHealthConnectAvailable(result: MethodChannel.Result) {
        try {
            val packageManager = packageManager
            val healthConnectPackage = "com.google.android.apps.healthdata"
            val packageInfo = packageManager.getPackageInfo(healthConnectPackage, 0)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun requestHealthConnectPermissions(result: MethodChannel.Result) {
        try {
            val intent = Intent("androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE")
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun getTodaySteps(result: MethodChannel.Result) {
        // 这里应该实现Health Connect API调用
        // 由于Health Connect API比较复杂，这里只是示例
        result.success(0)
    }

    private fun getStepsInRange(call: MethodCall, result: MethodChannel.Result) {
        val startTime = call.argument<Long>("startTime")
        val endTime = call.argument<Long>("endTime")
        
        if (startTime == null || endTime == null) {
            result.error("INVALID_ARGUMENTS", "startTime and endTime are required", null)
            return
        }
        
        // 这里应该实现Health Connect API调用
        result.success(0)
    }

    private fun getRecentHeartRate(result: MethodChannel.Result) {
        // 这里应该实现Health Connect API调用
        result.success(null)
    }

    private fun getTodayCalories(result: MethodChannel.Result) {
        // 这里应该实现Health Connect API调用
        result.success(0)
    }

    private fun getTodayDistance(result: MethodChannel.Result) {
        // 这里应该实现Health Connect API调用
        result.success(0.0)
    }

    private fun checkHealthConnectPermissions(result: MethodChannel.Result) {
        // 这里应该实现Health Connect权限检查
        result.success(false)
    }
}
