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

class RealtimeStepsService {
  static final RealtimeStepsService _instance =
      RealtimeStepsService._internal();
  factory RealtimeStepsService() => _instance;
  RealtimeStepsService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.example.self_running/sensor',
  );
  final StorageService _storage = StorageService();
  final DailyStepsBaseService _baseService = DailyStepsBaseService();

  Timer? _timer;
  StreamController<DailySteps?>? _stepsController;

  /// 获取今日步数的流
  Stream<DailySteps?> get todayStepsStream {
    _stepsController ??= StreamController<DailySteps?>.broadcast();
    return _stepsController!.stream;
  }

  /// 初始化服务
  Future<void> initialize() async {
    print('Initializing realtime steps service (sensor only)...');
    await _storage.init();
    await _baseService.init();

    // 立即获取一次今日步数
    await _fetchTodaySteps();

    // 启动定时器，每30秒更新一次
    _startPeriodicUpdate();
  }

  /// 启动定时更新
  void _startPeriodicUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchTodaySteps();
    });
    print('Started periodic sensor steps update (30s interval)');
  }

  /// 获取今日步数
  Future<DailySteps?> _fetchTodaySteps() async {
    try {
      final stepCount = await _channel.invokeMethod<int>(
        'getCumulativeStepCount',
      );

      if (stepCount != null) {
        assert(() {
          print('Current sensor step count: $stepCount');
          return true;
        }());

        // 使用步数基数服务计算今日步数
        final todaySteps = await _calculateTodayStepsWithBase(stepCount);

        if (todaySteps != null) {
          _stepsController?.add(todaySteps);
          await _saveTodaySteps(todaySteps);
          assert(() {
            print('Updated today steps: ${todaySteps.steps}');
            return true;
          }());
        }

        return todaySteps;
      } else {
        assert(() {
          print('Failed to get sensor step count');
          return true;
        }());
        _stepsController?.add(null);
        return null;
      }
    } catch (e) {
      assert(() {
        print('Error fetching today steps from sensor: $e');
        return true;
      }());
      _stepsController?.add(null);
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

  /// 手动刷新今日步数
  Future<DailySteps?> refreshTodaySteps() async {
    return await _fetchTodaySteps();
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

  /// 停止服务
  void dispose() {
    _timer?.cancel();
    _stepsController?.close();
    assert(() {
      print('Realtime steps service disposed');
      return true;
    }());
  }
}
