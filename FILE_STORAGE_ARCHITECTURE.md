# 文件存储架构优化

## 概述

本次优化主要改进了日记应用中音频和图片文件的存储方式，实现了更好的文件组织结构和数据管理。

## 主要改进

### 1. 文件系统组织结构

**新的目录结构：**
```
应用文档目录/
└── data/
    └── 20250816/          # 主表ID（日期格式：YYYYMMDD）
        ├── images/        # 图片文件目录
        │   ├── hash1.jpg
        │   ├── hash2.jpg
        │   └── ...
        └── audio/         # 音频文件目录
            ├── hash1.m4a
            ├── hash2.m4a
            └── ...
```

**优势：**
- 按日期组织文件，便于管理和清理
- 使用主表ID作为目录名，确保唯一性
- 图片和音频分离存储，结构清晰

### 2. 文件名管理

**图片文件：**
- 使用MD5哈希值作为文件名（32字符）
- 格式：`{md5_hash}.{extension}`
- 确保文件唯一性，避免重复
- 相比SHA256更短，提高可读性

**音频文件：**
- 使用MD5哈希值作为文件名（32字符）
- 格式：`{md5_hash}.{extension}`
- 确保文件唯一性，避免重复
- 相比SHA256更短，提高可读性

**Hash算法选择：**
- 使用MD5算法替代SHA256
- MD5生成32字符的hash值（SHA256为64字符）
- 对于文件去重场景，MD5的碰撞概率足够低
- 提高文件名的可读性和管理便利性

### 3. 音频文件显示名称

**显示名称限制：**
- 最大长度：6个字符
- 在UI中显示用户友好的名称
- 数据库中保存显示名称和文件路径的映射

**数据模型：**
```dart
class AudioFile {
  final String id;           // 文件名hash
  final String displayName;  // 显示名称（≤6字符）
  final String filePath;     // 文件路径
  final int duration;        // 时长（毫秒）
  final DateTime recordTime; // 录音时间
}
```

## 技术实现

### 1. 文件存储服务 (`FileStorageService`)

**核心方法：**
- `getImagesDirectory(dateId)`: 获取指定日期的图片目录
- `getAudioDirectory(dateId)`: 获取指定日期的音频目录
- `saveImageDirectly()`: 直接保存图片到指定目录
- `saveAudioDirectly()`: 直接保存音频到指定目录
- `cleanupUnusedFiles()`: 清理未使用的文件

**Hash生成方法：**
```dart
/// 生成文件的MD5 hash编码（32字符）
String _generateHash(Uint8List data, String extension) {
  final hash = md5.convert(data);
  return '${hash.toString()}.$extension';
}
```

### 2. 日记服务 (`DiaryService`)

**保存流程：**
1. 生成日期ID（YYYYMMDD格式）
2. 保存图片到 `/data/{dateId}/images/` 目录
3. 保存音频到 `/data/{dateId}/audio/` 目录
4. 创建AudioFile对象，包含显示名称和文件路径
5. 保存日记记录到数据库
6. 清理未使用的文件

### 3. 数据模型优化

**AudioFile模型：**
- 添加显示名称长度验证
- 自动截断超长显示名称
- 确保数据一致性

## 使用示例

### 保存日记
```dart
// 创建音频文件对象
final audioFile = AudioFile.create(
  displayName: '录音1',  // 自动限制为6字符
  filePath: '/path/to/audio.m4a',
  duration: 30000,  // 30秒
  recordTime: DateTime.now(),
);

// 保存日记
await diaryService.saveTodayDiary(
  content: '今天的日记内容',
  imageDataList: [imageBytes1, imageBytes2],
  audioFiles: [audioFile],
);
```

### 文件清理
```dart
// 自动清理未使用的文件
await fileStorageService.cleanupUnusedFiles(
  '20250816',  // 日期ID
  usedFilePaths,  // 正在使用的文件路径列表
);
```

## 兼容性

- 保留了旧的文件存储方法以保持向后兼容
- 新功能通过新的方法名提供
- 数据库结构保持不变，只优化了文件组织

## 性能优化

- 使用MD5 hash文件名避免重复文件（比SHA256更短）
- 按日期组织减少目录遍历开销
- 自动清理未使用文件节省存储空间
- 批量文件操作提高效率

## 安全性

- 文件名使用MD5 hash值，避免路径遍历攻击
- 文件存储在应用私有目录
- 自动验证文件完整性
- MD5对于文件去重场景足够安全
