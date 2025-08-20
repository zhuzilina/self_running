# 传感器步数获取修复总结

## 问题描述

用户反馈：打开App时能够获取一次步数，但是再次打开App时无论走了多少步都没有更新。同时Health Connect权限不足，需要改用传感器方式获取步数。

## 解决方案

### 1. 移除Health Connect依赖

**原因：** Health Connect权限不足，出现以下错误：
```
java.lang.SecurityException: Caller doesn't have android.permission.health.READ_STEPS
```

**修改内容：**
- 移除 `health` 插件的依赖
- 将 `RealtimeStepsService` 改为使用传感器获取步数
- 统一使用 `MethodChannel` 调用Android原生传感器

### 2. 实现新的步数计算逻辑

根据用户要求，实现以下计算方式：

#### 步数基数计算规则：
1. **App首次初始化**：以第一次获取的传感器步数为基数来计算增量
2. **第二天的基数**：前一天基数 + 前一天的步数值
3. **异常处理**：如果当前传感器的值小于了基数值，则将当前传感器值设置为基数值

#### 具体实现：

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

### 3. 修改的服务文件

#### `lib/services/realtime_steps_service.dart`
- 移除 `health` 插件依赖
- 改为使用 `MethodChannel` 调用传感器
- 使用 `DailyStepsBaseService` 进行步数计算
- 添加步数保存功能

#### `lib/services/daily_steps_base_service.dart`
- 修改 `_calculateBaseStepCount` 方法
- 实现新的步数基数计算逻辑
- 添加详细的日志输出

#### `lib/services/data_initialization_service.dart`
- 移除Health Connect相关初始化
- 统一使用传感器步数服务

#### `lib/presentation/states/providers.dart`
- 修改 `_refreshStepsData` 方法
- 移除Health Connect相关刷新逻辑

#### `lib/presentation/pages/settings_page.dart`
- 修改步数测试功能
- 移除Health Connect相关测试
- 改为测试传感器步数和实时步数

#### `lib/presentation/pages/home_page.dart`
- 修改刷新逻辑
- 统一使用传感器步数服务

## 步数计算示例

### 场景1：App首次启动
```
当前传感器值：1000步
基数：1000步
今日步数：0步（1000 - 1000）
```

### 场景2：同一天内再次获取
```
当前传感器值：1500步
基数：1000步（保持不变）
今日步数：500步（1500 - 1000）
```

### 场景3：第二天启动
```
前一天基数：1000步
前一天步数：500步
新基数：1500步（1000 + 500）
当前传感器值：1600步
今日步数：100步（1600 - 1500）
```

### 场景4：设备重启后
```
前一天基数：1000步
前一天步数：500步
新基数：1500步（1000 + 500）
当前传感器值：1200步（设备重启后重置）
今日步数：0步（1200 - 1200，基数调整为1200）
```

## 优势

### 1. 不依赖Health Connect
- 避免权限问题
- 减少依赖复杂度
- 提高兼容性

### 2. 智能基数计算
- 正确处理跨天步数计算
- 处理设备重启等异常情况
- 确保步数数据的连续性

### 3. 实时更新
- 每30秒自动更新一次
- 支持手动刷新
- 下拉刷新页面时自动更新

### 4. 数据持久化
- 步数数据保存到本地存储
- 基数信息持久化
- 支持历史数据查询

## 测试建议

### 1. 基本功能测试
- 打开App，检查是否能获取步数
- 走几步路，再次打开App，检查步数是否更新
- 使用下拉刷新功能，检查步数是否更新

### 2. 跨天测试
- 在一天结束时记录步数
- 第二天打开App，检查基数计算是否正确
- 验证今日步数是否从0开始计算

### 3. 设备重启测试
- 记录当前步数
- 重启设备
- 打开App，检查步数计算是否正确

### 4. 步数测试功能
- 进入设置页面，使用步数测试功能
- 测试传感器步数和实时步数
- 使用刷新所有步数数据功能

## 注意事项

### 1. 权限要求
- 确保应用有运动健康权限
- Android 10+ 需要 `ACTIVITY_RECOGNITION` 权限

### 2. 设备兼容性
- 传感器步数功能仅支持Android设备
- 需要设备支持步数传感器

### 3. 性能考虑
- 步数服务每30秒更新一次
- 避免频繁调用传感器
- 错误处理确保不会影响应用稳定性

## 日志输出

修复后的代码会输出详细的日志，方便调试：

```
Initializing realtime steps service (sensor only)...
Current sensor step count: 1500
Next day base calculation: 1000 + 500 = 1500
Calculated today steps with base: 100 (actual: 1600)
Updated today steps: 100
Today steps saved to storage: 100
```

## 后续优化建议

### 1. 智能更新频率
- 根据用户活动模式调整更新频率
- 静止时降低更新频率，活动时提高更新频率

### 2. 数据同步
- 添加云端同步功能
- 支持多设备数据同步

### 3. 用户体验
- 添加步数变化动画效果
- 提供更详细的步数统计信息
- 添加步数目标设置功能
