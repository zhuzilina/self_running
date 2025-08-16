import 'package:workmanager/workmanager.dart';
import 'package:flutter/services.dart';
import '../data/models/daily_steps.dart';
import '../services/storage_service.dart';
import '../services/daily_steps_base_service.dart';

// 后台任务处理器 - 必须是顶层函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Background task started: $task');

    try {
      switch (task) {
        case 'fetch_steps_task':
          await _handleStepsFetchTask();
          break;
        case 'reset_daily_steps':
          await _handleResetDailySteps();
          break;
        default:
          print('Unknown task: $task');
      }

      print('Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      print('Background task failed: $task, error: $e');
      return Future.value(false);
    }
  });
}

/// 处理步数获取任务
Future<void> _handleStepsFetchTask() async {
  try {
    print('Fetching steps in background...');

    final storage = StorageService();
    final baseService = DailyStepsBaseService();
    await storage.init();
    await baseService.init();

    const channel = MethodChannel('com.example.self_running/sensor');
    final stepCount = await channel.invokeMethod<int>('getCumulativeStepCount');

    if (stepCount != null) {
      print('Background step count: $stepCount');

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
        print('Background steps saved: $todaySteps (actual: $stepCount)');
      }
    }
  } catch (e) {
    print('Error in background steps fetch: $e');
  }
}

/// 处理重置每日步数任务
Future<void> _handleResetDailySteps() async {
  try {
    print('Resetting daily steps in background...');

    final storage = StorageService();
    final baseService = DailyStepsBaseService();
    await storage.init();
    await baseService.init();

    // 重置今日步数基数
    await baseService.resetTodayBase();

    const channel = MethodChannel('com.example.self_running/sensor');
    final stepCount = await channel.invokeMethod<int>('getCumulativeStepCount');

    if (stepCount != null) {
      // 使用步数基数服务重新计算今日步数
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
        print(
          'Background daily steps reset to: $todaySteps (actual: $stepCount)',
        );
      }
    }
  } catch (e) {
    print('Error in background reset daily steps: $e');
  }
}

/// 计算今日步数
Future<DailySteps?> _calculateTodaySteps(
  int currentStepCount,
  StorageService storage,
) async {
  try {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final allSteps = storage.loadAllDailySteps();

    DailySteps? todaySteps;
    for (final steps in allSteps) {
      if (steps.localDay.isAtSameMomentAs(startOfDay)) {
        todaySteps = steps;
        break;
      }
    }

    if (todaySteps != null) {
      final updatedSteps = DailySteps(
        localDay: startOfDay,
        steps: currentStepCount,
        tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
      );
      return updatedSteps;
    } else {
      final newTodaySteps = DailySteps(
        localDay: startOfDay,
        steps: currentStepCount,
        tzOffsetMinutes: startOfDay.timeZoneOffset.inMinutes,
      );
      return newTodaySteps;
    }
  } catch (e) {
    print('Error calculating today steps in background: $e');
    return null;
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
  } catch (e) {
    print('Error saving today steps in background: $e');
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
    print('Initializing background steps service...');
    await Workmanager().initialize(callbackDispatcher);
    await _registerPeriodicTasks();
    print('Background steps service initialized');
  }

  /// 注册定时任务
  Future<void> _registerPeriodicTasks() async {
    try {
      await Workmanager().registerPeriodicTask(
        'fetch_steps_task',
        'fetch_steps_task',
        frequency: const Duration(hours: 4),
        constraints: Constraints(
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      await Workmanager().registerPeriodicTask(
        'reset_daily_steps',
        'reset_daily_steps',
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      print('Periodic tasks registered successfully');
    } catch (e) {
      print('Error registering periodic tasks: $e');
    }
  }

  /// 立即执行一次步数获取任务
  Future<void> executeStepsFetchNow() async {
    try {
      await Workmanager().registerOneOffTask(
        'fetch_steps_task_now',
        'fetch_steps_task',
        initialDelay: const Duration(seconds: 5),
      );
      print('Immediate steps fetch task scheduled');
    } catch (e) {
      print('Error scheduling immediate steps fetch: $e');
    }
  }

  /// 立即执行一次重置任务
  Future<void> executeResetNow() async {
    try {
      await Workmanager().registerOneOffTask(
        'reset_daily_steps_now',
        'reset_daily_steps',
        initialDelay: const Duration(seconds: 5),
      );
      print('Immediate reset task scheduled');
    } catch (e) {
      print('Error scheduling immediate reset: $e');
    }
  }

  /// 取消所有任务
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      print('All background tasks cancelled');
    } catch (e) {
      print('Error cancelling background tasks: $e');
    }
  }

  /// 获取任务状态
  Future<void> getTaskStatus() async {
    try {
      // WorkManager没有直接的状态查询API，但我们可以通过日志来监控
      print('Background tasks are running...');
      print('Check logs for task execution status');
    } catch (e) {
      print('Error getting task status: $e');
    }
  }
}
