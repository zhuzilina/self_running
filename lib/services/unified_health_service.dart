import '../data/models/daily_steps.dart';
import 'health_connect_service.dart';
import 'health_permission_service.dart';

enum HealthDataSource { healthConnect, healthKit, googleFit, sensor, none }

class UnifiedHealthService {
  static final UnifiedHealthService _instance =
      UnifiedHealthService._internal();
  factory UnifiedHealthService() => _instance;
  UnifiedHealthService._internal();

  final HealthConnectService _healthConnectService = HealthConnectService();
  final HealthPermissionService _healthPermissionService =
      HealthPermissionService();

  HealthDataSource? _currentDataSource;

  /// 初始化健康数据服务
  Future<void> initialize() async {
    print('Initializing unified health service...');

    // 优先尝试Health Connect
    final isHealthConnectAvailable = await _healthConnectService.isAvailable();
    if (isHealthConnectAvailable) {
      _currentDataSource = HealthDataSource.healthConnect;
      print('Using Health Connect data source');
      return;
    }

    // 检查Google Fit/HealthKit
    final isHealthAvailable = await _healthPermissionService
        .isHealthDataAvailable();
    if (isHealthAvailable) {
      _currentDataSource = HealthDataSource.googleFit;
      print('Using Google Fit/HealthKit data source');
      return;
    }

    // 使用传感器
    _currentDataSource = HealthDataSource.sensor;
    print('Using sensor data source');
  }

  /// 获取当前健康数据源
  HealthDataSource? getCurrentDataSource() {
    return _currentDataSource;
  }

  /// 请求健康数据权限
  Future<bool> requestPermissions() async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.requestPermissions();
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        return await _healthPermissionService.requestPermissions();
      case HealthDataSource.sensor:
        return true; // 传感器不需要特殊权限
      case HealthDataSource.none:
      default:
        return false;
    }
  }

  /// 获取今日步数
  Future<DailySteps?> getTodaySteps() async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.getTodaySteps();
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        // 暂时返回null，后续可以扩展
        return null;
      case HealthDataSource.sensor:
        // 暂时返回null，后续可以扩展
        return null;
      case HealthDataSource.none:
      default:
        return null;
    }
  }

  /// 获取指定时间段的步数
  Future<List<DailySteps>> getStepsInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.getStepsInRange(startTime, endTime);
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        // 暂时返回空列表，后续可以扩展
        return [];
      case HealthDataSource.sensor:
        // 暂时返回空列表，后续可以扩展
        return [];
      case HealthDataSource.none:
      default:
        return [];
    }
  }

  /// 获取最近一次心率数据
  Future<int?> getRecentHeartRate() async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.getRecentHeartRate();
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        // 这里可以扩展获取心率数据
        return null;
      case HealthDataSource.sensor:
      case HealthDataSource.none:
      default:
        return null;
    }
  }

  /// 获取今日卡路里消耗
  Future<int?> getTodayCalories() async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.getTodayCalories();
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        // 这里可以扩展获取卡路里数据
        return null;
      case HealthDataSource.sensor:
      case HealthDataSource.none:
      default:
        return null;
    }
  }

  /// 获取今日距离
  Future<double?> getTodayDistance() async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.getTodayDistance();
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        // 这里可以扩展获取距离数据
        return null;
      case HealthDataSource.sensor:
      case HealthDataSource.none:
      default:
        return null;
    }
  }

  /// 检查权限状态
  Future<Map<String, bool>> checkPermissions() async {
    switch (_currentDataSource) {
      case HealthDataSource.healthConnect:
        return await _healthConnectService.checkPermissions();
      case HealthDataSource.healthKit:
      case HealthDataSource.googleFit:
        // 暂时返回空权限状态，后续可以扩展
        return {
          'steps': false,
          'distance': false,
          'calories': false,
          'heartRate': false,
        };
      case HealthDataSource.sensor:
        return {
          'steps': true,
          'distance': false,
          'calories': false,
          'heartRate': false,
        };
      case HealthDataSource.none:
      default:
        return {
          'steps': false,
          'distance': false,
          'calories': false,
          'heartRate': false,
        };
    }
  }
}
