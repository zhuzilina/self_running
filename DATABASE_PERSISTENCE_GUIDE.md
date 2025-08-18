# 数据库持久化使用指南

## 概述

本指南介绍如何使用新的数据库预保存和智能保存功能，实现数据的即时保存和日期变化时的编辑状态管理。

## 核心功能

### 1. 预保存功能
- **立即保存**：用户设置数据后立即保存到数据库，不检查日期
- **不检查编辑权限**：直接保存，适用于数据录入阶段
- **支持批量操作**：可以同时保存用户数据和日记数据

### 2. 智能保存功能
- **权限检查**：保存前检查今日记录是否可编辑
- **日期验证**：确保不会修改已锁定的历史记录
- **异常处理**：如果记录已锁定，抛出异常提示用户

### 3. 日期状态管理
- **自动检测**：检测日期变化时自动更新编辑状态
- **状态同步**：用户信息表和日记表的编辑状态同步更新
- **历史保护**：昨天的记录自动标记为不可编辑

## 使用方法

### 在Widget中使用

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/states/providers.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 预保存用户数据
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(preSaveProvider({
                'nickname': '新昵称',
                'slogan': '新口号',
                'steps': 8000,
              }).future);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('数据已预保存')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('保存失败: $e')),
              );
            }
          },
          child: Text('预保存用户数据'),
        ),

        // 智能保存用户数据
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(smartSaveProvider({
                'nickname': '新昵称',
                'slogan': '新口号',
                'steps': 8000,
              }).future);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('数据已智能保存')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('保存失败: $e')),
              );
            }
          },
          child: Text('智能保存用户数据'),
        ),

        // 预保存日记
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(diaryPreSaveProvider({
                'content': '今天的日记内容',
                'imageDataList': <Uint8List>[],
                'audioFiles': <AudioFile>[],
              }).future);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('日记已预保存')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('保存失败: $e')),
              );
            }
          },
          child: Text('预保存日记'),
        ),

        // 批量预保存
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(preSaveProvider({
                'nickname': '新昵称',
                'slogan': '新口号',
                'steps': 8000,
                'diaryContent': '今天的日记内容',
                'imageDataList': <Uint8List>[],
                'audioFiles': <AudioFile>[],
              }).future);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('数据已批量预保存')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('保存失败: $e')),
              );
            }
          },
          child: Text('批量预保存'),
        ),
      ],
    );
  }
}
```

### 检查编辑状态

```dart
// 检查今日是否可编辑
final isEditable = await ref.read(todayEditableProvider.future);

if (isEditable) {
  // 可以编辑，执行保存操作
  await ref.read(smartSaveProvider(data).future);
} else {
  // 不可编辑，显示提示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('今日记录已锁定，无法修改')),
  );
}
```

### 获取今日数据

```dart
// 获取今日用户数据
final userData = await ref.read(todayUserDataProvider.future);

// 获取今日日记
final diary = await ref.read(todayDiaryDataProvider.future);

if (userData != null) {
  print('今日步数: ${userData.steps}');
  print('昵称: ${userData.nickname}');
  print('是否可编辑: ${userData.isEditable}');
}
```

### 手动更新日期状态

```dart
// 手动触发日期状态更新（通常在应用启动时调用）
await ref.read(dateStatusUpdateProvider.future);
```

## 服务层使用

### 直接使用DataPersistenceService

```dart
import '../services/data_persistence_service.dart';

class MyService {
  final DataPersistenceService _persistenceService = DataPersistenceService();

  Future<void> saveUserData() async {
    await _persistenceService.init();
    
    // 预保存
    await _persistenceService.preSaveUserData(
      nickname: '新昵称',
      slogan: '新口号',
      steps: 8000,
    );

    // 智能保存
    await _persistenceService.smartSaveUserData(
      nickname: '新昵称',
      slogan: '新口号',
      steps: 8000,
    );
  }

  Future<void> saveDiaryData() async {
    await _persistenceService.init();
    
    await _persistenceService.preSaveDiaryData(
      content: '日记内容',
      imageDataList: <Uint8List>[],
      audioFiles: <AudioFile>[],
    );
  }

  Future<void> batchSave() async {
    await _persistenceService.init();
    
    await _persistenceService.preSaveBatch(
      nickname: '新昵称',
      slogan: '新口号',
      steps: 8000,
      diaryContent: '日记内容',
    );
  }
}
```

## 数据库结构

### user_daily_data表
```sql
CREATE TABLE user_daily_data (
  id TEXT PRIMARY KEY,                    -- 日期ID (YYYYMMDD)
  nickname TEXT,                          -- 用户昵称
  slogan TEXT,                            -- 用户口号
  avatar_path TEXT,                       -- 头像路径
  background_path TEXT,                   -- 背景图片路径
  steps INTEGER DEFAULT 0,                -- 步数
  date TEXT,                              -- 日期
  is_editable INTEGER DEFAULT 1,          -- 是否可编辑 (1=可编辑, 0=不可编辑)
  created_at TEXT,                        -- 创建时间
  updated_at TEXT                         -- 更新时间
);
```

### diaries表
```sql
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,                    -- 日期ID (YYYYMMDD)
  content TEXT,                           -- 日记内容
  image_paths TEXT,                       -- 图片路径列表
  audio_files TEXT,                       -- 音频文件JSON数组
  date TEXT,                              -- 日期
  is_editable INTEGER DEFAULT 1,          -- 是否可编辑 (1=可编辑, 0=不可编辑)
  created_at TEXT,                        -- 创建时间
  updated_at TEXT                         -- 更新时间
);
```

## 最佳实践

### 1. 数据录入阶段
- 使用预保存功能，让用户可以随时保存数据
- 不检查编辑权限，提供流畅的用户体验

### 2. 数据确认阶段
- 使用智能保存功能，确保数据完整性
- 检查编辑权限，防止误操作

### 3. 应用启动时
- 调用日期状态更新，确保编辑状态正确
- 初始化今日数据，确保记录存在

### 4. 错误处理
- 捕获保存异常，向用户显示友好提示
- 区分预保存和智能保存的错误类型

### 5. 性能优化
- 批量保存减少数据库操作次数
- 使用Provider缓存减少重复查询

## 注意事项

1. **日期格式**：所有日期ID使用YYYYMMDD格式
2. **编辑状态**：is_editable字段控制记录是否可修改
3. **文件管理**：图片和音频文件会自动管理，无需手动清理
4. **并发安全**：服务使用单例模式，确保线程安全
5. **数据一致性**：用户数据和日记数据的编辑状态保持同步

## 迁移指南

### 从旧版本升级
1. 数据库版本自动升级到v4
2. 自动添加is_editable字段到user_daily_data表
3. 现有记录的is_editable默认为1（可编辑）

### 代码迁移
1. 将原有的保存调用替换为预保存或智能保存
2. 添加编辑状态检查逻辑
3. 使用新的Provider获取数据
