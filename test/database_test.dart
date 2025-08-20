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
import 'package:self_running/data/models/diary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService Tests', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    test('should create and retrieve diary', () async {
      // 创建测试日记
      final diary = Diary.create(content: '测试日记内容', date: DateTime.now());

      // 保存日记
      await databaseService.saveDiary(diary);

      // 检索日记
      final retrievedDiary = await databaseService.getDiary(diary.id);

      // 验证
      expect(retrievedDiary, isNotNull);
      expect(retrievedDiary!.content, equals(diary.content));
      expect(retrievedDiary.images.length, equals(diary.images.length));
      expect(retrievedDiary.audioFiles.length, equals(diary.audioFiles.length));
    });

    test('should get all diaries', () async {
      // 创建多个测试日记
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayId =
          '${yesterday.year}${yesterday.month.toString().padLeft(2, '0')}${yesterday.day.toString().padLeft(2, '0')}';

      final diary1 = Diary.create(content: '日记1', date: yesterday);

      final diary2 = Diary.create(content: '日记2', date: today);

      // 保存日记
      await databaseService.saveDiary(diary1);
      await databaseService.saveDiary(diary2);

      // 获取所有日记
      final allDiaries = await databaseService.getAllDiaries();

      // 验证
      expect(allDiaries.length, greaterThanOrEqualTo(2));
    });

    test('should delete diary', () async {
      // 创建测试日记
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final diary = Diary.create(content: '要删除的日记', date: today);

      // 保存日记
      await databaseService.saveDiary(diary);

      // 验证日记存在
      final retrievedDiary = await databaseService.getDiary(todayId);
      expect(retrievedDiary, isNotNull);

      // 删除日记
      await databaseService.deleteDiary(todayId);

      // 验证日记已被删除
      final deletedDiary = await databaseService.getDiary(todayId);
      expect(deletedDiary, isNull);
    });

    test('should search diaries by content', () async {
      // 创建测试日记
      final diary1 = Diary.create(
        content: '今天天气很好，我去跑步了',
        date: DateTime(2024, 1, 15),
      );

      final diary2 = Diary.create(
        content: '今天下雨了，在家看书',
        date: DateTime(2024, 1, 16),
      );

      // 保存日记
      await databaseService.saveDiary(diary1);
      await databaseService.saveDiary(diary2);

      // 搜索内容
      final results = await databaseService.searchDiaries('跑步');

      expect(results.length, 1);
      expect(results.first.content, contains('跑步'));
    });

    test('should search diaries by numeric query', () async {
      // 创建测试日记
      final diary1 = Diary.create(
        content: '今天天气很好',
        date: DateTime(2024, 1, 15),
      );

      final diary2 = Diary.create(
        content: '今天下雨了',
        date: DateTime(2024, 1, 16),
      );

      // 保存日记
      await databaseService.saveDiary(diary1);
      await databaseService.saveDiary(diary2);

      // 搜索数字（应该匹配ID和日期）
      final results = await databaseService.searchDiaries('15');

      expect(results.length, greaterThanOrEqualTo(1));

      // 验证至少有一个结果包含15
      bool hasMatch = results.any(
        (diary) =>
            diary.id.contains('15') ||
            diary.content.contains('15') ||
            diary.date.day == 15,
      );
      expect(hasMatch, isTrue);
    });
  });
}
