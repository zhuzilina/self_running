# 后台步数服务使用说明

## 功能概述

后台步数服务使用WorkManager实现，让App每日在没有被打开时尝试获取步数基数，确保步数数据的连续性和准确性。

## 主要功能

### 1. 每日步数基数获取任务
- **执行时间**：每天凌晨2点
- **功能**：获取当日的步数基数，使用时间最早的一次加上前一天的步数记录
- **任务名称**：`fetch_daily_steps_base`

### 2. 步数基数更新任务
- **执行时间**：每4小时执行一次
- **功能**：更新当日的步数基数，确保数据实时性
- **任务名称**：`update_steps_base`

## 步数基数计算逻辑

### 计算规则
1. **App首次初始化**：以第一次获取的传感器步数为基数
2. **第二天的基数**：前一天基数 + 前一天的步数值
3. **异常处理**：如果当前传感器的值小于基数值，则将当前传感器值设置为基数值

### 具体实现

```dart
/// 智能计算步数基数
int _calculateBaseStepCount(DailyStepsBase latestBase, int currentStepCount) {
  final today = DateTime.now();
  final latestDate = latestBase.localDay;
  final daysDifference = today.difference(latestDate).inDays;

  if (daysDifference == 1) {
    // 相差1天：第二天的基数 = 前一天基数 + 前一天的步数值
    final newBase = latestBase.actualStepCount + latestBase.todaySteps;
    
    // 如果当前传感器值小于新基数，则将当前传感器值设置为基数
    if (currentStepCount < newBase) {
      return currentStepCount;
    }
    
    return newBase;
  } else if (daysDifference > 1) {
    // 相差多天：使用最新步数作为基数
    return latestBase.actualStepCount;
  } else {
    // 同一天：使用最新步数作为基数
    return latestBase.actualStepCount;
  }
}
```

## 任务配置

### 每日步数基数获取任务
```dart
await Workmanager().registerPeriodicTask(
  'fetch_daily_steps_base',
  'fetch_daily_steps_base',
  frequency: const Duration(days: 1),
  initialDelay: _getInitialDelay(), // 到下一个凌晨2点
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: false,
    requiresCharging: false,
    requiresDeviceIdle: false,
    requiresStorageNotLow: false,
  ),
);
```

### 步数基数更新任务
```dart
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
```

## 使用方法

### 1. 初始化服务
```dart
final backgroundService = BackgroundStepsService();
await backgroundService.initialize();
```

### 2. 手动触发任务
```dart
// 手动触发步数基数获取任务
await backgroundService.triggerDailyStepsBaseTask();

// 手动触发步数基数更新任务
await backgroundService.triggerUpdateStepsBaseTask();
```

### 3. 管理任务
```dart
// 取消所有后台任务
await backgroundService.cancelAllTasks();

// 获取任务状态
await backgroundService.getTaskStatus();
```

## 工作流程

### 每日步数基数获取任务流程
1. **检查今日基数记录**：查看是否已有今日的步数基数记录
2. **创建或更新基数**：
   - 如果没有记录，创建新的基数记录
   - 如果有记录，检查是否需要更新（超过1小时或步数明显增加）
3. **计算基数**：使用智能基数计算逻辑
4. **保存数据**：将基数信息保存到本地存储

### 步数基数更新任务流程
1. **获取当前步数**：从传感器获取当前累计步数
2. **更新今日步数**：使用步数基数服务更新今日步数
3. **保存数据**：将更新后的步数保存到本地存储

## 日志输出

后台任务会输出详细的日志，方便调试和监控：

```
Background task started: fetch_daily_steps_base
Fetching daily steps base in background...
Background step count: 1500
Background - Days difference: 1, Latest base: 1000, Current: 1500
Background - Next day base calculation: 1000 + 500 = 1500
Created daily steps base in background: DailyStepsBase(...)
Background task completed: fetch_daily_steps_base
```

## 优势

### 1. 数据连续性
- 即使App没有打开，也能获取步数基数
- 确保跨天步数计算的准确性

### 2. 智能更新
- 根据时间间隔和步数变化智能决定是否更新
- 避免频繁更新，节省系统资源

### 3. 异常处理
- 处理设备重启等异常情况
- 确保步数数据的可靠性

### 4. 后台执行
- 使用WorkManager确保任务在后台可靠执行
- 支持系统重启后自动恢复

## 注意事项

### 1. 权限要求
- 需要运动健康权限
- Android 10+ 需要 `ACTIVITY_RECOGNITION` 权限

### 2. 系统限制
- WorkManager任务可能受到系统电池优化影响
- 某些设备可能限制后台任务执行

### 3. 调试建议
- 查看日志输出了解任务执行情况
- 使用手动触发功能测试任务

## 测试方法

### 1. 手动触发测试
```dart
// 在设置页面或其他地方添加测试按钮
ElevatedButton(
  onPressed: () async {
    final backgroundService = BackgroundStepsService();
    await backgroundService.triggerDailyStepsBaseTask();
  },
  child: Text('测试后台步数获取'),
)
```

### 2. 日志监控
- 查看控制台日志了解任务执行情况
- 检查步数数据是否正确更新

### 3. 跨天测试
- 在一天结束时记录步数
- 第二天检查基数计算是否正确

## 故障排除

### 1. 任务不执行
- 检查WorkManager是否正确初始化
- 查看系统电池优化设置
- 确认权限是否已授予

### 2. 数据不更新
- 检查传感器是否正常工作
- 查看日志了解具体错误信息
- 确认存储服务是否正常

### 3. 基数计算错误
- 检查历史步数数据
- 验证基数计算逻辑
- 查看日志了解计算过程
