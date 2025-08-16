import 'package:flutter/material.dart';
import '../data/models/diary.dart';
import '../data/models/user_daily_data.dart';
import 'database_service.dart';
import 'user_profile_service.dart';
import 'diary_service.dart';
import 'storage_service.dart';

class DataInitializationService {
  static final DataInitializationService _instance =
      DataInitializationService._internal();
  factory DataInitializationService() => _instance;
  DataInitializationService._internal();

  final DatabaseService _databaseService = DatabaseService();
  UserProfileService? _userProfileService;
  final DiaryService _diaryService = DiaryService();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return; // 避免重复初始化
    }

    final storageService = StorageService();
    await storageService.init();
    _userProfileService = UserProfileService(storageService);
    await _userProfileService!.init();
    _initialized = true;
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

  /// 初始化今日数据
  Future<void> initializeTodayData() async {
    try {
      // 检查系统日期
      if (!isSystemDateValid()) {
        print('系统日期异常，请检查设备时间设置');
        return;
      }

      final todayId = getCurrentDateId();
      final yesterdayId = getYesterdayDateId();

      // 1. 处理昨天的记录 - 标记为不可修改
      await _markYesterdayAsNonEditable(yesterdayId);

      // 2. 确保今日用户数据存在
      await _ensureTodayUserDataExists(todayId);

      // 3. 确保今日日记记录存在
      await _ensureTodayDiaryExists(todayId);

      print('今日数据初始化完成');
    } catch (e) {
      print('数据初始化失败: $e');
    }
  }

  /// 标记昨天的记录为不可修改
  Future<void> _markYesterdayAsNonEditable(String yesterdayId) async {
    try {
      final yesterdayDiary = await _databaseService.getDiary(yesterdayId);
      if (yesterdayDiary != null && yesterdayDiary.isEditable) {
        final nonEditableDiary = yesterdayDiary.copyWith(isEditable: false);
        await _databaseService.saveDiary(nonEditableDiary);
        print('已标记昨日记录为不可修改: $yesterdayId');
      }
    } catch (e) {
      print('标记昨日记录失败: $e');
    }
  }

  /// 确保今日用户数据存在
  Future<void> _ensureTodayUserDataExists(String todayId) async {
    try {
      final existingUserData = await _databaseService.getUserDailyData(todayId);
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
        await _databaseService.saveUserDailyData(todayUserData);
        print('已创建今日用户数据: $todayId');
      }
    } catch (e) {
      print('创建今日用户数据失败: $e');
    }
  }

  /// 确保今日日记记录存在
  Future<void> _ensureTodayDiaryExists(String todayId) async {
    try {
      final existingDiary = await _databaseService.getDiary(todayId);
      if (existingDiary == null) {
        // 创建今日日记记录
        final todayDiary = Diary.create(
          content: '',
          date: DateTime.now(),
          isEditable: true,
        );
        await _databaseService.saveDiary(todayDiary);
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

      final todayId = getCurrentDateId();
      final todayDiary = await _databaseService.getDiary(todayId);

      if (todayDiary == null) {
        return true; // 如果不存在，允许创建
      }

      return todayDiary.isEditable;
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
