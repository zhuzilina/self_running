import 'dart:typed_data';
import '../data/models/diary.dart';
import '../data/models/audio_file.dart';
import 'database_service.dart';
import 'file_storage_service.dart';
import 'audio_file_manager.dart';

class DiaryService {
  final DatabaseService _databaseService = DatabaseService();
  final FileStorageService _fileStorageService = FileStorageService.instance;
  final AudioFileManager _audioFileManager = AudioFileManager.instance;

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

  /// 保存今日日记（智能更新，避免不必要的文件删除）
  Future<void> saveTodayDiary({
    required String content,
    required List<Uint8List> imageDataList,
    required List<AudioFile> audioFiles, // 使用AudioFile列表
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 获取现有日记
      final existingDiary = await _databaseService.getDiary(todayId);

      // 直接保存图片到目标目录（使用hash文件名）
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

      // 如果有现有日记，进行智能更新
      if (existingDiary != null) {
        // 找出需要删除的音频文件（在现有日记中但不在新音频列表中的）
        final existingAudioIds = existingDiary.audioFiles
            .map((a) => a.id)
            .toSet();
        final newAudioIds = audioFiles.map((a) => a.id).toSet();
        final audioIdsToDelete = existingAudioIds.difference(newAudioIds);

        // 标记需要删除的音频文件
        for (final audioId in audioIdsToDelete) {
          await _audioFileManager.markAudioFileAsDeleted(audioId);
        }

        // 更新日记对象
        final updatedDiary = existingDiary.copyWith(
          content: content,
          imagePaths: imagePaths,
          audioFiles: audioFiles,
        );

        // 更新数据库
        await _databaseService.saveDiary(updatedDiary);
      } else {
        // 创建新日记对象
        final diary = Diary.create(
          content: content,
          date: today,
          imagePaths: imagePaths,
          audioFiles: audioFiles,
        );

        // 保存到数据库
        await _databaseService.saveDiary(diary);
      }

      // 清理未使用的文件
      final allUsedPaths = [
        ...imagePaths,
        ...audioFiles.map((a) => a.filePath),
      ];
      await _fileStorageService.cleanupUnusedFiles(todayId, allUsedPaths);
    } catch (e) {
      throw Exception('保存今日日记失败: $e');
    }
  }

  /// 删除日记（包括音频文件）
  Future<void> deleteDiary(String dateId) async {
    try {
      // 获取日记数据
      final diary = await _databaseService.getDiary(dateId);
      if (diary != null) {
        // 标记音频文件为删除状态
        for (final audioFile in diary.audioFiles) {
          await _audioFileManager.markAudioFileAsDeleted(audioFile.id);
        }

        // 删除数据库记录
        await _databaseService.deleteDiary(dateId);

        // 清理图片文件
        await _fileStorageService.cleanupUnusedFiles(dateId, diary.imagePaths);
      }
    } catch (e) {
      print('删除日记失败: $e');
    }
  }

  /// 删除单个音频文件
  Future<bool> deleteAudioFile(String audioFileId) async {
    try {
      // 标记音频文件为删除状态
      final success = await _audioFileManager.markAudioFileAsDeleted(
        audioFileId,
      );

      if (success) {
        // 触发异步清理
        _audioFileManager.triggerCleanup();
      }

      return success;
    } catch (e) {
      print('删除音频文件失败: $e');
      return false;
    }
  }

  /// 获取文件统计信息
  Future<Map<String, dynamic>> getFileStats() async {
    try {
      final audioStats = await _audioFileManager.getFileStats();
      final storageStats = await _fileStorageService.getStorageStats();

      return {...audioStats, ...storageStats};
    } catch (e) {
      print('获取文件统计信息失败: $e');
      return {};
    }
  }

  /// 手动触发清理任务
  Future<void> triggerCleanup() async {
    try {
      await _audioFileManager.triggerCleanup();
    } catch (e) {
      print('触发清理任务失败: $e');
    }
  }

  /// 初始化服务
  Future<void> initialize() async {
    try {
      await _audioFileManager.initialize();
    } catch (e) {
      print('初始化日记服务失败: $e');
    }
  }

  /// 销毁服务
  void dispose() {
    _audioFileManager.dispose();
  }

  /// 使用新的音频文件管理器保存音频文件
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

      // 使用新的音频文件管理器进行两阶段提交
      final audioFile = await _audioFileManager.saveAudioFile(
        sourcePath: sourcePath,
        displayName: displayName,
        duration: duration,
        recordTime: recordTime,
        dateId: todayId,
      );

      return audioFile;
    } catch (e) {
      print('保存音频文件失败: $e');
      return null;
    }
  }

  /// 直接保存图片到目标目录
  /// 使用hash文件名保存，确保唯一性
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
