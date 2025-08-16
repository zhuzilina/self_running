import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/audio_file.dart';
import 'database_service.dart';

/// 音频文件管理器 - 实现两阶段提交和异步清理
class AudioFileManager {
  static AudioFileManager? _instance;
  final DatabaseService _databaseService = DatabaseService();
  Timer? _cleanupTimer;

  AudioFileManager._();

  static AudioFileManager get instance {
    _instance ??= AudioFileManager._();
    return _instance!;
  }

  /// 初始化管理器
  Future<void> initialize() async {
    // 启动定期清理任务
    _startCleanupTimer();
  }

  /// 销毁管理器
  void dispose() {
    _cleanupTimer?.cancel();
  }

  /// 获取应用文档目录
  Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// 获取临时目录（用于两阶段提交）
  Future<Directory> _getPendingDirectory(String dateId) async {
    final docsDir = await _documentsDirectory;
    final pendingDir = Directory(join(docsDir.path, 'data', dateId, 'pending'));
    if (!await pendingDir.exists()) {
      await pendingDir.create(recursive: true);
    }
    return pendingDir;
  }

  /// 获取音频目录
  Future<Directory> _getAudioDirectory(String dateId) async {
    final docsDir = await _documentsDirectory;
    final audioDir = Directory(join(docsDir.path, 'data', dateId, 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// 生成MD5 hash
  String _generateHash(Uint8List data) {
    final hash = md5.convert(data);
    return hash.toString();
  }

  /// 两阶段提交：保存音频文件
  /// 第一阶段：写入临时文件
  /// 第二阶段：验证成功后移动到正式目录并更新数据库
  Future<AudioFile?> saveAudioFile({
    required String sourcePath,
    required String displayName,
    required int duration,
    required DateTime recordTime,
    required String dateId,
  }) async {
    try {
      // 第一阶段：写入临时文件
      final pendingAudioFile = await _writeToPendingDirectory(
        sourcePath: sourcePath,
        displayName: displayName,
        duration: duration,
        recordTime: recordTime,
        dateId: dateId,
      );

      if (pendingAudioFile == null) {
        print('第一阶段失败：无法写入临时文件');
        return null;
      }

      // 第二阶段：验证文件完整性并移动到正式目录
      final finalAudioFile = await _moveToFinalLocation(
        pendingAudioFile,
        dateId,
      );

      if (finalAudioFile == null) {
        print('第二阶段失败：无法移动到正式目录');
        // 清理临时文件
        await _cleanupPendingFile(pendingAudioFile.filePath);
        return null;
      }

      // 更新数据库记录状态为active
      final activeAudioFile = finalAudioFile.markAsActive();

      print('音频文件保存成功: ${activeAudioFile.filePath}');
      return activeAudioFile;
    } catch (e) {
      print('保存音频文件失败: $e');
      return null;
    }
  }

  /// 第一阶段：写入临时目录
  Future<AudioFile?> _writeToPendingDirectory({
    required String sourcePath,
    required String displayName,
    required int duration,
    required DateTime recordTime,
    required String dateId,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('源文件不存在: $sourcePath');
        return null;
      }

      // 读取源文件数据
      final audioData = await sourceFile.readAsBytes();
      final hash = _generateHash(audioData);
      final fileName = '$hash.m4a';

      // 写入临时目录
      final pendingDir = await _getPendingDirectory(dateId);
      final pendingPath = join(pendingDir.path, fileName);
      final pendingFile = File(pendingPath);

      await sourceFile.copy(pendingPath);

      // 验证写入的文件
      if (!await pendingFile.exists()) {
        print('临时文件写入失败: $pendingPath');
        return null;
      }

      final pendingFileSize = await pendingFile.length();
      if (pendingFileSize != audioData.length) {
        print('文件大小不匹配: 期望${audioData.length}, 实际$pendingFileSize');
        await pendingFile.delete();
        return null;
      }

      // 创建pending状态的AudioFile对象
      return AudioFile.create(
        displayName: displayName,
        filePath: pendingPath,
        duration: duration,
        recordTime: recordTime,
      );
    } catch (e) {
      print('写入临时目录失败: $e');
      return null;
    }
  }

  /// 第二阶段：移动到正式目录
  Future<AudioFile?> _moveToFinalLocation(
    AudioFile pendingAudioFile,
    String dateId,
  ) async {
    try {
      final pendingFile = File(pendingAudioFile.filePath);
      if (!await pendingFile.exists()) {
        print('临时文件不存在: ${pendingAudioFile.filePath}');
        return null;
      }

      // 移动到正式目录
      final audioDir = await _getAudioDirectory(dateId);
      final fileName = basename(pendingAudioFile.filePath);
      final finalPath = join(audioDir.path, fileName);
      final finalFile = File(finalPath);

      // 如果目标文件已存在，先删除
      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      // 移动文件
      await pendingFile.rename(finalPath);

      // 验证移动后的文件
      if (!await finalFile.exists()) {
        print('文件移动失败: $finalPath');
        return null;
      }

      // 更新AudioFile对象
      return pendingAudioFile.copyWith(filePath: finalPath);
    } catch (e) {
      print('移动到正式目录失败: $e');
      return null;
    }
  }

  /// 逻辑删除音频文件（标记为删除状态）
  Future<bool> markAudioFileAsDeleted(String audioFileId) async {
    try {
      // 这里应该从数据库获取AudioFile对象
      // 暂时返回true，实际实现需要数据库操作
      print('标记音频文件为删除状态: $audioFileId');
      return true;
    } catch (e) {
      print('标记删除失败: $e');
      return false;
    }
  }

  /// 异步清理已删除的文件
  Future<void> cleanupDeletedFiles() async {
    try {
      print('开始清理已删除的音频文件...');

      // 获取所有标记为删除的音频文件
      final deletedFiles = await _getDeletedAudioFiles();

      for (final audioFile in deletedFiles) {
        await _physicallyDeleteFile(audioFile);
      }

      print('清理完成，处理了${deletedFiles.length}个文件');
    } catch (e) {
      print('清理已删除文件失败: $e');
    }
  }

  /// 获取已删除的音频文件列表
  Future<List<AudioFile>> _getDeletedAudioFiles() async {
    // 这里应该从数据库查询状态为deleted的音频文件
    // 暂时返回空列表，实际实现需要数据库操作
    return [];
  }

  /// 物理删除文件
  Future<void> _physicallyDeleteFile(AudioFile audioFile) async {
    try {
      final file = File(audioFile.filePath);
      if (await file.exists()) {
        await file.delete();
        print('物理删除文件成功: ${audioFile.filePath}');

        // 更新数据库记录（删除或标记为已清理）
        await _updateFileAsCleaned(audioFile.id);
      }
    } catch (e) {
      print('物理删除文件失败: ${audioFile.filePath}, 错误: $e');
    }
  }

  /// 更新文件状态为已清理
  Future<void> _updateFileAsCleaned(String audioFileId) async {
    // 这里应该更新数据库记录
    // 可以选择物理删除记录或标记为已清理
    print('更新文件状态为已清理: $audioFileId');
  }

  /// 清理临时文件
  Future<void> _cleanupPendingFile(String pendingPath) async {
    try {
      final file = File(pendingPath);
      if (await file.exists()) {
        await file.delete();
        print('清理临时文件: $pendingPath');
      }
    } catch (e) {
      print('清理临时文件失败: $pendingPath, 错误: $e');
    }
  }

  /// 启动定期清理定时器
  void _startCleanupTimer() {
    // 每30分钟执行一次清理
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      cleanupDeletedFiles();
    });
  }

  /// 手动触发清理
  Future<void> triggerCleanup() async {
    await cleanupDeletedFiles();
  }

  /// 获取文件统计信息
  Future<Map<String, dynamic>> getFileStats() async {
    try {
      final docsDir = await _documentsDirectory;
      final dataDir = Directory(join(docsDir.path, 'data'));

      int totalFiles = 0;
      int pendingFiles = 0;
      int activeFiles = 0;
      int deletedFiles = 0;
      int totalSize = 0;

      if (await dataDir.exists()) {
        final dateDirs = dataDir.listSync();
        for (final dateDir in dateDirs) {
          if (dateDir is Directory) {
            // 统计pending文件
            final pendingDir = Directory(join(dateDir.path, 'pending'));
            if (await pendingDir.exists()) {
              final files = pendingDir.listSync();
              for (final file in files) {
                if (file is File) {
                  pendingFiles++;
                  totalSize += await file.length();
                }
              }
            }

            // 统计audio文件
            final audioDir = Directory(join(dateDir.path, 'audio'));
            if (await audioDir.exists()) {
              final files = audioDir.listSync();
              for (final file in files) {
                if (file is File) {
                  activeFiles++;
                  totalSize += await file.length();
                }
              }
            }
          }
        }
      }

      totalFiles = pendingFiles + activeFiles + deletedFiles;

      return {
        'totalFiles': totalFiles,
        'pendingFiles': pendingFiles,
        'activeFiles': activeFiles,
        'deletedFiles': deletedFiles,
        'totalSize': totalSize,
      };
    } catch (e) {
      print('获取文件统计信息失败: $e');
      return {
        'totalFiles': 0,
        'pendingFiles': 0,
        'activeFiles': 0,
        'deletedFiles': 0,
        'totalSize': 0,
      };
    }
  }
}
