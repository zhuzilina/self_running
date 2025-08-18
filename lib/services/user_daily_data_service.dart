import 'dart:typed_data';
import '../data/models/user_daily_data.dart';
import 'database_service.dart';
import 'file_storage_service.dart';

class UserDailyDataService {
  final DatabaseService _databaseService = DatabaseService();
  final FileStorageService _fileStorageService = FileStorageService.instance;

  /// 获取今日用户数据
  Future<UserDailyData?> getTodayUserData() async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      return await _databaseService.getUserDailyData(todayId);
    } catch (e) {
      throw Exception('获取今日用户数据失败: $e');
    }
  }

  /// 预保存今日用户数据（立即保存，不检查日期）
  Future<void> preSaveTodayUserData({
    required String nickname,
    required String slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    required int steps,
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 保存头像文件
      String? avatarPath;
      if (avatarData != null) {
        avatarPath = await _fileStorageService.saveImage(
          avatarData,
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // 保存背景文件
      String? backgroundPath;
      if (backgroundData != null) {
        backgroundPath = await _fileStorageService.saveImage(
          backgroundData,
          'background_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final userData = UserDailyData.create(
        nickname: nickname,
        slogan: slogan,
        avatarPath: avatarPath,
        backgroundPath: backgroundPath,
        steps: steps,
        date: today,
        isEditable: true, // 预保存时默认可编辑
      );

      // 使用预保存方法，立即保存
      await _databaseService.preSaveUserDailyData(userData);
    } catch (e) {
      throw Exception('预保存今日用户数据失败: $e');
    }
  }

  /// 检查并更新编辑状态（当日期变化时调用）
  Future<void> updateEditableStatusForDateChange() async {
    try {
      await _databaseService.updateEditableStatusForDateChange();
    } catch (e) {
      throw Exception('更新编辑状态失败: $e');
    }
  }

  /// 检查今日记录是否可编辑
  Future<bool> isTodayEditable() async {
    try {
      final today = DateTime.now();
      return await _databaseService.isDateEditable(today);
    } catch (e) {
      throw Exception('检查今日编辑状态失败: $e');
    }
  }

  /// 获取指定日期的用户数据
  Future<UserDailyData?> getUserDataByDate(DateTime date) async {
    try {
      return await _databaseService.getUserDailyDataByDate(date);
    } catch (e) {
      throw Exception('获取指定日期用户数据失败: $e');
    }
  }

  /// 智能保存用户数据（检查编辑权限）
  Future<void> smartSaveUserData({
    required String nickname,
    required String slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    required int steps,
  }) async {
    try {
      // 首先检查今日是否可编辑
      final isEditable = await isTodayEditable();
      if (!isEditable) {
        throw Exception('今日记录已锁定，无法修改');
      }

      // 如果可编辑，则进行预保存
      await preSaveTodayUserData(
        nickname: nickname,
        slogan: slogan,
        avatarData: avatarData,
        backgroundData: backgroundData,
        steps: steps,
      );
    } catch (e) {
      throw Exception('智能保存用户数据失败: $e');
    }
  }

  /// 保存今日用户数据
  Future<void> saveTodayUserData({
    required String nickname,
    required String slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    required int steps,
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 保存头像文件
      String? avatarPath;
      if (avatarData != null) {
        avatarPath = await _fileStorageService.saveImage(
          avatarData,
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // 保存背景文件
      String? backgroundPath;
      if (backgroundData != null) {
        backgroundPath = await _fileStorageService.saveImage(
          backgroundData,
          'background_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final userData = UserDailyData.create(
        nickname: nickname,
        slogan: slogan,
        avatarPath: avatarPath,
        backgroundPath: backgroundPath,
        steps: steps,
        date: today,
      );

      await _databaseService.saveUserDailyData(userData);
    } catch (e) {
      throw Exception('保存今日用户数据失败: $e');
    }
  }

  /// 更新用户数据（不包含文件）
  Future<void> updateUserData({
    required String nickname,
    required String slogan,
    required int steps,
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final existingData = await _databaseService.getUserDailyData(todayId);
      if (existingData != null) {
        final updatedData = existingData.copyWith(
          nickname: nickname,
          slogan: slogan,
          steps: steps,
        );
        await _databaseService.saveUserDailyData(updatedData);
      } else {
        // 如果不存在，创建新的
        final userData = UserDailyData.create(
          nickname: nickname,
          slogan: slogan,
          steps: steps,
          date: today,
        );
        await _databaseService.saveUserDailyData(userData);
      }
    } catch (e) {
      throw Exception('更新用户数据失败: $e');
    }
  }

  /// 更新头像
  Future<void> updateAvatar(Uint8List avatarData) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final existingData = await _databaseService.getUserDailyData(todayId);
      if (existingData != null) {
        // 删除旧头像文件
        if (existingData.avatarPath != null) {
          await _fileStorageService.deleteFile(existingData.avatarPath!);
        }

        // 保存新头像
        final avatarPath = await _fileStorageService.saveImage(
          avatarData,
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        final updatedData = existingData.copyWith(avatarPath: avatarPath);
        await _databaseService.saveUserDailyData(updatedData);
      }
    } catch (e) {
      throw Exception('更新头像失败: $e');
    }
  }

  /// 更新背景图片
  Future<void> updateBackground(Uint8List backgroundData) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final existingData = await _databaseService.getUserDailyData(todayId);
      if (existingData != null) {
        // 删除旧背景文件
        if (existingData.backgroundPath != null) {
          await _fileStorageService.deleteFile(existingData.backgroundPath!);
        }

        // 保存新背景
        final backgroundPath = await _fileStorageService.saveImage(
          backgroundData,
          'background_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        final updatedData = existingData.copyWith(
          backgroundPath: backgroundPath,
        );
        await _databaseService.saveUserDailyData(updatedData);
      }
    } catch (e) {
      throw Exception('更新背景图片失败: $e');
    }
  }

  /// 更新步数
  Future<void> updateSteps(int steps) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final existingData = await _databaseService.getUserDailyData(todayId);
      if (existingData != null) {
        final updatedData = existingData.copyWith(steps: steps);
        await _databaseService.saveUserDailyData(updatedData);
      } else {
        // 如果不存在，创建新的（使用默认值）
        final userData = UserDailyData.create(
          nickname: '用户',
          slogan: '记录美好生活',
          steps: steps,
          date: today,
        );
        await _databaseService.saveUserDailyData(userData);
      }
    } catch (e) {
      throw Exception('更新步数失败: $e');
    }
  }

  /// 获取所有用户数据
  Future<List<UserDailyData>> getAllUserData() async {
    try {
      return await _databaseService.getAllUserDailyData();
    } catch (e) {
      throw Exception('获取所有用户数据失败: $e');
    }
  }

  /// 删除用户数据
  Future<void> deleteUserData(String id) async {
    try {
      final userData = await _databaseService.getUserDailyData(id);
      if (userData != null) {
        // 删除相关文件
        if (userData.avatarPath != null) {
          await _fileStorageService.deleteFile(userData.avatarPath!);
        }
        if (userData.backgroundPath != null) {
          await _fileStorageService.deleteFile(userData.backgroundPath!);
        }
      }

      await _databaseService.deleteUserDailyData(id);
    } catch (e) {
      throw Exception('删除用户数据失败: $e');
    }
  }

  /// 获取用户数据和对应的日记
  Future<UserDailyData?> getUserDataWithDiary(String id) async {
    try {
      return await _databaseService.getUserDailyDataWithDiary(id);
    } catch (e) {
      throw Exception('获取用户数据和日记失败: $e');
    }
  }

  /// 为指定日期创建用户数据（用于测试）
  Future<void> createUserDataForDate({
    required String nickname,
    required String slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    required int steps,
    required DateTime date,
  }) async {
    try {
      final dateId =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

      // 保存头像文件
      String? avatarPath;
      if (avatarData != null) {
        avatarPath = await _fileStorageService.saveImage(
          avatarData,
          'avatar_${date.millisecondsSinceEpoch}.jpg',
        );
      }

      // 保存背景文件
      String? backgroundPath;
      if (backgroundData != null) {
        backgroundPath = await _fileStorageService.saveImage(
          backgroundData,
          'background_${date.millisecondsSinceEpoch}.jpg',
        );
      }

      final userData = UserDailyData(
        id: dateId,
        nickname: nickname,
        slogan: slogan,
        avatarPath: avatarPath,
        backgroundPath: backgroundPath,
        steps: steps,
        date: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEditable: true,
      );

      await _databaseService.saveUserDailyData(userData);
    } catch (e) {
      throw Exception('为指定日期创建用户数据失败: $e');
    }
  }
}
