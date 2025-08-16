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
}
