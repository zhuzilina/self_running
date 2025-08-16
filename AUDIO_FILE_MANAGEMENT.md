# 音频文件管理机制 - 两阶段提交 + 异步清理

## 概述

为了解决音频文件保存和删除时容易丢失文件的问题，我们实现了基于两阶段提交和异步清理的文件管理机制。这个方案确保了文件操作的原子性和数据一致性。

## 核心设计原则

### 1. 两阶段提交 (Two-Phase Commit)
- **第一阶段**: 写入临时文件到 `/pending/` 目录
- **第二阶段**: 验证成功后移动到正式目录并更新数据库状态

### 2. 异步清理 (Asynchronous Cleanup)
- **逻辑删除**: 在数据库中标记文件为删除状态
- **物理删除**: 异步任务执行实际的文件删除操作
- **定期GC**: 定时清理已删除的文件

## 文件状态管理

### AudioFileStatus 枚举
```dart
enum AudioFileStatus {
  pending,   // 临时状态，文件已写入但未确认
  active,    // 正常状态，文件可用
  deleted,   // 已删除状态，等待物理清理
}
```

### AudioFile 模型增强
```dart
class AudioFile {
  final String id;                    // 文件名hash
  final String displayName;           // 显示名称（≤6字符）
  final String filePath;              // 文件路径
  final int duration;                 // 时长（毫秒）
  final DateTime recordTime;          // 录音时间
  final AudioFileStatus status;       // 文件状态
  final DateTime? deletedAt;          // 删除时间
  final DateTime createdAt;           // 创建时间
  final DateTime updatedAt;           // 更新时间
}
```

## 目录结构

```
应用文档目录/
└── data/
    └── 20241201/              # 主表ID（日期格式：YYYYMMDD）
        ├── pending/           # 临时文件目录（两阶段提交）
        │   ├── hash1.m4a
        │   └── hash2.m4a
        ├── audio/             # 正式音频文件目录
        │   ├── hash1.m4a
        │   └── hash2.m4a
        └── images/            # 图片文件目录
            ├── hash1.jpg
            └── hash2.jpg
```

## 保存流程

### 1. 第一阶段：写入临时文件
```dart
Future<AudioFile?> _writeToPendingDirectory({
  required String sourcePath,
  required String displayName,
  required int duration,
  required DateTime recordTime,
  required String dateId,
}) async {
  // 1. 读取源文件数据
  final audioData = await sourceFile.readAsBytes();
  
  // 2. 生成MD5 hash
  final hash = _generateHash(audioData);
  final fileName = '$hash.m4a';
  
  // 3. 写入临时目录
  final pendingPath = join(pendingDir.path, fileName);
  await sourceFile.copy(pendingPath);
  
  // 4. 验证写入的文件
  final pendingFileSize = await pendingFile.length();
  if (pendingFileSize != audioData.length) {
    await pendingFile.delete();
    return null;
  }
  
  // 5. 创建pending状态的AudioFile对象
  return AudioFile.create(
    displayName: displayName,
    filePath: pendingPath,
    duration: duration,
    recordTime: recordTime,
  );
}
```

### 2. 第二阶段：移动到正式目录
```dart
Future<AudioFile?> _moveToFinalLocation(AudioFile pendingAudioFile, String dateId) async {
  // 1. 验证临时文件存在
  final pendingFile = File(pendingAudioFile.filePath);
  if (!await pendingFile.exists()) {
    return null;
  }
  
  // 2. 移动到正式目录
  final audioDir = await _getAudioDirectory(dateId);
  final fileName = basename(pendingAudioFile.filePath);
  final finalPath = join(audioDir.path, fileName);
  
  // 3. 如果目标文件已存在，先删除
  final finalFile = File(finalPath);
  if (await finalFile.exists()) {
    await finalFile.delete();
  }
  
  // 4. 移动文件
  await pendingFile.rename(finalPath);
  
  // 5. 验证移动后的文件
  if (!await finalFile.exists()) {
    return null;
  }
  
  // 6. 更新AudioFile对象
  return pendingAudioFile.copyWith(filePath: finalPath);
}
```

## 删除流程

### 1. 逻辑删除
```dart
Future<bool> markAudioFileAsDeleted(String audioFileId) async {
  try {
    // 在数据库中标记文件为删除状态
    // 设置 status = AudioFileStatus.deleted
    // 设置 deletedAt = DateTime.now()
    return true;
  } catch (e) {
    return false;
  }
}
```

### 2. 异步清理
```dart
Future<void> cleanupDeletedFiles() async {
  try {
    // 1. 获取所有标记为删除的音频文件
    final deletedFiles = await _getDeletedAudioFiles();
    
    // 2. 逐个物理删除文件
    for (final audioFile in deletedFiles) {
      await _physicallyDeleteFile(audioFile);
    }
  } catch (e) {
    print('清理已删除文件失败: $e');
  }
}
```

### 3. 定期GC
```dart
void _startCleanupTimer() {
  // 每30分钟执行一次清理
  _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
    cleanupDeletedFiles();
  });
}
```

## 错误处理和恢复

### 1. 保存失败处理
- **第一阶段失败**: 不创建数据库记录，清理临时文件
- **第二阶段失败**: 清理临时文件，回滚数据库操作
- **文件验证失败**: 删除损坏的文件，返回错误

### 2. 删除失败处理
- **逻辑删除失败**: 保持文件状态不变
- **物理删除失败**: 保留文件，下次清理时重试
- **数据库更新失败**: 记录错误日志，手动处理

### 3. 恢复机制
- **临时文件清理**: 定期清理孤立的临时文件
- **状态不一致**: 通过文件存在性验证修复状态
- **数据库修复**: 提供手动修复工具

## 性能优化

### 1. 并发处理
- 支持多个音频文件同时保存
- 异步清理不影响主业务流程
- 文件操作使用独立线程池

### 2. 存储优化
- 使用MD5 hash避免重复文件
- 按日期组织减少目录遍历
- 定期清理减少存储空间

### 3. 内存管理
- 流式处理大文件
- 及时释放文件句柄
- 避免内存泄漏

## 监控和统计

### 1. 文件统计
```dart
Future<Map<String, dynamic>> getFileStats() async {
  return {
    'totalFiles': totalFiles,
    'pendingFiles': pendingFiles,
    'activeFiles': activeFiles,
    'deletedFiles': deletedFiles,
    'totalSize': totalSize,
  };
}
```

### 2. 操作日志
- 记录所有文件操作
- 记录错误和异常
- 提供调试信息

### 3. 健康检查
- 定期验证文件完整性
- 检查目录结构
- 监控存储空间

## 使用示例

### 保存音频文件
```dart
final audioFile = await audioFileManager.saveAudioFile(
  sourcePath: '/path/to/source.m4a',
  displayName: '录音1',
  duration: 30000,
  recordTime: DateTime.now(),
  dateId: '20241201',
);

if (audioFile != null) {
  print('保存成功: ${audioFile.filePath}');
} else {
  print('保存失败');
}
```

### 删除音频文件
```dart
final success = await audioFileManager.markAudioFileAsDeleted('file_id');
if (success) {
  print('标记删除成功');
  // 触发异步清理
  audioFileManager.triggerCleanup();
}
```

### 手动清理
```dart
await audioFileManager.triggerCleanup();
```

## 优势

### 1. 数据一致性
- 确保数据库中存在的文件一定是写成功的文件
- 避免文件丢失和状态不一致

### 2. 操作原子性
- 两阶段提交保证操作的原子性
- 失败时自动回滚

### 3. 可靠性
- 异步清理避免阻塞主流程
- 定期GC确保存储空间

### 4. 可维护性
- 清晰的状态管理
- 完善的错误处理
- 详细的监控统计

## 总结

这个两阶段提交 + 异步清理的机制有效解决了音频文件管理中的可靠性问题，确保了文件操作的原子性和数据一致性，同时提供了良好的性能和可维护性。
