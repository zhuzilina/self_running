import 'dart:async';

import '../../services/storage_service.dart';
import '../models/daily_steps.dart';

/// Android-only sensor based step source using TYPE_STEP_COUNTER via a pedometer plugin.
///
/// 说明：这里不直接依赖具体插件，以抽象接口方式实现。实际运行时请接入
/// 如 `pedometer` 或自定义 MethodChannel，并在 `getCurrentCumulativeCount()` 中返回
/// 系统累计计步器值（自设备启动以来累计步数）。
class SensorRepository {
  final StorageService storage;
  final Future<int?> Function() getCurrentCumulativeCount;

  SensorRepository({
    required this.storage,
    required this.getCurrentCumulativeCount,
  });

  /// 读取当天按“日”聚合的步数。
  ///
  /// - 计步传感器提供自启动以来的累计值，需要减去“今日零点时的基线值”。
  /// - 首次在某天调用时，将当前累计值记录为该日基线（后续调用用于求差）。
  Future<DailySteps?> fetchTodayBySensor() async {
    final now = DateTime.now();
    final localDay = DateTime(now.year, now.month, now.day);
    final tz = now.timeZoneOffset.inMinutes;

    final cumulative = await getCurrentCumulativeCount();
    if (cumulative == null) return null;

    final existingBaseline = storage.loadSensorBaselineForDay(localDay);

    // 首次调用：写入基线并返回 0（避免把历史累计一次性计入今日）
    if (existingBaseline == null) {
      await storage.saveSensorBaselineForDay(
        localDay: localDay,
        baselineCounter: cumulative,
      );
      return DailySteps(localDay: localDay, steps: 0, tzOffsetMinutes: tz);
    }

    final steps = cumulative - existingBaseline;
    final safeSteps = steps < 0 ? 0 : steps; // 设备重启或计数回绕时兜底
    return DailySteps(
      localDay: localDay,
      steps: safeSteps,
      tzOffsetMinutes: tz,
    );
  }
}
