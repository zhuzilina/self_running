import 'package:flutter/material.dart';
import '../data/models/diary.dart';
import '../data/models/user_daily_data.dart';
import 'database_service.dart';
import 'user_profile_service.dart';
import 'diary_service.dart';
import 'storage_service.dart';
import '../services/health_data_sync_service.dart';

class DataInitializationService {
  static final DataInitializationService _instance =
      DataInitializationService._internal();
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

  /// 检查系统日期是否正确
  bool isSystemDateValid() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 检查今天和昨天的日期是否合理（不能是未来日期）
    if (today.isAfter(DateTime.now())) {
      return false;
    }

    return true;
  }

  /// 获取当前日期ID
  String getCurrentDateId() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// 获取昨天的日期ID
  String getYesterdayDateId() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';
  }

  /// 初始化今日数据（确保今日记录存在）
  Future<void> initializeTodayData() async {
    final today = DateTime.now();
    final todayId =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

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

  /// 预保存今日数据（立即保存，不检查日期）
  Future<void> preSaveTodayData({
    String? nickname,
    String? slogan,
    int? steps,
    String? diaryContent,
  }) async {
    try {
      final today = DateTime.now();
      final todayId = getCurrentDateId();

      // 预保存用户数据
      if (nickname != null || slogan != null || steps != null) {
        final userProfile = await _userProfileService!.getUserProfile();
        final existingUserData = await _databaseService!.getUserDailyData(
          todayId,
        );

        if (existingUserData != null) {
          // 更新现有数据
          final updatedUserData = existingUserData.copyWith(
            nickname: nickname ?? existingUserData.nickname,
            slogan: slogan ?? existingUserData.slogan,
            steps: steps ?? existingUserData.steps,
            isEditable: true, // 确保可编辑
          );
          await _databaseService!.preSaveUserDailyData(updatedUserData);
        } else {
          // 创建新数据
          final newUserData = UserDailyData.create(
            nickname: nickname ?? userProfile.nickname,
            slogan: slogan ?? userProfile.slogan,
            steps: steps ?? 0,
            date: today,
            isEditable: true,
          );
          await _databaseService!.preSaveUserDailyData(newUserData);
        }
      }

      // 预保存日记数据
      if (diaryContent != null) {
        final existingDiary = await _databaseService!.getDiary(todayId);

        if (existingDiary != null) {
          // 更新现有日记
          final updatedDiary = existingDiary.copyWith(
            content: diaryContent,
            isEditable: true, // 确保可编辑
          );
          await _databaseService!.saveDiary(updatedDiary);
        } else {
          // 创建新日记
          final newDiary = Diary.create(
            content: diaryContent,
            date: today,
            isEditable: true,
          );
          await _databaseService!.saveDiary(newDiary);
        }
      }

      print('今日数据预保存完成');
    } catch (e) {
      print('预保存今日数据失败: $e');
    }
  }

  /// 智能保存今日数据（检查编辑权限）
  Future<void> smartSaveTodayData({
    String? nickname,
    String? slogan,
    int? steps,
    String? diaryContent,
  }) async {
    try {
      // 首先检查今日是否可编辑
      final isEditable = await isTodayEditable();
      if (!isEditable) {
        throw Exception('今日记录已锁定，无法修改');
      }

      // 如果可编辑，则进行预保存
      await preSaveTodayData(
        nickname: nickname,
        slogan: slogan,
        steps: steps,
        diaryContent: diaryContent,
      );
    } catch (e) {
      print('智能保存今日数据失败: $e');
      rethrow;
    }
  }

  /// 检查并更新编辑状态（当日期变化时调用）
  Future<void> updateEditableStatusForDateChange() async {
    try {
      await _databaseService!.updateEditableStatusForDateChange();
      print('编辑状态更新完成');
    } catch (e) {
      print('更新编辑状态失败: $e');
    }
  }

  /// 标记昨天的记录为不可修改
  Future<void> _markYesterdayAsNonEditable(String yesterdayId) async {
    try {
      final yesterdayDiary = await _databaseService!.getDiary(yesterdayId);
      if (yesterdayDiary != null && yesterdayDiary.isEditable) {
        final nonEditableDiary = yesterdayDiary.copyWith(isEditable: false);
        await _databaseService!.saveDiary(nonEditableDiary);
        print('已标记昨日记录为不可修改: $yesterdayId');
      }
    } catch (e) {
      print('标记昨日记录失败: $e');
    }
  }

  /// 确保今日用户数据存在
  Future<void> _ensureTodayUserDataExists(String todayId) async {
    try {
      final existingUserData = await _databaseService!.getUserDailyData(
        todayId,
      );
      if (existingUserData == null) {
        // 创建今日用户数据
        final userProfile = await _userProfileService!.getUserProfile();
        final todayUserData = UserDailyData(
          id: todayId,
          nickname: userProfile.nickname,
          slogan: userProfile.slogan,
          avatarPath: userProfile.avatar,
          backgroundPath: userProfile.coverImage,
          steps: 0,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService!.saveUserDailyData(todayUserData);
        print('已创建今日用户数据: $todayId');
      }
    } catch (e) {
      print('创建今日用户数据失败: $e');
    }
  }

  /// 确保今日日记记录存在
  Future<void> _ensureTodayDiaryExists(String todayId) async {
    try {
      final existingDiary = await _databaseService!.getDiary(todayId);
      if (existingDiary == null) {
        // 创建今日日记记录
        final todayDiary = Diary.create(
          content: '',
          date: DateTime.now(),
          isEditable: true,
        );
        await _databaseService!.saveDiary(todayDiary);
        print('已创建今日日记记录: $todayId');
      }
    } catch (e) {
      print('创建今日日记记录失败: $e');
    }
  }

  /// 检查今日记录是否可编辑
  Future<bool> isTodayEditable() async {
    try {
      if (!isSystemDateValid()) {
        return false;
      }

      final today = DateTime.now();
      return await _databaseService!.isDateEditable(today);
    } catch (e) {
      print('检查今日记录可编辑状态失败: $e');
      return false;
    }
  }

  /// 获取系统日期状态信息
  Map<String, dynamic> getSystemDateStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = today.isAfter(DateTime.now());

    return {
      'isValid': isSystemDateValid(),
      'currentDate': today.toIso8601String(),
      'isFuture': isFuture,
      'message': isFuture ? '系统日期设置为未来时间，请检查设备时间设置' : '系统日期正常',
    };
  }
}
