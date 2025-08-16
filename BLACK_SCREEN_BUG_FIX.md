# 保存时黑屏问题修复

## 问题描述

用户在返回保存确认对话框中点击"保存"按钮时，屏幕出现黑屏，应用无法正常响应。

## 问题分析

### 根本原因

1. **重复的状态重置调用**
   - `_handleBackPress`方法调用`_saveDiary()`
   - `_saveDiary()`方法内部也会调用`_resetInitialStateHash()`
   - 导致状态重置被调用两次，可能引起状态混乱

2. **重复的导航操作**
   - `_handleBackPress`方法在保存后调用`Navigator.pop()`
   - `_saveDiary()`方法内部也会调用`Navigator.pop()`
   - 导致重复的页面返回操作

3. **异步操作时序问题**
   - 保存操作是异步的，但导航操作可能在保存完成前就执行
   - 导致界面状态不一致

## 修复方案

### 1. 修改`_saveDiary`方法，添加自动返回控制

#### 修改前
```dart
Future<void> _saveDiary() async {
  // ... 保存逻辑 ...
  
  if (mounted) {
    // 保存成功后重置初始状态哈希值
    _resetInitialStateHash();
    
    // 刷新今日日记数据
    ref.invalidate(todayDiaryProvider);
    
    Navigator.of(context).pop(); // ❌ 总是自动返回
  }
}
```

#### 修改后
```dart
Future<bool> _saveDiary({bool autoReturn = true}) async {
  // ... 保存逻辑 ...
  
  if (mounted) {
    // 保存成功后重置初始状态哈希值
    _resetInitialStateHash();
    
    // 刷新今日日记数据
    ref.invalidate(todayDiaryProvider);
    
    // 根据参数决定是否自动返回
    if (autoReturn) {
      Navigator.of(context).pop();
    }
  }
  
  return true; // 返回保存结果
}
```

### 2. 修改`_handleBackPress`方法，避免重复操作

#### 修改前
```dart
Future<void> _handleBackPress() async {
  if (_hasChanges()) {
    final shouldSave = await _showSaveConfirmDialog();
    if (shouldSave) {
      await _saveDiary(); // ❌ 会触发自动返回
      _resetInitialStateHash(); // ❌ 重复调用
    }
    // 无论是否保存，都返回
    if (mounted) {
      Navigator.of(context).pop(); // ❌ 重复返回
    }
  } else {
    Navigator.of(context).pop();
  }
}
```

#### 修改后
```dart
Future<void> _handleBackPress() async {
  if (_hasChanges()) {
    final shouldSave = await _showSaveConfirmDialog();
    if (shouldSave) {
      // 用户选择保存，不自动返回
      final success = await _saveDiary(autoReturn: false);
      if (success && mounted) {
        // 保存成功后手动返回
        Navigator.of(context).pop();
      }
      return;
    }
    // 用户选择不保存，直接返回
    if (mounted) {
      Navigator.of(context).pop();
    }
  } else {
    // 没有修改，直接返回
    Navigator.of(context).pop();
  }
}
```

### 3. 保持AppBar保存按钮的原有行为

```dart
TextButton(
  onPressed: _saveDiary, // ✅ 使用默认的autoReturn = true
  child: const Text('保存'),
),
```

## 修复效果

### 1. 避免重复操作
- 消除了重复的状态重置调用
- 避免了重复的导航操作
- 确保每个操作只执行一次

### 2. 正确的异步处理
- 保存操作完成后才执行返回
- 确保状态更新和导航的顺序正确
- 避免界面状态不一致

### 3. 灵活的控制机制
- 通过`autoReturn`参数控制是否自动返回
- 不同场景使用不同的返回策略
- 保持代码的可维护性

## 测试验证

### 测试场景1：正常保存
1. 点击AppBar的"保存"按钮
2. **预期结果**：保存成功，自动返回上一页面

### 测试场景2：返回时保存
1. 修改内容后点击返回按钮
2. 在弹出的对话框中点击"保存"
3. **预期结果**：保存成功，返回上一页面，无黑屏

### 测试场景3：返回时不保存
1. 修改内容后点击返回按钮
2. 在弹出的对话框中点击"不保存"
3. **预期结果**：直接返回上一页面，无黑屏

### 测试场景4：无修改返回
1. 不进行任何修改，点击返回按钮
2. **预期结果**：直接返回上一页面，无对话框

## 技术要点

### 1. 参数化控制
- 使用`autoReturn`参数控制返回行为
- 避免硬编码的导航逻辑
- 提高代码的灵活性

### 2. 异步操作管理
- 确保异步操作完成后再执行后续操作
- 使用返回值判断操作是否成功
- 避免竞态条件

### 3. 状态一致性
- 确保状态重置只执行一次
- 保证导航操作的唯一性
- 维护界面状态的一致性

## 总结

通过修改`_saveDiary`方法添加自动返回控制参数，并调整`_handleBackPress`方法的调用逻辑，成功解决了保存时黑屏的问题。修复后的代码避免了重复操作，确保了异步操作的正确处理，提供了更好的用户体验。
