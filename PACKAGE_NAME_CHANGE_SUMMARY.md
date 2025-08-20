# 包名修改总结

## 概述
将App的包名从 `com.example.self_running` 修改为 `com.selfrunning`

## 修改的文件

### Android 相关文件

1. **android/app/build.gradle.kts**
   - 修改 `namespace` 从 `com.example.self_running` 到 `com.selfrunning`
   - 修改 `applicationId` 从 `com.example.self_running` 到 `com.selfrunning`

2. **android/app/src/main/kotlin/com/selfrunning/MainActivity.kt** (新建)
   - 包名声明：`package com.selfrunning`
   - 通道名称更新：
     - `com.selfrunning/sensor`
     - `com.selfrunning/health_connect`

3. **删除旧文件**
   - 删除 `android/app/src/main/kotlin/com/example/self_running/MainActivity.kt`
   - 删除目录 `android/app/src/main/kotlin/com/example/self_running`

### Flutter Dart 文件

4. **lib/platform/sensor_channel.dart**
   - 通道名称从 `com.example.self_running/sensor` 改为 `com.selfrunning/sensor`

5. **lib/services/background_steps_service.dart**
   - 两处通道名称从 `com.example.self_running/sensor` 改为 `com.selfrunning/sensor`

6. **lib/services/health_connect_service.dart**
   - 通道名称从 `com.example.self_running/health_connect` 改为 `com.selfrunning/health_connect`

7. **lib/services/sensor_steps_service.dart**
   - 通道名称从 `com.example.self_running/sensor` 改为 `com.selfrunning/sensor`

8. **lib/services/realtime_steps_service.dart**
   - 通道名称从 `com.example.self_running/sensor` 改为 `com.selfrunning/sensor`

### iOS 相关文件

9. **ios/Runner.xcodeproj/project.pbxproj**
   - 主应用 Bundle Identifier 从 `com.example.selfRunning` 改为 `com.selfrunning`
   - 测试应用 Bundle Identifier 从 `com.example.selfRunning.RunnerTests` 改为 `com.selfrunning.RunnerTests`

### macOS 相关文件

10. **macos/Runner.xcodeproj/project.pbxproj**
    - 测试应用 Bundle Identifier 从 `com.example.selfRunning.RunnerTests` 改为 `com.selfrunning.RunnerTests`

11. **macos/Runner/Configs/AppInfo.xcconfig**
    - Bundle Identifier 从 `com.example.selfRunning` 改为 `com.selfrunning`

### Linux 相关文件

12. **linux/CMakeLists.txt**
    - APPLICATION_ID 从 `com.example.self_running` 改为 `com.selfrunning`

## 验证结果

- ✅ Android 构建成功 (`flutter build apk --debug`)
- ✅ 所有通道名称已更新
- ✅ 包名结构已正确创建
- ✅ 旧文件已清理

## 注意事项

1. 如果之前安装过旧包名的应用，需要先卸载再安装新包名的应用
2. 所有平台特定的配置都已更新
3. 通道名称已同步更新，确保原生代码和Flutter代码的通信正常

## 新的包名结构

- **Android**: `com.selfrunning`
- **iOS**: `com.selfrunning`
- **macOS**: `com.selfrunning`
- **Linux**: `com.selfrunning`
