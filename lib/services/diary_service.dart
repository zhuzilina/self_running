import 'dart:typed_data';
import '../data/models/diary.dart';
import '../data/models/audio_file.dart';
import 'database_service.dart';
import 'file_storage_service.dart';

class DiaryService {
  final DatabaseService _databaseService = DatabaseService();
  final FileStorageService _fileStorageService = FileStorageService.instance;

  /// 获取今日日记
  Future<Diary?> getTodayDiary() async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      return await _databaseService.getDiary(todayId);
    } catch (e) {
      throw Exception('获取今日日记失败: $e');
    }
  }

  /// 保存今日日记（使用新的直接存储逻辑）
  Future<void> saveTodayDiary({
    required String content,
    required List<Uint8List> imageDataList,
    required List<AudioFile> audioFiles, // 使用AudioFile列表
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 直接保存图片到目标目录
      final List<String> imagePaths = [];
      for (int i = 0; i < imageDataList.length; i++) {
        final imagePath = await _fileStorageService.saveImageDirectly(
          imageDataList[i],
          'diary_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          todayId,
        );
        if (imagePath != null) {
          imagePaths.add(imagePath);
        }
      }

      // 创建日记对象
      final diary = Diary.create(
        content: content,
        date: today,
        imagePaths: imagePaths,
        audioFiles: audioFiles, // 使用AudioFile列表
      );

      // 保存到数据库
      await _databaseService.saveDiary(diary);

      // 文件清理已在页面层面处理，这里不再清理
    } catch (e) {
      throw Exception('保存今日日记失败: $e');
    }
  }

  /// 删除日记（仅删除数据库记录，不清理文件）
  Future<void> deleteDiary(String id) async {
    try {
      // 只删除数据库记录，不清理文件
      await _databaseService.deleteDiary(id);
    } catch (e) {
      throw Exception('删除日记失败: $e');
    }
  }

  /// 直接保存音频文件到目标目录
  Future<AudioFile?> saveAudioDirectly({
    required String sourcePath,
    required String displayName,
    required int duration,
    required DateTime recordTime,
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      final audioPath = await _fileStorageService.saveAudioDirectly(
        sourcePath,
        'diary_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        todayId,
      );

      if (audioPath != null) {
        return AudioFile.create(
          displayName: displayName,
          filePath: audioPath,
          duration: duration,
          recordTime: recordTime,
        );
      }
      return null;
    } catch (e) {
      throw Exception('保存音频文件失败: $e');
    }
  }

  /// 直接保存图片到目标目录
  Future<String?> saveImageDirectly(
    Uint8List imageData,
    String originalName,
  ) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      return await _fileStorageService.saveImageDirectly(
        imageData,
        originalName,
        todayId,
      );
    } catch (e) {
      throw Exception('保存图片失败: $e');
    }
  }

  // 保留旧方法以保持兼容性
  Future<String?> saveImageToStorage(
    Uint8List imageData,
    String originalName,
  ) async {
    return await _fileStorageService.saveImage(imageData, originalName);
  }

  Future<String?> saveAudioToStorage(
    String sourcePath,
    String originalName,
  ) async {
    return await _fileStorageService.saveAudio(sourcePath, originalName);
  }
}
