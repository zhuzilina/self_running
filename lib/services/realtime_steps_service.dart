import 'dart:async';
import 'package:health/health.dart';
import '../data/models/daily_steps.dart';

class RealtimeStepsService {
  static final RealtimeStepsService _instance =
      RealtimeStepsService._internal();
  factory RealtimeStepsService() => _instance;
  RealtimeStepsService._internal();

  final Health _health = Health();
  Timer? _timer;
  StreamController<DailySteps?>? _stepsController;

  /// 获取今日步数的流
  Stream<DailySteps?> get todayStepsStream {
    _stepsController ??= StreamController<DailySteps?>.broadcast();
    return _stepsController!.stream;
  }

  /// 初始化服务
  Future<void> initialize() async {
    print('Initializing realtime steps service...');

    // 配置health插件
    await _health.configure();

    // 请求权限
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
    print('Health permissions granted: $granted');

    if (granted) {
      // 立即获取一次今日步数
      await _fetchTodaySteps();

      // 启动定时器，每30秒更新一次
      _startPeriodicUpdate();
    }
  }

  /// 启动定时更新
  void _startPeriodicUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchTodaySteps();
    });
    print('Started periodic steps update (30s interval)');
  }

  /// 获取今日步数
  Future<DailySteps?> _fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // 使用getTotalStepsInInterval获取今日总步数
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);

      if (steps != null && steps > 0) {
        final todaySteps = DailySteps(
          localDay: startOfDay,
          steps: steps,
          tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
        );

        print('Today steps: $steps');
        _stepsController?.add(todaySteps);
        return todaySteps;
      } else {
        print('No steps data available for today');
        _stepsController?.add(null);
        return null;
      }
    } catch (e) {
      print('Error fetching today steps: $e');
      _stepsController?.add(null);
      return null;
    }
  }

  /// 手动刷新今日步数
  Future<DailySteps?> refreshTodaySteps() async {
    return await _fetchTodaySteps();
  }

  /// 获取指定时间段的步数
  Future<List<DailySteps>> getStepsInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: startTime,
        endTime: endTime,
      );

      print('Received ${raw.length} health data points');
      final Map<DateTime, int> bucket = {};

      for (final d in raw) {
        final local = DateTime(
          d.dateFrom.year,
          d.dateFrom.month,
          d.dateFrom.day,
        );
        final value = (d.value as num?)?.toInt() ?? 0;
        bucket[local] = (bucket[local] ?? 0) + value;
        print('Health data: ${d.dateFrom} -> $value steps');
      }

      final List<DailySteps> list =
          bucket.entries
              .map(
                (e) => DailySteps(
                  localDay: e.key,
                  steps: e.value,
                  tzOffsetMinutes: e.key.timeZoneOffset.inMinutes,
                ),
              )
              .toList()
            ..sort((a, b) => a.localDay.compareTo(b.localDay));

      print('Processed ${list.length} daily steps records');
      return list;
    } catch (e) {
      print('Error fetching steps in range: $e');
      return [];
    }
  }

  /// 获取最近一次心率
  Future<int?> getRecentHeartRate() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: oneHourAgo,
        endTime: now,
      );

      if (raw.isNotEmpty) {
        // 获取最新的心率数据
        raw.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final latest = raw.first;
        final heartRate = (latest.value as num?)?.toInt();
        print('Recent heart rate: $heartRate bpm');
        return heartRate;
      }

      return null;
    } catch (e) {
      print('Error fetching heart rate: $e');
      return null;
    }
  }

  /// 获取今日卡路里
  Future<int?> getTodayCalories() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );

      int totalCalories = 0;
      for (final d in raw) {
        final value = (d.value as num?)?.toInt() ?? 0;
        totalCalories += value;
      }

      print('Today calories: $totalCalories');
      return totalCalories > 0 ? totalCalories : null;
    } catch (e) {
      print('Error fetching calories: $e');
      return null;
    }
  }

  /// 停止服务
  void dispose() {
    _timer?.cancel();
    _stepsController?.close();
    print('Realtime steps service disposed');
  }

  /// 写入测试步数数据
  Future<bool> writeTestSteps() async {
    try {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(minutes: 10));

      final success = await _health.writeHealthData(
        value: 1000, // 写入1000步测试数据
        type: HealthDataType.STEPS,
        startTime: earlier,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );

      print('Test steps written: $success');
      if (success) {
        // 写入成功后立即获取最新数据
        await _fetchTodaySteps();
      }
      return success;
    } catch (e) {
      print('Error writing test steps: $e');
      return false;
    }
  }
}
