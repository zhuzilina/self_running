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
      final diary = Diary.create(
        content: '测试日记内容',
        date: DateTime.now(),
        imagePaths: ['test_image1.jpg', 'test_image2.jpg'],
        audioFiles: [], // 空的音频文件列表
      );

      // 保存日记
      await databaseService.saveDiary(diary);

      // 检索日记
      final retrievedDiary = await databaseService.getDiary(diary.id);

      // 验证
      expect(retrievedDiary, isNotNull);
      expect(retrievedDiary!.content, equals(diary.content));
      expect(retrievedDiary.imagePaths, equals(diary.imagePaths));
      expect(retrievedDiary.audioFiles, equals(diary.audioFiles));
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
  });
}
