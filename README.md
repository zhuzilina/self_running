# Self Running —— 和过去的自己赛跑（Flutter）

一个专注“只和过去的自己比”的步数 App。连接手机健康平台（Apple Health / Google Fit），按“日”聚合你的步数数据，计算“今天超过了过去多少天”，并用折线图与日历热力图直观展示趋势与坚持。

---

## 功能特性

- 今日步数总览与“超过过去 X 天/约 Y%”提示
- 自我排行：按步数对历史天数降序排序，突出“今天”；支持 7/30/90/365 天筛选
- 统计可视化：最近 30 天折线图；全年热力图
- 本地持久化：使用 Hive 将按日聚合后的数据保存在本地
- 轻权限：仅申请读取步数所需的最小权限
- Android-only 兜底：在 Health 数据不可用时，使用系统传感器（TYPE_STEP_COUNTER）计算“今日步数”（需 ACTIVITY_RECOGNITION 权限）

---

## 演示预览（占位）

- 主页：今日步数与相对名次
- 排行页：近 7/30/90/365 天排序
- 统计页：折线图 + 热力图

可在真机运行查看实际效果。

---

## 快速开始

1) 环境准备

- Flutter SDK（稳定版）
- Dart >= 3.8.1（见 `pubspec.yaml` 中 `environment.sdk`）
- Android Studio / Xcode（用于构建与真机调试）
- 建议使用真机（健康数据在模拟器上通常不可用）

2) 克隆与依赖

```bash
flutter pub get
```

3) 运行

```bash
flutter run
```

---

## 平台配置

### iOS（Apple HealthKit）

- 在 Xcode 中为 `Runner` 开启 HealthKit Capability
- 在 `ios/Runner/Info.plist` 中添加用途描述键：
  - `NSHealthShareUsageDescription`：说明读取步数的目的
  - `NSMotionUsageDescription`：说明与运动与健身相关能力使用的目的
- 首次运行会弹出授权对话框，请允许“读取步数”

### Android（Google Fit / 传感器）

- Android 10+ 设备需声明并请求“身体活动识别”权限：`android.permission.ACTIVITY_RECOGNITION`
- 如使用 Google Fit 数据源，需完成对应 OAuth 配置（具体以 `health` 插件文档为准）
- 首次运行会弹出授权对话框，请允许“读取步数”
- 已内置传感器兜底：设备支持 `TYPE_STEP_COUNTER` 时，可在未安装 Google Fit/Health Connect 的情况下计算“今日步数”（仅限当日，且重启后会重置基线）

注意：桌面与 Web 平台通常无法访问健康数据，应用会正常启动但数据列表为空。

---

## 架构概览

分层设计，清晰可维护：

- data：平台数据源与模型（`health` 插件 → `HealthRepository` → `DailySteps`）
- domain：用例（`FetchDailyStepsUseCase`、`computeRanking`）
- presentation：页面与状态（Riverpod Providers，`HomePage` / `RankingPage` / `StatsPage`）
- services：本地存储（`StorageService` 基于 Hive）

目录（节选）：

```text
lib/
  data/
    models/
      daily_steps.dart
    repositories/
      health_repository.dart
  domain/
    usecases/
      compute_ranking_usecase.dart
      fetch_daily_steps_usecase.dart
  presentation/
    pages/
      home_page.dart
      ranking_page.dart
      stats_page.dart
    states/
      providers.dart
  services/
    storage_service.dart
  app.dart
  main.dart
```

---

## 核心数据模型

```dart
class DailySteps {
  final DateTime localDay;
  final int steps;
  final int? goal;
  final int tzOffsetMinutes;

  const DailySteps({
    required this.localDay,
    required this.steps,
    required this.tzOffsetMinutes,
    this.goal,
  });
}
```

原则：以“本地自然日”为最小聚合单位；持久化时记录 `tzOffsetMinutes`，便于时区切换与旅行场景回放。

---

## 关键用例与状态

- `FetchDailyStepsUseCase`：
  - 拉取健康平台步数 → 按“日”聚合 → 与本地缓存合并 → 对缺失日期补 0 → 按日排序 → 落盘 Hive
- `computeRanking`：
  - 将“今天”插入历史步数列表，按步数降序计算名次/百分位与“超过了多少天”
- Riverpod Providers：
  - `dailyStepsProvider`：触发同步并提供按日数据
  - `todayRankingProvider`：基于 `dailyStepsProvider` 计算今天的名次、百分位与超过天数

---

## 主要依赖

- `health`（健康数据接入）
- `flutter_riverpod`（状态管理）
- `fl_chart`（折线图）
- `flutter_heatmap_calendar`（日历热力图）
- `hive` / `hive_flutter`（本地持久化）
- `intl`（日期格式化）

具体版本见 `pubspec.yaml`。

---

## 开发与调试提示

- 真机优先：健康数据在模拟器上通常不可用
- 首次进入 App 或下拉刷新会触发同步；Android 可按需扩展后台/定时同步
- 若授权被拒绝，界面会提示“暂无数据”或“同步失败”，可在系统设置中重新授权
- 可通过 `StorageService.clearAll()` 清空本地缓存进行验证

---

## 已知限制与后续计划

- 桌面与 Web 平台暂不支持健康数据（会显示空数据）
- 未实现数据导出与小组件
- 计划：CSV 导出、Android 后台 `workmanager`、个性化目标与成就系统

---

## 许可证

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.


