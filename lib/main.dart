import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/health_permission_service.dart';
import 'services/data_initialization_service.dart';
import 'services/unified_health_service.dart';
import 'services/realtime_steps_service.dart';
import 'services/sensor_steps_service.dart';
import 'services/background_steps_service.dart';
import 'services/daily_steps_base_service.dart';
import 'data/models/daily_steps_base.dart';
import 'services/storage_service.dart';
import 'services/user_profile_service.dart';
import 'services/health_data_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  await Hive.initFlutter();

  Hive.registerAdapter(DailyStepsBaseAdapter());

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
