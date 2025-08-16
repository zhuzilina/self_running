import 'package:flutter/services.dart';
import '../data/models/daily_steps.dart';

class HealthConnectService {
  static final HealthConnectService _instance =
      HealthConnectService._internal();
  factory HealthConnectService() => _instance;
  HealthConnectService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.example.self_running/health_connect',
  );

  /// 检查Health Connect是否可用
  Future<bool> isAvailable() async {
    try {
      final bool? available = await _channel.invokeMethod(
        'isHealthConnectAvailable',
      );
      print('Health Connect available: $available');
      return available ?? false;
    } catch (e) {
      print('Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// 请求Health Connect权限
  Future<bool> requestPermissions() async {
    try {
      final bool? granted = await _channel.invokeMethod(
        'requestHealthConnectPermissions',
      );
      print('Health Connect permissions granted: $granted');
      return granted ?? false;
    } catch (e) {
      print('Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// 获取今日步数
  Future<DailySteps?> getTodaySteps() async {
    try {
      final Map<String, dynamic>? result = await _channel.invokeMethod(
        'getTodaySteps',
      );

      if (result == null) return null;

      final int steps = result['steps'] ?? 0;
      final int timestamp =
          result['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
      final DateTime localDay = DateTime.fromMillisecondsSinceEpoch(timestamp);

      print('Today steps from Health Connect: $steps');

      return DailySteps(
        localDay: DateTime(localDay.year, localDay.month, localDay.day),
        steps: steps,
        tzOffsetMinutes: localDay.timeZoneOffset.inMinutes,
      );
    } catch (e) {
      print('Error getting today steps from Health Connect: $e');
      return null;
    }
  }

  /// 获取指定时间段的步数
  Future<List<DailySteps>> getStepsInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final List<dynamic>? results = await _channel
          .invokeMethod('getStepsInRange', {
            'startTime': startTime.millisecondsSinceEpoch,
            'endTime': endTime.millisecondsSinceEpoch,
          });

      if (results == null) return [];

      final List<DailySteps> stepsList = results.map((result) {
        final int steps = result['steps'] ?? 0;
        final int timestamp =
            result['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        final DateTime localDay = DateTime.fromMillisecondsSinceEpoch(
          timestamp,
        );

        return DailySteps(
          localDay: DateTime(localDay.year, localDay.month, localDay.day),
          steps: steps,
          tzOffsetMinutes: localDay.timeZoneOffset.inMinutes,
        );
      }).toList();

      // 按日期排序
      stepsList.sort((a, b) => a.localDay.compareTo(b.localDay));

      print('Steps data from Health Connect: ${stepsList.length} days');
      return stepsList;
    } catch (e) {
      print('Error getting steps in range from Health Connect: $e');
      return [];
    }
  }

  /// 获取最近一次心率数据
  Future<int?> getRecentHeartRate() async {
    try {
      final int? heartRate = await _channel.invokeMethod('getRecentHeartRate');
      if (heartRate != null) {
        print('Recent heart rate from Health Connect: $heartRate bpm');
      }
      return heartRate;
    } catch (e) {
      print('Error getting recent heart rate from Health Connect: $e');
      return null;
    }
  }

  /// 获取今日卡路里消耗
  Future<int?> getTodayCalories() async {
    try {
      final int? calories = await _channel.invokeMethod('getTodayCalories');
      if (calories != null) {
        print('Today calories from Health Connect: $calories');
      }
      return calories;
    } catch (e) {
      print('Error getting today calories from Health Connect: $e');
      return null;
    }
  }

  /// 获取今日距离
  Future<double?> getTodayDistance() async {
    try {
      final double? distance = await _channel.invokeMethod('getTodayDistance');
      if (distance != null) {
        print('Today distance from Health Connect: ${distance}m');
      }
      return distance;
    } catch (e) {
      print('Error getting today distance from Health Connect: $e');
      return null;
    }
  }

  /// 检查权限状态
  Future<Map<String, bool>> checkPermissions() async {
    try {
      final Map<String, dynamic>? permissions = await _channel.invokeMethod(
        'checkHealthConnectPermissions',
      );

      if (permissions == null) {
        return {
          'steps': false,
          'distance': false,
          'calories': false,
          'heartRate': false,
        };
      }

      final result = <String, bool>{
        'steps': permissions['steps'] ?? false,
        'distance': permissions['distance'] ?? false,
        'calories': permissions['calories'] ?? false,
        'heartRate': permissions['heartRate'] ?? false,
      };

      print('Health Connect permissions status: $result');
      return result;
    } catch (e) {
      print('Error checking Health Connect permissions: $e');
      return {
        'steps': false,
        'distance': false,
        'calories': false,
        'heartRate': false,
      };
    }
  }
}
