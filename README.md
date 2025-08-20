# 与自己赛跑 - 尝试记录每一天

## 一、应用简介

本应用致力于帮助用户记录每天的美好瞬间，包括文字、图像、声音等内容。通过记录用户的日常趣事和步数数据，本应用可以：

- **整理并生成可阅读、可搜索的记忆卡片**，帮助用户回顾和保存重要回忆；
- **通过步数排行榜**，帮助用户与过去的自己"相遇"，体验时光的流动与变化。

## 二、主要功能

### 主页
- 展示用户个人信息和今日步数统计
- 提供下拉刷新功能，实时更新步数数据
- 支持动态封面图片缩放效果
- 显示今日日记编辑卡片，支持快速记录
- 集成运动健康权限管理

### 日记编辑页
- 支持文字、图片、音频等多种内容记录
- 提供点击和长按两种录音模式
- 支持图片多选上传（最多9张）
- 音频文件管理，包括播放、重命名、删除
- 增量保存机制，提升保存效率
- 智能检测未保存修改，提供保存确认

### 排行榜页
- 展示用户历史步数排行榜
- 按步数高低排序显示
- 显示用户头像、昵称、签名等信息
- 支持今日数据与历史数据对比
- 提供数据可视化展示

### 足迹页
- 按时间分组展示所有日记记录
- 支持关键词搜索功能
- 置顶日记特殊展示
- 懒加载图片优化性能
- 音频播放器集成
- 支持日记详情查看

### 日记详情页
- 完整展示单篇日记内容
- 支持图片轮播查看
- 音频文件播放控制
- 日记置顶/取消置顶功能
- 垂直滑动切换相邻日记
- 图片全屏预览功能

## 三、项目结构

```
self_running/
├── android/                 # Android平台配置
├── ios/                    # iOS平台配置
├── lib/
│   ├── data/              # 数据层
│   │   ├── models/        # 数据模型
│   │   └── repositories/  # 数据仓库
│   ├── domain/            # 领域层
│   │   └── usecases/      # 用例
│   ├── presentation/      # 表现层
│   │   ├── pages/         # 页面组件
│   │   ├── states/        # 状态管理
│   │   └── widgets/       # 通用组件
│   ├── services/          # 服务层
│   └── platform/          # 平台特定代码
├── assets/                # 静态资源
├── test/                  # 测试文件
└── web/                   # Web平台配置
```

## 四、技术栈

### 前端框架
- **Flutter** - 跨平台UI框架
- **Dart** - 编程语言

### 状态管理
- **Riverpod** - 状态管理解决方案

### 数据存储
- **SQLite** - 本地数据库
- **SharedPreferences** - 轻量级数据存储

### 多媒体处理
- **image_picker** - 图片选择
- **record** - 音频录制
- **audioplayers** - 音频播放
- **photo_view** - 图片预览

### 健康数据
- **health** - 健康数据访问
- **sensors_plus** - 传感器数据

### 其他依赖
- **intl** - 国际化
- **path_provider** - 路径管理
- **percent_indicator** - 进度指示器
- **flutter_sticky_header** - 粘性头部

## 五、平台支持

- ✅ **Android** - 支持Android 5.0及以上版本
- ✅ **iOS** - 支持iOS 11.0及以上版本
- ✅ **Web** - 支持现代浏览器
- ✅ **Windows** - 支持Windows 10及以上版本
- ✅ **macOS** - 支持macOS 10.14及以上版本
- ✅ **Linux** - 支持主流Linux发行版

## 六、部署说明

### 环境要求
- Flutter SDK 3.0.0 或更高版本
- Dart SDK 2.17.0 或更高版本
- Android Studio / VS Code
- Xcode (仅iOS开发需要)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/zhuzilina/self_running.git
   cd self_running
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行项目**
   ```bash
   # 调试模式
   flutter run
   
   # 发布模式
   flutter run --release
   ```

4. **构建应用**
   ```bash
   # Android APK
   flutter build apk
   
   # iOS
   flutter build ios
   
   # Web
   flutter build web
   ```

### 配置说明

- **Android**: 确保在 `android/app/build.gradle` 中配置正确的包名和版本信息
- **iOS**: 在 `ios/Runner/Info.plist` 中配置必要的权限描述
- **健康权限**: 应用需要运动健康权限来获取步数数据

## 七、开源协议

本项目采用 **Apache License 2.0** 开源协议。

### 协议要点

- **使用自由**: 您可以自由使用、修改和分发本软件
- **商业友好**: 允许商业使用，无需支付费用
- **专利授权**: 包含专利授权条款
- **免责声明**: 软件按"原样"提供，不提供任何保证

### 协议要求

使用本软件时，您需要：

1. 保留原始版权声明
2. 在修改的文件中说明您所做的更改
3. 包含Apache License 2.0的完整副本
4. 如果有NOTICE文件，需要保留其内容

完整的协议文本请查看 [LICENSE](LICENSE) 文件。

---

**Copyright 2025 榆见晴天**

如有问题或建议，欢迎提交Issue或Pull Request。


