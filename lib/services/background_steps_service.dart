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

import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';
import '../data/models/daily_steps.dart';
import '../data/models/daily_steps_base.dart';
import '../services/storage_service.dart';
import '../services/daily_steps_base_service.dart';

// WorkManager回调函数 - 必须是顶层函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    assert(() {
      print('Background task started: $task');
      return true;
    }());

    try {
      switch (task) {
        case 'fetch_daily_steps_base':
          await _handleDailyStepsBaseTask();
          break;
        case 'update_steps_base':
          await _handleUpdateStepsBaseTask();
          break;
        default:
          assert(() {
            print('Unknown task: $task');
            return true;
          }());
      }

      assert(() {

        print('Background task completed: $task');

        return true;

      }());
      return Future.value(true);
    } catch (e) {
      assert(() {
        print('Background task failed: $task, error: $e');
        return true;
      }());
      return Future.value(false);
    }
  });
}

/// 处理每日步数基数获取任务
Future<void> _handleDailyStepsBaseTask() async {
  try {
    assert(() {
      print('Fetching daily steps base in background...');
      return true;
    }());

    final storage = StorageService();
    final baseService = DailyStepsBaseService();
    await storage.init();
    await baseService.init();

    const channel = MethodChannel('com.example.self_running/sensor');
    final stepCount = await channel.invokeMethod<int>('getCumulativeStepCount');

    if (stepCount != null) {
      assert(() {
        print('Background step count: $stepCount');
        return true;
      }());

      // 获取今日步数基数记录
      final todayBase = await baseService.getTodayBase();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      if (todayBase == null) {
        // 今日还没有基数记录，创建新的基数记录
        final latestBase = await baseService.getLatestBase();
        int baseStepCount;

        if (latestBase != null) {
          // 计算基数：使用智能步数比对逻辑
          baseStepCount = _calculateBaseStepCount(latestBase, stepCount);
        } else {
          // 首次安装，基数为当前步数
          baseStepCount = stepCount;
        }

        final newBase = DailyStepsBase(
          localDay: startOfDay,
          baseStepCount: baseStepCount,
          actualStepCount: stepCount,
          createdAt: now,
          updatedAt: now,
        );

        // 使用baseService的方法来添加记录
        await baseService.createOrUpdateTodayBase(stepCount);
        assert(() {
          print('Created daily steps base in background: $newBase');
          return true;
        }());
      } else {
        // 今日已有基数记录，检查是否需要更新
        final timeDifference = now.difference(todayBase.updatedAt);

        // 如果距离上次更新超过1小时，或者当前步数明显增加，则更新
        if (timeDifference.inHours >= 1 ||
            stepCount > todayBase.actualStepCount + 100) {
          await baseService.createOrUpdateTodayBase(stepCount);
          assert(() {
            print('Updated daily steps base in background');
            return true;
          }());
        } else {
          assert(() {
            print('Daily steps base up to date, no update needed');
            return true;
          }());
        }
      }
    } else {
      assert(() {
        print('Failed to get step count in background');
        return true;
      }());
    }
  } catch (e) {
    assert(() {
      print('Error handling daily steps base task: $e');
      return true;
    }());
  }
}

/// 处理更新步数基数任务
Future<void> _handleUpdateStepsBaseTask() async {
  try {
    assert(() {
      print('Updating steps base in background...');
      return true;
    }());

    final storage = StorageService();
    final baseService = DailyStepsBaseService();
    await storage.init();
    await baseService.init();

    const channel = MethodChannel('com.example.self_running/sensor');
    final stepCount = await channel.invokeMethod<int>('getCumulativeStepCount');

    if (stepCount != null) {
      assert(() {
        print('Background step count for update: $stepCount');
        return true;
      }());

      // 使用步数基数服务更新今日步数
      final todaySteps = await baseService.updateTodaySteps(stepCount);

      if (todaySteps >= 0) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        final dailySteps = DailySteps(
          localDay: startOfDay,
          steps: todaySteps,
          tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
        );

        await _saveTodaySteps(dailySteps, storage);
        assert(() {
          print('Updated steps base in background: $todaySteps');
          return true;
        }());
      }
    } else {
      assert(() {
        print('Failed to get step count for update in background');
        return true;
      }());
    }
  } catch (e) {
    assert(() {
      print('Error handling update steps base task: $e');
      return true;
    }());
  }
}

/// 智能计算步数基数（与DailyStepsBaseService中的逻辑保持一致）
int _calculateBaseStepCount(DailyStepsBase latestBase, int currentStepCount) {
  final today = DateTime.now();
  final latestDate = latestBase.localDay;
  final daysDifference = today.difference(latestDate).inDays;

  assert(() {

    print(
    'Background - Days difference: $daysDifference, Latest base: ${latestBase.actualStepCount}, Current: $currentStepCount',
  );

    return true;

  }());

  if (daysDifference == 1) {
    // 相差1天：第二天的基数 = 前一天基数 + 前一天的步数值
    final newBase = latestBase.actualStepCount + latestBase.todaySteps;
    assert(() {
      print(
      'Background - Next day base calculation: ${latestBase.actualStepCount} + ${latestBase.todaySteps} = $newBase',
    );
      return true;
    }());

    // 如果当前传感器值小于新基数，则将当前传感器值设置为基数
    if (currentStepCount < newBase) {
      print(
        'Background - Current sensor value ($currentStepCount) < new base ($newBase), using current as base',
      );
      return currentStepCount;
    }

    return newBase;
  } else if (daysDifference > 1) {
    // 相差多天：使用最新步数作为基数
    assert(() {
      print('Background - Multiple days difference, using latest as base');
      return true;
    }());
    return latestBase.actualStepCount;
  } else {
    // 同一天：使用最新步数作为基数
    assert(() {
      print('Background - Same day, using latest as base');
      return true;
    }());
    return latestBase.actualStepCount;
  }
}

/// 保存今日步数
Future<void> _saveTodaySteps(
  DailySteps todaySteps,
  StorageService storage,
) async {
  try {
    final allSteps = storage.loadAllDailySteps();
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

    await storage.saveDailySteps(allSteps);
    assert(() {
      print('Background - Today steps saved to storage: ${todaySteps.steps}');
      return true;
    }());
  } catch (e) {
    assert(() {
      print('Background - Error saving today steps: $e');
      return true;
    }());
  }
}

/// 后台步数服务管理类
class BackgroundStepsService {
  static final BackgroundStepsService _instance =
      BackgroundStepsService._internal();
  factory BackgroundStepsService() => _instance;
  BackgroundStepsService._internal();

  /// 初始化WorkManager
  Future<void> initialize() async {
    assert(() {
      print('Initializing background steps service...');
      return true;
    }());
    await Workmanager().initialize(callbackDispatcher);
    await _registerPeriodicTasks();
    assert(() {
      print('Background steps service initialized');
      return true;
    }());
  }

  /// 注册定时任务
  Future<void> _registerPeriodicTasks() async {
    try {
      // 注册每日步数基数获取任务（每天凌晨2点执行）
      await Workmanager().registerPeriodicTask(
        'fetch_daily_steps_base',
        'fetch_daily_steps_base',
        frequency: const Duration(days: 1),
        initialDelay: _getInitialDelay(),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // 注册步数基数更新任务（每4小时执行一次）
      await Workmanager().registerPeriodicTask(
        'update_steps_base',
        'update_steps_base',
        frequency: const Duration(hours: 4),
        initialDelay: const Duration(minutes: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      assert(() {

        print('Background tasks registered successfully');

        return true;

      }());
    } catch (e) {
      assert(() {
        print('Error registering background tasks: $e');
        return true;
      }());
    }
  }

  /// 计算初始延迟时间（到下一个凌晨2点）
  Duration _getInitialDelay() {
    final now = DateTime.now();
    final nextRun = DateTime(now.year, now.month, now.day + 1, 2, 0, 0);
    return nextRun.difference(now);
  }

  /// 手动触发步数基数获取任务
  Future<void> triggerDailyStepsBaseTask() async {
    try {
      await Workmanager().registerOneOffTask(
        'fetch_daily_steps_base_manual',
        'fetch_daily_steps_base',
        initialDelay: const Duration(seconds: 5),
      );
      assert(() {
        print('Manual daily steps base task triggered');
        return true;
      }());
    } catch (e) {
      assert(() {
        print('Error triggering manual daily steps base task: $e');
        return true;
      }());
    }
  }

  /// 手动触发步数基数更新任务
  Future<void> triggerUpdateStepsBaseTask() async {
    try {
      await Workmanager().registerOneOffTask(
        'update_steps_base_manual',
        'update_steps_base',
        initialDelay: const Duration(seconds: 5),
      );
      assert(() {
        print('Manual update steps base task triggered');
        return true;
      }());
    } catch (e) {
      assert(() {
        print('Error triggering manual update steps base task: $e');
        return true;
      }());
    }
  }

  /// 取消所有后台任务
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      assert(() {
        print('All background tasks cancelled');
        return true;
      }());
    } catch (e) {
      assert(() {
        print('Error cancelling background tasks: $e');
        return true;
      }());
    }
  }

  /// 获取任务状态
  Future<void> getTaskStatus() async {
    try {
      // WorkManager没有直接的状态查询API，这里只是记录日志
      assert(() {
        print('Background tasks status: Active');
        return true;
      }());
    } catch (e) {
      assert(() {
        print('Error getting task status: $e');
        return true;
      }());
    }
  }
}
