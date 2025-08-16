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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  await Hive.initFlutter();
  Hive.registerAdapter(DailyStepsBaseAdapter());

  // 初始化数据库
  await DatabaseService().database;

  // 初始化数据管理服务
  try {
    final dataInitService = DataInitializationService();
    await dataInitService.init();
    await dataInitService.initializeTodayData();
    print('数据初始化完成');
  } catch (e) {
    print('数据初始化失败: $e');
  }

  // 初始化统一健康服务
  try {
    final unifiedHealthService = UnifiedHealthService();
    await unifiedHealthService.initialize();

    final dataSource = unifiedHealthService.getCurrentDataSource();
    print('Current health data source: $dataSource');

    if (dataSource != HealthDataSource.none) {
      final granted = await unifiedHealthService.requestPermissions();
      print('Health permissions requested on startup: $granted');
    }
  } catch (e) {
    print('Error initializing unified health service: $e');
  }

  // 初始化实时步数服务
  try {
    final realtimeStepsService = RealtimeStepsService();
    await realtimeStepsService.initialize();
    print('Realtime steps service initialized successfully');
  } catch (e) {
    print('Error initializing realtime steps service: $e');
  }

  // 初始化传感器步数服务
  try {
    final sensorStepsService = SensorStepsService();
    await sensorStepsService.initialize();
    print('Sensor steps service initialized successfully');
  } catch (e) {
    print('Error initializing sensor steps service: $e');
  }

  // 初始化步数基数服务
  try {
    final dailyStepsBaseService = DailyStepsBaseService();
    await dailyStepsBaseService.init();
    print('Daily steps base service initialized successfully');
  } catch (e) {
    print('Error initializing daily steps base service: $e');
  }

  // 初始化后台步数服务（WorkManager）
  try {
    final backgroundStepsService = BackgroundStepsService();
    await backgroundStepsService.initialize();
    print('Background steps service initialized successfully');
  } catch (e) {
    print('Error initializing background steps service: $e');
  }

  runApp(const ProviderScope(child: App()));
}
