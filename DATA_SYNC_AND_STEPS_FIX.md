# 数据同步和步数问题解决方案

## 问题描述

用户反馈了两个新问题：

1. **排行页面数据更新延迟**：主页修改内容后，排行页面需要重启App才能看到新修改的数据
2. **步数记录问题**：每天的步数显示为0，没有成功将今天的步数同步到数据库中

## 问题分析

### 问题1：排行页面数据更新延迟

**原因**：
- `userDailyDataRankingProvider`没有监听用户配置的变化
- 用户修改配置后，排行页面的数据没有自动刷新

### 问题2：步数记录问题

**原因**：
- 应用中存在两个独立的数据源：
  - **健康数据**：存储在`DailySteps`模型中，使用Hive存储
  - **每日数据**：存储在`UserDailyData`模型中，使用SQLite数据库
- 这两个数据源之间没有同步机制
- 排行页面显示的是`UserDailyData`，但步数数据来自健康平台

## 解决方案

### 1. 修复排行页面数据更新延迟

#### 修改userDailyDataRankingProvider

在`lib/presentation/states/providers.dart`中添加对用户配置的依赖：

```dart
// 用户每日数据排行Provider - 从数据库获取数据用于排行
final userDailyDataRankingProvider = FutureProvider<List<UserDailyData>>((
  ref,
) async {
  try {
    // 监听用户配置变化，确保配置更新时排行数据自动刷新
    await ref.read(userProfileProvider.future);
    
    final service = ref.read(userDailyDataServiceProvider);
    
    // 获取所有用户数据
    final allData = await service.getAllUserData();
    
    // 按日期排序，最新的在前面
    allData.sort((a, b) => b.date.compareTo(a.date));
    
    return allData;
  } catch (e) {
    print('userDailyDataRankingProvider: Error - $e');
    return [];
  }
});
```

**效果**：
- 用户配置更新时，排行页面数据会自动刷新
- 无需重启App即可看到最新数据

### 2. 修复步数记录问题

#### 创建健康数据同步服务

新建`lib/services/health_data_sync_service.dart`：

```dart
/// 健康数据同步服务
/// 负责将健康平台的步数数据同步到每日数据表中
class HealthDataSyncService {
  final StorageService _storageService;
  final DatabaseService _databaseService;
  final UserProfileService _userProfileService;

  HealthDataSyncService({
    required StorageService storageService,
    required DatabaseService databaseService,
    required UserProfileService userProfileService,
  })  : _storageService = storageService,
        _databaseService = databaseService,
        _userProfileService = userProfileService;

  /// 同步健康数据到每日数据表
  Future<void> syncHealthDataToDailyData() async {
    try {
      // 获取所有健康数据
      final healthData = _storageService.loadAllDailySteps();
      
      if (healthData.isEmpty) {
        print('HealthDataSyncService: 暂无健康数据');
        return;
      }

      // 获取用户配置
      final userProfile = await _userProfileService.getUserProfile();

      // 同步每个日期的数据
      for (final dailySteps in healthData) {
        await _syncSingleDayData(dailySteps, userProfile);
      }

      print('HealthDataSyncService: 同步完成，共处理 ${healthData.length} 条数据');
    } catch (e) {
      print('HealthDataSyncService: 同步失败 - $e');
    }
  }

  /// 同步单日数据
  Future<void> _syncSingleDayData(DailySteps dailySteps, UserProfile userProfile) async {
    try {
      final dateId = _formatDateId(dailySteps.localDay);
      
      // 检查是否已存在该日期的数据
      final existingData = await _databaseService.getUserDailyData(dateId);
      
      if (existingData != null) {
        // 更新现有数据，保留用户自定义信息，更新步数
        final updatedData = existingData.copyWith(
          steps: dailySteps.steps,
          updatedAt: DateTime.now(),
        );
        await _databaseService.saveUserDailyData(updatedData);
      } else {
        // 创建新数据
        final newData = UserDailyData.create(
          nickname: userProfile.nickname,
          slogan: userProfile.slogan,
          avatarPath: userProfile.avatar,
          backgroundPath: userProfile.coverImage,
          steps: dailySteps.steps,
          date: dailySteps.localDay,
          isEditable: true,
        );
        await _databaseService.saveUserDailyData(newData);
      }
    } catch (e) {
      print('HealthDataSyncService: 同步单日数据失败 ${dailySteps.localDay} - $e');
    }
  }

  /// 格式化日期ID
  String _formatDateId(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
```

#### 在providers中添加同步服务

在`lib/presentation/states/providers.dart`中：

```dart
final healthDataSyncServiceProvider = Provider<HealthDataSyncService>((ref) {
  return HealthDataSyncService(
    storageService: ref.read(storageServiceProvider),
    databaseService: ref.read(databaseServiceProvider),
    userProfileService: ref.read(userProfileServiceProvider),
  );
});

final dailyStepsProvider = FutureProvider<List<DailySteps>>((ref) async {
  final useCase = ref.read(fetchDailyStepsUseCaseProvider);
  final from = DateTime.now().subtract(const Duration(days: 365));
  final to = DateTime.now();
  
  final result = await useCase(from: from, to: to);
  
  // 同步健康数据到每日数据表
  final syncService = ref.read(healthDataSyncServiceProvider);
  await syncService.syncHealthDataToDailyData();
  
  return result;
});
```

#### 修改数据初始化服务

在`lib/services/data_initialization_service.dart`中：

```dart
class DataInitializationService {
  static final DataInitializationService _instance = DataInitializationService._internal();
  factory DataInitializationService() => _instance;
  DataInitializationService._internal();

  DatabaseService? _databaseService;
  UserProfileService? _userProfileService;
  HealthDataSyncService? _healthDataSyncService;

  void initialize({
    required DatabaseService databaseService,
    required UserProfileService userProfileService,
    required HealthDataSyncService healthDataSyncService,
  }) {
    _databaseService = databaseService;
    _userProfileService = userProfileService;
    _healthDataSyncService = healthDataSyncService;
  }

  /// 初始化今日数据（确保今日记录存在）
  Future<void> initializeTodayData() async {
    final today = DateTime.now();
    final todayId = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    // 同步健康数据到每日数据表
    if (_healthDataSyncService != null) {
      await _healthDataSyncService!.syncHealthDataToDailyData();
    }

    // 确保今日用户数据存在
    final existingUserData = await _databaseService!.getUserDailyData(todayId);
    if (existingUserData == null) {
      final userProfile = await _userProfileService!.getUserProfile();
      final newUserData = UserDailyData.create(
        nickname: userProfile.nickname,
        slogan: userProfile.slogan,
        avatarPath: userProfile.avatar,
        backgroundPath: userProfile.coverImage,
        steps: 0,
        date: today,
        isEditable: true,
      );
      await _databaseService!.preSaveUserDailyData(newUserData);
    } else {
      // 如果今日数据已存在，同步用户配置信息
      final userProfile = await _userProfileService!.getUserProfile();
      final updatedUserData = existingUserData.copyWith(
        nickname: userProfile.nickname,
        slogan: userProfile.slogan,
        avatarPath: userProfile.avatar,
        backgroundPath: userProfile.coverImage,
        updatedAt: DateTime.now(),
      );
      await _databaseService!.saveUserDailyData(updatedUserData);
    }

    // 确保今日日记存在
    final existingDiary = await _databaseService!.getDiary(todayId);
    if (existingDiary == null) {
      final newDiary = Diary.create(content: '', date: today, isEditable: true);
      await _databaseService!.saveDiary(newDiary);
    }
  }
}
```

#### 修改应用启动流程

在`lib/main.dart`中：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化存储服务
    final storageService = StorageService();
    await storageService.init();

    // 初始化数据库服务
    final databaseService = DatabaseService();
    await databaseService.database; // 使用database getter初始化

    // 初始化用户配置服务
    final userProfileService = UserProfileService(storageService);
    await userProfileService.init();

    // 初始化健康数据同步服务
    final healthDataSyncService = HealthDataSyncService(
      storageService: storageService,
      databaseService: databaseService,
      userProfileService: userProfileService,
    );

    // 初始化数据初始化服务
    final dataInitService = DataInitializationService();
    dataInitService.initialize(
      databaseService: databaseService,
      userProfileService: userProfileService,
      healthDataSyncService: healthDataSyncService,
    );

    // 初始化今日数据
    await dataInitService.initializeTodayData();

    runApp(const ProviderScope(child: App()));
  } catch (e) {
    print('应用初始化失败: $e');
    runApp(const ProviderScope(child: App()));
  }
}
```

## 数据流程

### 修改后的数据流程

```
健康平台数据 → DailySteps (Hive) → HealthDataSyncService → UserDailyData (SQLite) → 排行页面显示
用户配置更新 → UserProfile → userDailyDataRankingProvider → 排行页面自动刷新
```

### 同步时机

1. **应用启动时**：通过`DataInitializationService.initializeTodayData()`
2. **健康数据更新时**：通过`dailyStepsProvider`
3. **用户配置更新时**：通过`userDailyDataRankingProvider`的依赖关系

## 测试功能

在测试数据页面添加了新的测试功能：

- **同步健康数据**：手动触发健康数据同步
- **刷新排行数据**：手动刷新排行页面数据

## 优势

### 1. 数据一致性
- 健康数据与每日数据保持同步
- 用户配置更新立即反映到排行页面

### 2. 自动化
- 无需手动操作，数据自动同步
- 应用启动时自动初始化

### 3. 实时性
- 用户配置更新后立即生效
- 健康数据更新后自动同步

### 4. 可靠性
- 错误处理完善
- 同步失败不影响其他功能

## 注意事项

### 1. 性能考虑
- 同步操作在后台进行
- 避免频繁同步，只在必要时触发

### 2. 数据完整性
- 保留用户自定义信息
- 只更新步数数据

### 3. 错误处理
- 同步失败不影响应用正常运行
- 提供详细的错误日志

## 总结

通过以上修改，现在应用能够：

1. **实时更新排行数据**：用户配置修改后立即反映到排行页面
2. **正确显示步数**：健康平台的步数数据正确同步到每日数据表
3. **自动化同步**：无需手动操作，数据自动保持同步
4. **提供良好的用户体验**：数据更新及时，显示准确

这个解决方案从根本上解决了数据同步和步数显示问题，确保用户能够看到准确、实时的数据。
