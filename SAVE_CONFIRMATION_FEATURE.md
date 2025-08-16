# 返回保存提示功能实现

## 功能概述

在今日记录页面添加了返回时提示是否保存的对话框功能。当用户点击返回按钮时，系统会检测是否有未保存的修改，如果有修改则弹出确认对话框询问用户是否要保存。

## 技术实现

### 1. MD5哈希值比较机制

使用MD5算法对页面状态进行哈希值比较，准确检测用户是否进行了修改：

```dart
/// 生成当前状态的MD5哈希值
String _generateStateHash() {
  // 创建包含所有状态信息的Map
  final stateData = {
    'content': _textController.text,
    'images': _selectedImages.map((img) => base64Encode(img)).toList(),
    'audioPaths': _audioPaths,
    'audioNames': _audioNames,
    'audioDurations': _audioDurations.map((d) => d.inMilliseconds).toList(),
    'audioRecordTimes': _audioRecordTimes.map((t) => t.toIso8601String()).toList(),
  };
  
  // 将Map转换为JSON字符串
  final jsonString = jsonEncode(stateData);
  
  // 生成MD5哈希值
  final bytes = utf8.encode(jsonString);
  final digest = md5.convert(bytes);
  
  return digest.toString();
}
```

### 2. 状态检测机制

#### 初始状态记录
- 在页面初始化完成后，生成初始状态的MD5哈希值
- 存储在`_initialStateHash`变量中

#### 修改检测
```dart
/// 检查是否有未保存的修改
bool _hasChanges() {
  if (_initialStateHash == null) return false;
  final currentHash = _generateStateHash();
  return _initialStateHash != currentHash;
}
```

### 3. 保存确认对话框

```dart
/// 显示保存确认对话框
Future<bool> _showSaveConfirmDialog() async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('保存提示'),
        content: const Text('您有未保存的修改，是否要保存？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 不保存
            },
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 保存
            },
            child: const Text('保存'),
          ),
        ],
      );
    },
  ) ?? false;
}
```

### 4. 返回处理逻辑

```dart
/// 处理返回按钮点击
Future<void> _handleBackPress() async {
  if (_hasChanges()) {
    final shouldSave = await _showSaveConfirmDialog();
    if (shouldSave) {
      // 用户选择保存
      await _saveDiary();
    }
    // 无论是否保存，都返回
    if (mounted) {
      Navigator.of(context).pop();
    }
  } else {
    // 没有修改，直接返回
    Navigator.of(context).pop();
  }
}
```

### 5. 返回按钮集成

#### AppBar返回按钮
```dart
leading: IconButton(
  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
  onPressed: _handleBackPress,
),
```

#### Android返回键处理
```dart
body: WillPopScope(
  onWillPop: () async {
    await _handleBackPress();
    return false; // 我们已经在_handleBackPress中处理了导航
  },
  child: Stack(
    // 页面内容
  ),
),
```

## 检测的状态内容

### 1. 文本内容
- 日记文本内容的变化

### 2. 图片内容
- 图片数据的base64编码
- 图片数量变化

### 3. 音频内容
- 音频文件路径
- 音频文件名称
- 音频时长
- 录音时间
- 音频数量变化

## 用户体验流程

### 1. 无修改情况
- 用户点击返回按钮
- 系统检测到无修改
- 直接返回上一页面

### 2. 有修改情况
- 用户点击返回按钮
- 系统检测到有修改
- 弹出保存确认对话框
- 用户选择"保存"或"不保存"
- 根据用户选择执行相应操作
- 返回上一页面

## 技术特点

### 1. 精确检测
- 使用MD5哈希值比较，确保检测的准确性
- 包含所有可能修改的状态信息

### 2. 性能优化
- 只在需要时生成哈希值
- 避免频繁的哈希计算

### 3. 用户体验
- 非阻塞式对话框
- 清晰的提示信息
- 简单的操作选择

### 4. 平台兼容
- 支持iOS和Android的返回操作
- 统一的处理逻辑

## 依赖包

```yaml
dependencies:
  crypto: ^3.0.3  # MD5哈希算法
```

## 导入声明

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
```

## 总结

这个功能成功实现了：

1. **精确的修改检测**: 通过MD5哈希值比较，准确识别用户是否进行了修改
2. **友好的用户提示**: 提供清晰的保存确认对话框
3. **完整的返回处理**: 支持AppBar返回按钮和Android返回键
4. **良好的用户体验**: 避免用户意外丢失未保存的内容

这个实现确保了用户在编辑日记时不会意外丢失修改的内容，提供了更好的用户体验。
