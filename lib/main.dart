import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/data_initialization_service.dart';
import 'data/models/daily_steps_base.dart';
import 'services/storage_service.dart';
import 'services/user_profile_service.dart';
import 'services/health_data_sync_service.dart';

// WorkManager回调函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 显示通知
    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder',
          '每日提醒',
          channelDescription: '提醒用户记录每天的日记',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notifications.show(0, '每日提醒', '记得记录今天的美好瞬间哦！', notificationDetails);

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  await Hive.initFlutter();

  Hive.registerAdapter(DailyStepsBaseAdapter());

  // 初始化WorkManager
  await Workmanager().initialize(callbackDispatcher);

  // 初始化本地通知
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

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
