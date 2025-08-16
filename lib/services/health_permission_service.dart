import 'package:health/health.dart';

class HealthPermissionService {
  static final HealthPermissionService _instance =
      HealthPermissionService._internal();
  factory HealthPermissionService() => _instance;
  HealthPermissionService._internal();

  final Health _health = Health();

  /// 检查健康数据权限状态
  Future<bool> checkPermissions() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
      ];

      final permissions = [HealthDataAccess.READ];

      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      print('Health permissions check result: $granted');
      return granted;
    } catch (e) {
      print('Error checking health permissions: $e');
      return false;
    }
  }

  /// 请求健康数据权限
  Future<bool> requestPermissions() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
      ];

      final permissions = [HealthDataAccess.READ];

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

