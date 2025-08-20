import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HealthPermissionService {
  static final HealthPermissionService _instance =
      HealthPermissionService._internal();
  factory HealthPermissionService() => _instance;
  HealthPermissionService._internal();

  final Health _health = Health();
  static const String _dontRemindKey = 'health_permission_dont_remind';

  /// 检查是否设置了"不再提醒"
  Future<bool> isDontRemindSet() async {
    try {
      final box = await Hive.openBox('app_settings');
      return box.get(_dontRemindKey, defaultValue: false);
    } catch (e) {
      print('Error checking dont remind setting: $e');
      return false;
    }
  }

  /// 设置"不再提醒"
  Future<void> setDontRemind() async {
    try {
      final box = await Hive.openBox('app_settings');
      await box.put(_dontRemindKey, true);
    } catch (e) {
      print('Error setting dont remind: $e');
    }
  }

  /// 使用permission_handler请求运动权限
  Future<bool> requestActivityPermission() async {
    try {
      final status = await Permission.activityRecognition.request();
      print('Activity recognition permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('Error requesting activity permission: $e');
      return false;
    }
  }

  /// 检查运动权限状态
  Future<bool> checkActivityPermission() async {
    try {
      final status = await Permission.activityRecognition.status;
      print('Activity recognition permission status: $status');
      return status.isGranted;
    } catch (e) {
      print('Error checking activity permission: $e');
      return false;
    }
  }

  /// 打开应用设置页面
  Future<void> openAppSettingsPage() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// 检查健康数据权限状态（不自动请求权限）
  Future<bool> checkPermissions() async {
    try {
      // 通过尝试获取数据来检查权限状态，而不是直接请求权限
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      // 如果能成功获取数据，说明有权限
      final permissionsResult = await _health.hasPermissions([
        HealthDataType.STEPS,
      ]);
      final hasPermission = data.isNotEmpty || (permissionsResult ?? false);
      print('Health permissions check result: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('Error checking health permissions: $e');
      return false;
    }
  }

  /// 请求健康数据权限
  Future<bool> requestPermissions() async {
    try {
      // 首先请求活动识别和位置权限
      await Permission.activityRecognition.request();
      await Permission.location.request();

      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
      ];

      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      print('Health permissions request result: $granted');
      return granted;
    } catch (e) {
      print('Error requesting health permissions: $e');
      return false;
    }
  }

  /// 检查设备是否支持健康数据
  Future<bool> isHealthDataAvailable() async {
    try {
      final available = await _health.isDataTypeAvailable(HealthDataType.STEPS);
      print('Health data available: $available');
      return available;
    } catch (e) {
      print('Error checking health data availability: $e');
      return false;
    }
  }
}
