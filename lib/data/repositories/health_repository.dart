import 'package:health/health.dart';
import '../models/daily_steps.dart';

class HealthRepository {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
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
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      print('Health permissions granted: $granted');
      return granted;
    } catch (e) {
      print('Health permissions error: $e');
      return false;
    }
  }

  Future<List<DailySteps>> fetchDailySteps(DateTime from, DateTime to) async {
    try {
      print(
        'Fetching health data from ${from.toIso8601String()} to ${to.toIso8601String()}',
      );

      // 不再自动请求权限，直接尝试获取数据
      // 如果没有权限，将返回空列表

      print('Requesting health data...');
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: from,
        endTime: to,
      );

      print('Received ${raw.length} health data points');
      final mapped = raw;
      final Map<DateTime, int> bucket = {};

      for (final d in mapped) {
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
      print('Error fetching health data: $e');
      // 在非支持平台或无权限时，容错返回空列表
      return [];
    }
  }
}
