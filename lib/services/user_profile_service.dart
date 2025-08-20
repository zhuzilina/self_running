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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../data/models/user_profile.dart';
import 'storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../data/models/user_daily_data.dart'; // Added import for UserDailyData
import '../services/database_service.dart'; // Added import for DatabaseService

class UserProfileService {
  static const String _profileKey = 'user_profile';
  final StorageService _storage;

  UserProfileService(this._storage);

  Future<void> init() async {
    await _storage.init();
  }

  Future<UserProfile> getUserProfile() async {
    final box = Hive.box(StorageService.dailyStepsBoxName);
    final jsonString = box.get(_profileKey);
    if (jsonString == null || jsonString.isEmpty) {
      return UserProfile.defaultProfile();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      return UserProfile.defaultProfile();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    final box = Hive.box(StorageService.dailyStepsBoxName);
    await box.put(_profileKey, jsonString);
  }

  /// 更新用户配置并同步到每日数据
  Future<void> updateProfile({
    String? nickname,
    String? slogan,
    String? avatar,
    String? coverImage,
  }) async {
    try {
      final currentProfile = await getUserProfile();

      // 更新用户配置
      final updatedProfile = currentProfile.copyWith(
        nickname: nickname ?? currentProfile.nickname,
        slogan: slogan ?? currentProfile.slogan,
        avatar: avatar ?? currentProfile.avatar,
        coverImage: coverImage ?? currentProfile.coverImage,
      );

      await saveUserProfile(updatedProfile);

      // 同步更新今日的每日数据记录
      await _syncToDailyData(updatedProfile);
    } catch (e) {
      throw Exception('更新用户配置失败: $e');
    }
  }

  /// 同步用户配置到每日数据
  Future<void> _syncToDailyData(UserProfile profile) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 获取今日的每日数据记录
      final databaseService = DatabaseService();
      final existingData = await databaseService.getUserDailyData(todayId);

      if (existingData != null) {
        // 更新现有记录
        final updatedData = existingData.copyWith(
          nickname: profile.nickname,
          slogan: profile.slogan,
          avatarPath: profile.avatar,
          backgroundPath: profile.coverImage,
          updatedAt: DateTime.now(),
        );
        await databaseService.saveUserDailyData(updatedData);
      } else {
        // 创建新的今日记录
        final newData = UserDailyData.create(
          nickname: profile.nickname,
          slogan: profile.slogan,
          avatarPath: profile.avatar,
          backgroundPath: profile.coverImage,
          steps: 0,
          date: today,
          isEditable: true,
        );
        await databaseService.saveUserDailyData(newData);
      }
    } catch (e) {
      assert(() {
        print('同步用户配置到每日数据失败: $e');
        return true;
      }());
      // 不抛出异常，避免影响用户配置的更新
    }
  }

  Future<String?> saveImageToLocal(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/user_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final file = File('${imagesDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      assert(() {
        print('保存图片失败: $e');
        return true;
      }());
      return null;
    }
  }
}
