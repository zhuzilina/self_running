package com.example.self_running

import android.Manifest
import android.content.Context
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
    private val sensorChannelName = "com.example.self_running/sensor"
    private val healthConnectChannelName = "com.example.self_running/health_connect"

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

    // ==================== Health Connect API实现 ====================
    
    private fun isHealthConnectAvailable(result: Result) {
        try {
            // 检查Health Connect是否可用
            // 这里应该检查Health Connect服务是否安装和可用
            // 暂时返回true作为示例
            result.success(true)
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to check Health Connect availability", e.message)
        }
    }
    
    private fun requestHealthConnectPermissions(result: Result) {
        try {
            // 这里应该调用Health Connect API请求权限
            // 由于没有实际的Health Connect SDK，这里返回true作为示例
            result.success(true)
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to request Health Connect permissions", e.message)
        }
    }
    
    private fun getTodaySteps(result: Result) {
        try {
            // 模拟Health Connect API调用
            // 实际实现中应该调用Health Connect SDK
            val steps = 8000 // 模拟步数
            val timestamp = System.currentTimeMillis()
            
            val response = JSONObject().apply {
                put("steps", steps)
                put("timestamp", timestamp)
            }
            
            result.success(response.toString())
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to get today steps", e.message)
        }
    }
    
    private fun getStepsInRange(call: MethodCall, result: Result) {
        try {
            val startTime = call.argument<Long>("startTime") ?: 0L
            val endTime = call.argument<Long>("endTime") ?: 0L
            
            // 模拟Health Connect API调用
            // 实际实现中应该调用Health Connect SDK
            val steps = 8000 // 模拟步数
            val timestamp = System.currentTimeMillis()
            
            val response = JSONArray().apply {
                put(JSONObject().apply {
                    put("steps", steps)
                    put("timestamp", timestamp)
                })
            }
            
            result.success(response.toString())
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to get steps in range", e.message)
        }
    }
    
    private fun getRecentHeartRate(result: Result) {
        try {
            // 模拟获取最近一次心率数据
            // 实际实现中应该调用Health Connect SDK
            val heartRate = 72 // 模拟心率
            result.success(heartRate)
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to get recent heart rate", e.message)
        }
    }
    
    private fun getTodayCalories(result: Result) {
        try {
            // 模拟获取今日卡路里消耗
            // 实际实现中应该调用Health Connect SDK
            val calories = 450 // 模拟卡路里
            result.success(calories)
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to get today calories", e.message)
        }
    }
    
    private fun getTodayDistance(result: Result) {
        try {
            // 模拟获取今日距离
            // 实际实现中应该调用Health Connect SDK
            val distance = 6500.0 // 模拟距离（米）
            result.success(distance)
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to get today distance", e.message)
        }
    }
    
    private fun checkHealthConnectPermissions(result: Result) {
        try {
            // 模拟检查权限状态
            // 实际实现中应该调用Health Connect SDK
            val permissions = JSONObject().apply {
                put("steps", true)
                put("distance", true)
                put("calories", true)
                put("heartRate", true)
            }
            
            result.success(permissions.toString())
        } catch (e: Exception) {
            result.error("HEALTH_CONNECT_ERROR", "Failed to check permissions", e.message)
        }
    }

    // ==================== 传感器状态检查 ====================
    
    private fun getSensorStatus(result: Result) {
        try {
            val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
            val stepSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            
            val status = JSONObject().apply {
                put("stepSensorAvailable", stepSensor != null)
                put("stepSensorName", stepSensor?.name ?: "N/A")
                put("stepSensorVendor", stepSensor?.vendor ?: "N/A")
                put("stepSensorVersion", stepSensor?.version ?: 0)
                put("stepSensorPower", stepSensor?.power ?: 0.0)
                put("stepSensorResolution", stepSensor?.resolution ?: 0.0)
            }
            
            result.success(status.toString())
        } catch (e: Exception) {
            result.error("SENSOR_STATUS_ERROR", "Error getting sensor status", e.message)
        }
    }
}
