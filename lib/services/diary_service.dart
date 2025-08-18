import 'dart:typed_data';
import '../data/models/diary.dart';
import '../data/models/audio_file.dart';
import '../data/models/image_info.dart';
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

  /// 预保存今日日记（立即保存，不检查日期）
  Future<void> preSaveTodayDiary({
    required String content,
    required List<Uint8List> imageDataList,
    required List<AudioFile> audioFiles,
  }) async {
    try {
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 获取现有日记
      final existingDiary = await _databaseService.getDiary(todayId);

      // 保存图片（原图 + 缩略图）到目标目录
      final List<ImageInfo> images = [];
      for (int i = 0; i < imageDataList.length; i++) {
        final imagePaths = await _fileStorageService.saveImageWithThumbnail(
          imageDataList[i],
          'diary_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          todayId,
        );
        if (imagePaths != null) {
          images.add(
            ImageInfo(
              originalPath: imagePaths['originalPath']!,
              thumbnailPath: imagePaths['thumbnailPath']!,
              originalName:
                  'diary_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              createdAt: DateTime.now(),
            ),
          );
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
          images: images,
          audioFiles: audioFiles,
          isEditable: true, // 预保存时确保可编辑
        );

        // 更新数据库
        await _databaseService.saveDiary(updatedDiary);
      } else {
        // 创建新日记对象
        final diary = Diary.create(
          content: content,
          date: today,
          images: images,
          audioFiles: audioFiles,
          isEditable: true, // 预保存时默认可编辑
        );

        // 保存到数据库
        await _databaseService.saveDiary(diary);
      }

      // 清理未使用的文件
      final allUsedPaths = [
        ...images.map((img) => img.originalPath),
        ...images.map((img) => img.thumbnailPath),
        ...audioFiles.map((a) => a.filePath),
      ];
      await _fileStorageService.cleanupUnusedFiles(todayId, allUsedPaths);
    } catch (e) {
      throw Exception('预保存今日日记失败: $e');
    }
  }

  /// 智能保存今日日记（检查编辑权限）
  Future<void> smartSaveTodayDiary({
    required String content,
    required List<Uint8List> imageDataList,
    required List<AudioFile> audioFiles,
  }) async {
    try {
      // 首先检查今日是否可编辑
      final isEditable = await isTodayEditable();
      if (!isEditable) {
        throw Exception('今日记录已锁定，无法修改');
      }

      // 如果可编辑，则进行预保存
      await preSaveTodayDiary(
        content: content,
        imageDataList: imageDataList,
        audioFiles: audioFiles,
      );
    } catch (e) {
      throw Exception('智能保存今日日记失败: $e');
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

      // 保存图片（原图 + 缩略图）到目标目录
      final List<ImageInfo> images = [];
      for (int i = 0; i < imageDataList.length; i++) {
        final imagePaths = await _fileStorageService.saveImageWithThumbnail(
          imageDataList[i],
          'diary_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          todayId,
        );
        if (imagePaths != null) {
          images.add(
            ImageInfo(
              originalPath: imagePaths['originalPath']!,
              thumbnailPath: imagePaths['thumbnailPath']!,
              originalName:
                  'diary_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              createdAt: DateTime.now(),
            ),
          );
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
          images: images,
          audioFiles: audioFiles,
        );

        // 更新数据库
        await _databaseService.saveDiary(updatedDiary);
      } else {
        // 创建新日记对象
        final diary = Diary.create(
          content: content,
          date: today,
          images: images,
          audioFiles: audioFiles,
        );

        // 保存到数据库
        await _databaseService.saveDiary(diary);
      }

      // 清理未使用的文件
      final allUsedPaths = [
        ...images.map((img) => img.originalPath),
        ...images.map((img) => img.thumbnailPath),
        ...audioFiles.map((a) => a.filePath),
      ];
      await _fileStorageService.cleanupUnusedFiles(todayId, allUsedPaths);
    } catch (e) {
      throw Exception('保存今日日记失败: $e');
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

  /// 获取指定日期的日记
  Future<Diary?> getDiaryByDate(DateTime date) async {
    try {
      return await _databaseService.getDiaryByDate(date);
    } catch (e) {
      throw Exception('获取指定日期日记失败: $e');
    }
  }

  /// 获取所有日记
  Future<List<Diary>> getAllDiaries() async {
    try {
      return await _databaseService.getAllDiaries();
    } catch (e) {
      throw Exception('获取所有日记失败: $e');
    }
  }

  /// 搜索日记内容
  Future<List<Diary>> searchDiaries(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await _databaseService.getAllDiaries();
      }
      return await _databaseService.searchDiaries(query.trim());
    } catch (e) {
      throw Exception('搜索日记失败: $e');
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
