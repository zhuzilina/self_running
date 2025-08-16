# 数据库架构说明

## 概述

本应用使用 SQLite3 数据库存储日记数据，使用文件系统存储图片和音频文件。这种架构提供了高效的数据管理和良好的性能。

## 架构组件

### 1. 数据库服务 (DatabaseService)

**文件位置**: `lib/services/database_service.dart`

**功能**:
- 管理 SQLite3 数据库连接
- 提供日记的 CRUD 操作
- 使用单例模式确保数据库连接的唯一性

**数据库表结构**:

**用户每日数据表（主表）**:
```sql
CREATE TABLE user_daily_data (
  id TEXT PRIMARY KEY,           -- 格式：20250815
  nickname TEXT NOT NULL,        -- 用户昵称
  slogan TEXT NOT NULL,          -- 用户标语
  avatar_path TEXT,              -- 头像文件路径
  background_path TEXT,          -- 背景图片路径
  steps INTEGER NOT NULL DEFAULT 0, -- 今日步数
  date TEXT NOT NULL,            -- 日期
  created_at TEXT NOT NULL,      -- 创建时间
  updated_at TEXT                -- 更新时间
)
```

**日记表（关联表）**:
```sql
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,           -- 日记ID
  user_daily_id TEXT NOT NULL,   -- 关联用户每日数据ID
  content TEXT NOT NULL,         -- 日记内容
  image_paths TEXT,              -- 图片路径列表
  audio_paths TEXT,              -- 音频路径列表
  audio_names TEXT,              -- 音频名称列表
  audio_durations TEXT,          -- 音频时长列表
  date TEXT NOT NULL,            -- 日期
  created_at TEXT NOT NULL,      -- 创建时间
  updated_at TEXT,               -- 更新时间
  FOREIGN KEY (user_daily_id) REFERENCES user_daily_data (id)
)
```

**主要方法**:
- `saveDiary(Diary diary)`: 保存日记
- `getDiary(String id)`: 获取指定日记
- `getAllDiaries()`: 获取所有日记（按日期倒序）
- `deleteDiary(String id)`: 删除日记

### 2. 文件存储服务 (FileStorageService)

**文件位置**: `lib/services/file_storage_service.dart`

**功能**:
- 管理图片和音频文件的存储
- 使用 SHA256 哈希作为文件名，避免重复
- 提供文件清理和统计功能

**存储结构**:
```
应用文档目录/
├── diary.db          # SQLite 数据库文件
├── images/           # 图片文件目录
│   ├── [hash1].jpg   # 日记图片
│   ├── [hash2].png   # 日记图片
│   ├── [hash3].jpg   # 用户头像
│   ├── [hash4].jpg   # 用户背景
│   └── ...
└── audio/            # 音频文件目录
    ├── [hash1].m4a   # 日记音频
    ├── [hash2].wav   # 日记音频
    └── ...
```

**主要方法**:
- `saveImage(Uint8List imageData, String originalName)`: 保存图片
- `saveAudio(String sourcePath, String originalName)`: 保存音频
- `deleteFile(String filePath)`: 删除文件
- `cleanupUnusedFiles(List<String> usedFilePaths)`: 清理未使用文件
- `getStorageStats()`: 获取存储统计信息

### 3. 用户每日数据服务 (UserDailyDataService)

**文件位置**: `lib/services/user_daily_data_service.dart`

**功能**:
- 管理用户每日数据（昵称、标语、头像、背景、步数）
- 处理头像和背景图片的文件存储
- 提供用户数据的CRUD操作

**主要方法**:
- `getTodayUserData()`: 获取今日用户数据
- `saveTodayUserData()`: 保存今日用户数据
- `updateUserData()`: 更新用户数据
- `updateAvatar()`: 更新头像
- `updateBackground()`: 更新背景图片
- `updateSteps()`: 更新步数
- `getAllUserData()`: 获取所有用户数据
- `deleteUserData()`: 删除用户数据
- `getUserDataWithDiary()`: 获取用户数据和对应的日记

### 4. 日记服务 (DiaryService)

**文件位置**: `lib/services/diary_service.dart`

**功能**:
- 整合数据库和文件存储服务
- 提供高级的日记管理功能
- 处理文件关联和清理

**主要方法**:
- `getTodayDiary()`: 获取今日日记
- `saveTodayDiary()`: 保存今日日记
- `getAllDiaries()`: 获取所有日记
- `deleteDiary(String diaryId)`: 删除日记及相关文件
- `saveImageToStorage()`: 保存图片到文件系统
- `saveAudioToStorage()`: 保存音频到文件系统

## 数据流程

### 保存用户数据流程

1. **用户更新个人信息**
2. **保存头像文件**:
   - 调用 `updateAvatar()` 保存头像到文件系统
   - 使用哈希命名避免重复
3. **保存背景文件**:
   - 调用 `updateBackground()` 保存背景到文件系统
   - 使用哈希命名避免重复
4. **保存用户数据**:
   - 创建 `UserDailyData` 对象
   - 调用 `saveTodayUserData()` 保存到数据库
   - 数据库存储用户信息和文件路径

### 保存日记流程

1. **用户点击保存按钮**
2. **确保用户数据存在**:
   - 检查今日用户数据是否存在
   - 如果不存在，创建默认用户数据
3. **保存图片文件**:
   - 遍历 `_selectedImages` 列表
   - 调用 `saveImageToStorage()` 保存到文件系统
   - 获取文件路径列表
4. **保存音频文件**:
   - 遍历 `_audioPaths` 列表
   - 调用 `saveAudioToStorage()` 保存到文件系统
   - 获取文件路径列表
5. **保存日记数据**:
   - 创建 `Diary` 对象
   - 调用 `saveTodayDiary()` 保存到数据库
   - 数据库存储文件路径、音频名称、时长等信息
   - 通过 `user_daily_id` 关联到用户数据

### 加载用户数据流程

1. **页面初始化**
2. **从数据库加载用户数据**:
   - 调用 `getTodayUserData()` 获取今日用户数据
   - 设置用户昵称、标语、步数
3. **加载用户图片**:
   - 根据文件路径从文件系统加载头像和背景
   - 如果路径为空，使用默认图片

### 加载日记流程

1. **页面初始化**
2. **确保用户数据存在**:
   - 检查今日用户数据是否存在
   - 如果不存在，从健康数据获取步数并创建用户数据
3. **从数据库加载日记数据**:
   - 调用 `getTodayDiary()` 获取今日日记
   - 设置文本内容
4. **加载音频信息**:
   - 设置音频路径、名称、时长
   - 初始化播放器列表
5. **加载图片文件**:
   - 根据文件路径从文件系统加载图片数据
   - 设置到 `_selectedImages` 列表

## 文件命名规则

### 哈希生成
- 使用 SHA256 算法对文件内容进行哈希
- 格式: `{hash}.{extension}`
- 示例: `a1b2c3d4e5f6...789.jpg`

### 优势
- **去重**: 相同内容的文件使用相同文件名
- **完整性**: 哈希值可以验证文件完整性
- **安全性**: 文件名不包含原始信息

## 依赖项

```yaml
dependencies:
  sqlite3: ^2.9.0      # SQLite3 数据库
  crypto: ^3.0.3       # 哈希算法
  path_provider: ^2.1.5 # 文件路径管理
```

## 测试

运行数据库测试:
```bash
flutter test test/database_test.dart
```

## 注意事项

1. **文件清理**: 删除日记时会同时删除相关的图片和音频文件
2. **错误处理**: 所有文件操作都包含错误处理机制
3. **性能优化**: 使用单例模式避免重复创建数据库连接
4. **数据一致性**: 数据库和文件系统保持同步

## 未来改进

1. **数据迁移**: 从 Hive 迁移到 SQLite3
2. **备份功能**: 支持数据备份和恢复
3. **压缩存储**: 对图片和音频进行压缩
4. **云同步**: 支持云端数据同步
