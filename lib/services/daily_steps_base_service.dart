/*
 * Copyright 2025 榆见晴天
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:hive/hive.dart';
import '../data/models/daily_steps_base.dart';
import '../data/models/daily_steps.dart';

class DailyStepsBaseService {
  static final DailyStepsBaseService _instance =
      DailyStepsBaseService._internal();
  factory DailyStepsBaseService() => _instance;
  DailyStepsBaseService._internal();

  static const String _boxName = 'daily_steps_base';
  Box<DailyStepsBase>? _box;

  /// 初始化服务
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<DailyStepsBase>(_boxName);
    } else {
      _box = Hive.box<DailyStepsBase>(_boxName);
    }
  }

  /// 获取今日步数基数记录
  Future<DailyStepsBase?> getTodayBase() async {
    await _ensureInit();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _box!.values
        .where((base) => base.localDay.isAtSameMomentAs(startOfDay))
        .firstOrNull;
  }

  /// 获取指定日期的步数基数记录
  Future<DailyStepsBase?> getBaseByDate(DateTime date) async {
    await _ensureInit();
    final startOfDay = DateTime(date.year, date.month, date.day);

    return _box!.values
        .where((base) => base.localDay.isAtSameMomentAs(startOfDay))
        .firstOrNull;
  }

  /// 获取最近的步数基数记录
  Future<DailyStepsBase?> getLatestBase() async {
    await _ensureInit();
    if (_box!.isEmpty) return null;

    return _box!.values.reduce(
      (a, b) => a.localDay.isAfter(b.localDay) ? a : b,
    );
  }

  /// 创建或更新今日步数基数
  Future<DailyStepsBase> createOrUpdateTodayBase(int actualStepCount) async {
    await _ensureInit();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final now = DateTime.now();

    // 查找今日记录
    final existingBase = await getTodayBase();

    if (existingBase != null) {
      // 更新现有记录的实际步数，但保持基数不变
      final updatedBase = existingBase.copyWith(
        actualStepCount: actualStepCount,
        updatedAt: now,
      );
      await _box!.put(existingBase.key, updatedBase);
      assert(() {
        print('Updated today base: $updatedBase');
        return true;
      }());
      return updatedBase;
    } else {
      // 创建新记录
      final latestBase = await getLatestBase();
      int baseStepCount;

      if (latestBase != null) {
        // 计算基数：使用智能步数比对逻辑
        baseStepCount = _calculateBaseStepCount(latestBase, actualStepCount);
      } else {
        // 首次安装，基数为当前步数（这样今日步数就是0）
        baseStepCount = actualStepCount;
      }

      final newBase = DailyStepsBase(
        localDay: startOfDay,
        baseStepCount: baseStepCount,
        actualStepCount: actualStepCount,
        createdAt: now,
        updatedAt: now,
      );

      await _box!.add(newBase);
      assert(() {
        print('Created today base: $newBase');
        return true;
      }());
      return newBase;
    }
  }

  /// 智能计算步数基数
  int _calculateBaseStepCount(DailyStepsBase latestBase, int currentStepCount) {
    final today = DateTime.now();
    final latestDate = latestBase.localDay;
    final daysDifference = today.difference(latestDate).inDays;

    assert(() {

      print(
      'Days difference: $daysDifference, Latest base: ${latestBase.actualStepCount}, Current: $currentStepCount',
    );

      return true;

    }());

    if (daysDifference == 1) {
      // 相差1天：第二天的基数 = 前一天基数 + 前一天的步数值
      final newBase = latestBase.actualStepCount + latestBase.todaySteps;
      assert(() {
        print(
        'Next day base calculation: ${latestBase.actualStepCount} + ${latestBase.todaySteps} = $newBase',
      );
        return true;
      }());

      // 如果当前传感器值小于新基数，则将当前传感器值设置为基数
      if (currentStepCount < newBase) {
        print(
          'Current sensor value ($currentStepCount) < new base ($newBase), using current as base',
        );
        return currentStepCount;
      }

      return newBase;
    } else if (daysDifference > 1) {
      // 相差多天：使用最新步数作为基数
      assert(() {
        print('Multiple days difference, using latest as base');
        return true;
      }());
      return latestBase.actualStepCount;
    } else {
      // 同一天：使用最新步数作为基数
      assert(() {
        print('Same day, using latest as base');
        return true;
      }());
      return latestBase.actualStepCount;
    }
  }

  /// 获取今日实际步数
  Future<int> getTodaySteps() async {
    final todayBase = await getTodayBase();
    if (todayBase != null) {
      return todayBase.todaySteps;
    }
    return 0;
  }

  /// 更新今日实际步数
  Future<int> updateTodaySteps(int actualStepCount) async {
    final base = await createOrUpdateTodayBase(actualStepCount);
    return base.todaySteps;
  }

  /// 获取指定时间段的步数记录
  Future<List<DailySteps>> getStepsInRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    await _ensureInit();
    final startOfRange = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );
    final endOfRange = DateTime(endTime.year, endTime.month, endTime.day);

    final bases = _box!.values
        .where(
          (base) =>
              base.localDay.isAfter(
                startOfRange.subtract(const Duration(days: 1)),
              ) &&
              base.localDay.isBefore(endOfRange.add(const Duration(days: 1))),
        )
        .toList();

    return bases
        .map(
          (base) => DailySteps(
            localDay: base.localDay,
            steps: base.todaySteps,
            tzOffsetMinutes: base.localDay.timeZoneOffset.inMinutes,
          ),
        )
        .toList()
      ..sort((a, b) => a.localDay.compareTo(b.localDay));
  }

  /// 重置今日步数基数
  Future<void> resetTodayBase() async {
    await _ensureInit();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final existingBase = await getTodayBase();
    if (existingBase != null) {
      await _box!.delete(existingBase.key);
      assert(() {
        print('Reset today base');
        return true;
      }());
    }
  }

  /// 获取所有步数基数记录
  Future<List<DailyStepsBase>> getAllBases() async {
    await _ensureInit();
    return _box!.values.toList()
      ..sort((a, b) => a.localDay.compareTo(b.localDay));
  }

  /// 清理旧数据（保留最近30天）
  Future<void> cleanupOldData() async {
    await _ensureInit();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final keysToDelete = <dynamic>[];
    for (final base in _box!.values) {
      if (base.localDay.isBefore(thirtyDaysAgo)) {
        keysToDelete.add(base.key);
      }
    }

    await _box!.deleteAll(keysToDelete);
    assert(() {
      print('Cleaned up ${keysToDelete.length} old base records');
      return true;
    }());
  }

  /// 确保初始化
  Future<void> _ensureInit() async {
    if (_box == null) {
      await init();
    }
  }

  /// 关闭服务
  Future<void> close() async {
    await _box?.close();
  }
}
