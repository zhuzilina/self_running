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

import 'package:flutter_test/flutter_test.dart';
import 'package:self_running/services/database_service.dart';
import 'package:self_running/data/models/user_daily_data.dart';
import 'package:self_running/data/models/diary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('UserDailyData Tests', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    test('should create and retrieve user daily data', () async {
      // 创建测试用户数据
      final userData = UserDailyData.create(
        nickname: '测试用户',
        slogan: '测试标语',
        avatarPath: '/path/to/avatar.jpg',
        backgroundPath: '/path/to/background.jpg',
        steps: 8000,
        date: DateTime.now(),
      );

      // 保存用户数据
      await databaseService.saveUserDailyData(userData);

      // 检索用户数据
      final retrievedUserData = await databaseService.getUserDailyData(
        userData.id,
      );

      // 验证
      expect(retrievedUserData, isNotNull);
      expect(retrievedUserData!.nickname, equals(userData.nickname));
      expect(retrievedUserData.slogan, equals(userData.slogan));
      expect(retrievedUserData.avatarPath, equals(userData.avatarPath));
      expect(retrievedUserData.backgroundPath, equals(userData.backgroundPath));
      expect(retrievedUserData.steps, equals(userData.steps));
    });

    test('should create diary with user daily data association', () async {
      // 创建用户数据
      final userData = UserDailyData.create(
        nickname: '测试用户',
        slogan: '测试标语',
        steps: 8000,
        date: DateTime.now(),
      );

      await databaseService.saveUserDailyData(userData);

      // 创建日记
      final diary = Diary.create(
        content: '测试日记内容',
        date: DateTime.now(),
        images: [], // 空的图片列表
        audioFiles: [], // 空的音频文件列表
      );

      // 保存日记（关联到用户数据）
      await databaseService.saveDiary(diary);

      // 获取用户数据和日记
      final result = await databaseService.getUserDailyDataWithDiary(
        userData.id,
      );

      // 验证
      expect(result, isNotNull);
      expect(result!.nickname, equals('测试用户'));

      // 获取关联的日记
      final diaryResult = await databaseService.getDiary(userData.id);
      expect(diaryResult, isNotNull);
      expect(diaryResult!.content, equals('测试日记内容'));
    });

    test('should get all user daily data', () async {
      // 创建多个用户数据
      final userData1 = UserDailyData.create(
        nickname: '用户1',
        slogan: '标语1',
        steps: 8000,
        date: DateTime.now().subtract(const Duration(days: 1)),
      );

      final userData2 = UserDailyData.create(
        nickname: '用户2',
        slogan: '标语2',
        steps: 10000,
        date: DateTime.now(),
      );

      // 保存用户数据
      await databaseService.saveUserDailyData(userData1);
      await databaseService.saveUserDailyData(userData2);

      // 获取所有用户数据
      final allUserData = await databaseService.getAllUserDailyData();

      // 验证
      expect(allUserData.length, greaterThanOrEqualTo(2));
    });

    test('should delete user daily data', () async {
      // 创建测试用户数据
      final userData = UserDailyData.create(
        nickname: '要删除的用户',
        slogan: '要删除的标语',
        steps: 5000,
        date: DateTime.now(),
      );

      // 保存用户数据
      await databaseService.saveUserDailyData(userData);

      // 验证用户数据存在
      final retrievedUserData = await databaseService.getUserDailyData(
        userData.id,
      );
      expect(retrievedUserData, isNotNull);

      // 删除用户数据
      await databaseService.deleteUserDailyData(userData.id);

      // 验证用户数据已被删除
      final deletedUserData = await databaseService.getUserDailyData(
        userData.id,
      );
      expect(deletedUserData, isNull);
    });

    test('should handle default avatar and background paths', () {
      final userData = UserDailyData.create(
        nickname: '测试用户',
        slogan: '测试标语',
        steps: 8000,
        date: DateTime.now(),
      );

      // 测试默认路径
      expect(
        userData.effectiveAvatarPath,
        equals(UserDailyData.defaultAvatarPath),
      );
      expect(
        userData.effectiveBackgroundPath,
        equals(UserDailyData.defaultBackgroundPath),
      );

      // 测试自定义路径
      final userDataWithCustomPaths = userData.copyWith(
        avatarPath: '/custom/avatar.jpg',
        backgroundPath: '/custom/background.jpg',
      );

      expect(
        userDataWithCustomPaths.effectiveAvatarPath,
        equals('/custom/avatar.jpg'),
      );
      expect(
        userDataWithCustomPaths.effectiveBackgroundPath,
        equals('/custom/background.jpg'),
      );
    });
  });
}
