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

import 'package:intl/intl.dart';
import '../data/models/daily_steps.dart';
import '../data/models/user_daily_data.dart';
import '../data/models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../services/user_profile_service.dart';

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
  }) : _storageService = storageService,
       _databaseService = databaseService,
       _userProfileService = userProfileService;

  /// 同步健康数据到每日数据表
  Future<void> syncHealthDataToDailyData() async {
    try {
      // 获取所有健康数据
      final healthData = _storageService.loadAllDailySteps();

      if (healthData.isEmpty) {
        assert(() {
          print('HealthDataSyncService: 暂无健康数据');
          return true;
        }());
        return;
      }

      // 获取用户配置
      final userProfile = await _userProfileService.getUserProfile();

      // 同步每个日期的数据
      for (final dailySteps in healthData) {
        await _syncSingleDayData(dailySteps, userProfile);
      }

      assert(() {

        print('HealthDataSyncService: 同步完成，共处理 ${healthData.length} 条数据');

        return true;

      }());
    } catch (e) {
      assert(() {
        print('HealthDataSyncService: 同步失败 - $e');
        return true;
      }());
    }
  }

  /// 同步单日数据
  Future<void> _syncSingleDayData(
    DailySteps dailySteps,
    UserProfile userProfile,
  ) async {
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
      assert(() {
        print('HealthDataSyncService: 同步单日数据失败 ${dailySteps.localDay} - $e');
        return true;
      }());
    }
  }

  /// 同步今日数据
  Future<void> syncTodayData() async {
    try {
      final today = DateTime.now();
      final todayKey = DateFormat('yyyy-MM-dd').format(today);

      // 获取今日健康数据
      final allHealthData = _storageService.loadAllDailySteps();
      final todayHealthData = allHealthData
          .where(
            (data) =>
                DateFormat('yyyy-MM-dd').format(data.localDay) == todayKey,
          )
          .firstOrNull;

      if (todayHealthData != null) {
        final userProfile = await _userProfileService.getUserProfile();
        await _syncSingleDayData(todayHealthData, userProfile);
        assert(() {
          print('HealthDataSyncService: 今日数据同步完成，步数: ${todayHealthData.steps}');
          return true;
        }());
      } else {
        assert(() {
          print('HealthDataSyncService: 未找到今日健康数据');
          return true;
        }());
      }
    } catch (e) {
      assert(() {
        print('HealthDataSyncService: 同步今日数据失败 - $e');
        return true;
      }());
    }
  }

  /// 格式化日期ID
  String _formatDateId(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
