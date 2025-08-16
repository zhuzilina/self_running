import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/health_permission_service.dart';
import 'services/data_initialization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 请求健康数据权限
  try {
    final healthPermissionService = HealthPermissionService();
    final available = await healthPermissionService.isHealthDataAvailable();
    print('Health data available: $available');

    if (available) {
      final granted = await healthPermissionService.requestPermissions();
      print('Health permissions requested on startup: $granted');
    }
  } catch (e) {
    print('Error requesting health permissions on startup: $e');
  }

  runApp(const ProviderScope(child: App()));
}
