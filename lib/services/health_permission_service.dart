/*
 * Copyright 2025 榆见晴天
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HealthPermissionService {
  static final HealthPermissionService _instance =
      HealthPermissionService._internal();
  factory HealthPermissionService() => _instance;
  HealthPermissionService._internal();

  final Health _health = Health();
  static const String _dontRemindKey = 'health_permission_dont_remind';

  /// 检查是否设置了"不再提醒"
  Future<bool> isDontRemindSet() async {
    try {
      final box = await Hive.openBox('app_settings');
      return box.get(_dontRemindKey, defaultValue: false);
    } catch (e) {
      assert(() {
        print('Error checking dont remind setting: $e');
        return true;
      }());
      return false;
    }
  }

  /// 设置"不再提醒"
  Future<void> setDontRemind() async {
    try {
      final box = await Hive.openBox('app_settings');
      await box.put(_dontRemindKey, true);
    } catch (e) {
      assert(() {
        print('Error setting dont remind: $e');
        return true;
      }());
    }
  }

  /// 使用permission_handler请求运动权限
  Future<bool> requestActivityPermission() async {
    try {
      final status = await Permission.activityRecognition.request();
      assert(() {
        print('Activity recognition permission status: $status');
        return true;
      }());
      return status.isGranted;
    } catch (e) {
      assert(() {
        print('Error requesting activity permission: $e');
        return true;
      }());
      return false;
    }
  }

  /// 检查运动权限状态
  Future<bool> checkActivityPermission() async {
    try {
      final status = await Permission.activityRecognition.status;
      assert(() {
        print('Activity recognition permission status: $status');
        return true;
      }());
      return status.isGranted;
    } catch (e) {
      assert(() {
        print('Error checking activity permission: $e');
        return true;
      }());
      return false;
    }
  }

  /// 打开应用设置页面
  Future<void> openAppSettingsPage() async {
    try {
      await openAppSettings();
    } catch (e) {
      assert(() {
        print('Error opening app settings: $e');
        return true;
      }());
    }
  }

  /// 检查健康数据权限状态（不自动请求权限）
  Future<bool> checkPermissions() async {
    try {
      // 通过尝试获取数据来检查权限状态，而不是直接请求权限
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      // 如果能成功获取数据，说明有权限
      final permissionsResult = await _health.hasPermissions([
        HealthDataType.STEPS,
      ]);
      final hasPermission = data.isNotEmpty || (permissionsResult ?? false);
      assert(() {
        print('Health permissions check result: $hasPermission');
        return true;
      }());
      return hasPermission;
    } catch (e) {
      assert(() {
        print('Error checking health permissions: $e');
        return true;
      }());
      return false;
    }
  }

  /// 请求健康数据权限
  Future<bool> requestPermissions() async {
    try {
      // 首先请求活动识别和位置权限
      await Permission.activityRecognition.request();
      await Permission.location.request();

      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
      ];

      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      assert(() {

        print('Health permissions request result: $granted');

        return true;

      }());
      return granted;
    } catch (e) {
      assert(() {
        print('Error requesting health permissions: $e');
        return true;
      }());
      return false;
    }
  }

  /// 检查设备是否支持健康数据
  Future<bool> isHealthDataAvailable() async {
    try {
      final available = await _health.isDataTypeAvailable(HealthDataType.STEPS);
      assert(() {
        print('Health data available: $available');
        return true;
      }());
      return available;
    } catch (e) {
      assert(() {
        print('Error checking health data availability: $e');
        return true;
      }());
      return false;
    }
  }
}
