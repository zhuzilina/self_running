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

import 'dart:async';
import 'package:flutter/services.dart';
import '../data/models/daily_steps.dart';
import '../services/storage_service.dart';
import '../services/daily_steps_base_service.dart';

class SensorStepsService {
  static final SensorStepsService _instance = SensorStepsService._internal();
  factory SensorStepsService() => _instance;
  SensorStepsService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.example.self_running/sensor',
  );
  final StorageService _storage = StorageService();
  final DailyStepsBaseService _baseService = DailyStepsBaseService();

  int _lastStepCount = 0;
  DateTime? _lastUpdateTime;
  Timer? _periodicTimer;
  StreamController<DailySteps?>? _stepsController;

  /// 获取今日步数的流
  Stream<DailySteps?> get todayStepsStream {
    _stepsController ??= StreamController<DailySteps?>.broadcast();
    return _stepsController!.stream;
  }

  /// 初始化传感器服务
  Future<void> initialize() async {
    assert(() {
      print('Initializing sensor steps service...');
      return true;
    }());
    await _storage.init();
    await _baseService.init();
    await _fetchCurrentSteps();
    _startPeriodicUpdate();
  }

  /// 启动定时更新
  void _startPeriodicUpdate() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchCurrentSteps();
    });
    print('Started periodic sensor steps update (30s interval)');
  }

  /// 获取当前传感器步数
  Future<int?> _fetchCurrentSteps() async {
    try {
      final stepCount = await _channel.invokeMethod<int>(
        'getCumulativeStepCount',
      );

      if (stepCount != null) {
        assert(() {
          print('Current sensor step count: $stepCount');
          return true;
        }());

        // 使用新的步数基数服务计算今日步数
        final todaySteps = await _calculateTodayStepsWithBase(stepCount);

        if (todaySteps != null) {
          _stepsController?.add(todaySteps);
          await _saveTodaySteps(todaySteps);
          assert(() {
            print('Updated today steps: ${todaySteps.steps}');
            return true;
          }());
        }

        _lastStepCount = stepCount;
        _lastUpdateTime = DateTime.now();
        return stepCount;
      } else {
        assert(() {
          print('Failed to get sensor step count');
          return true;
        }());
        return null;
      }
    } catch (e) {
      assert(() {
        print('Error fetching sensor steps: $e');
        return true;
      }());
      return null;
    }
  }

  /// 使用步数基数计算今日步数
  Future<DailySteps?> _calculateTodayStepsWithBase(int currentStepCount) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // 使用步数基数服务更新今日步数
      final todaySteps = await _baseService.updateTodaySteps(currentStepCount);

      if (todaySteps >= 0) {
        final dailySteps = DailySteps(
          localDay: startOfDay,
          steps: todaySteps,
          tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
        );
        print(
          'Calculated today steps with base: $todaySteps (actual: $currentStepCount)',
        );
        return dailySteps;
      }
      return null;
    } catch (e) {
      assert(() {
        print('Error calculating today steps with base: $e');
        return true;
      }());
      return null;
    }
  }

  /// 计算今日步数（旧方法，保留兼容性）
  Future<DailySteps?> _calculateTodaySteps(int currentStepCount) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final todaySteps = await _getTodayStepsFromStorage();

      if (todaySteps != null) {
        final lastStepCount = todaySteps.steps;
        final stepIncrement = currentStepCount - lastStepCount;

        if (stepIncrement >= 0) {
          final updatedSteps = DailySteps(
            localDay: startOfDay,
            steps: currentStepCount,
            tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
          );
          print(
            'Updated today steps: $currentStepCount (increment: $stepIncrement)',
          );
          return updatedSteps;
        }
      } else {
        final todaySteps = DailySteps(
          localDay: startOfDay,
          steps: currentStepCount,
          tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
        );
        assert(() {
          print('First time today steps: $currentStepCount');
          return true;
        }());
        return todaySteps;
      }
      return null;
    } catch (e) {
      assert(() {
        print('Error calculating today steps: $e');
        return true;
      }());
      return null;
    }
  }

  /// 从存储获取今日步数
  Future<DailySteps?> _getTodayStepsFromStorage() async {
    try {
      final allSteps = _storage.loadAllDailySteps();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      for (final steps in allSteps) {
        if (steps.localDay.isAtSameMomentAs(startOfDay)) {
          return steps;
        }
      }
      return null;
    } catch (e) {
      assert(() {
        print('Error getting today steps from storage: $e');
        return true;
      }());
      return null;
    }
  }

  /// 保存今日步数到存储
  Future<void> _saveTodaySteps(DailySteps todaySteps) async {
    try {
      final allSteps = _storage.loadAllDailySteps();
      bool found = false;

      for (int i = 0; i < allSteps.length; i++) {
        if (allSteps[i].localDay.isAtSameMomentAs(todaySteps.localDay)) {
          allSteps[i] = todaySteps;
          found = true;
          break;
        }
      }

      if (!found) {
        allSteps.add(todaySteps);
      }

      await _storage.saveDailySteps(allSteps);
      assert(() {
        print('Today steps saved to storage: ${todaySteps.steps}');
        return true;
      }());
    } catch (e) {
      assert(() {
        print('Error saving today steps: $e');
        return true;
      }());
    }
  }

  /// 手动刷新步数
  Future<DailySteps?> refreshSteps() async {
    final stepCount = await _fetchCurrentSteps();
    if (stepCount != null) {
      return await _calculateTodaySteps(stepCount);
    }
    return null;
  }

  /// 重置今日步数
  Future<void> resetTodaySteps() async {
    try {
      // 重置步数基数
      await _baseService.resetTodayBase();

      // 重新获取当前步数并计算
      final currentStepCount = await _channel.invokeMethod<int>(
        'getCumulativeStepCount',
      );

      if (currentStepCount != null) {
        final todaySteps = await _calculateTodayStepsWithBase(currentStepCount);
        if (todaySteps != null) {
          await _saveTodaySteps(todaySteps);
          _lastStepCount = currentStepCount;
          _lastUpdateTime = DateTime.now();
          print(
            'Reset today steps to: ${todaySteps.steps} (actual: $currentStepCount)',
          );
        }
      }
    } catch (e) {
      assert(() {
        print('Error resetting today steps: $e');
        return true;
      }());
    }
  }

  /// 停止服务
  void dispose() {
    _periodicTimer?.cancel();
    _stepsController?.close();
    assert(() {
      print('Sensor steps service disposed');
      return true;
    }());
  }
}
