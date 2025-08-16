import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FileStorageService {
  static FileStorageService? _instance;

  FileStorageService._();

  static FileStorageService get instance {
    _instance ??= FileStorageService._();
    return _instance!;
  }

  /// 获取应用文档目录
  Future<Directory> get _documentsDirectory async {
    return await getApplicationDocumentsDirectory();
  }

  /// 获取指定日期的文件存储目录
  /// 目录结构: /data/20250816/
  Future<Directory> _getDateDirectory(String dateId) async {
    final docsDir = await _documentsDirectory;
    // 直接使用dateId作为目录名，如20250816
    final dateDir = Directory(join(docsDir.path, 'data', dateId));
    if (!await dateDir.exists()) {
      await dateDir.create(recursive: true);
    }
    return dateDir;
  }

  /// 获取图片存储目录（按日期组织）
  /// 目录结构: /data/20250816/images/
  Future<Directory> getImagesDirectory(String dateId) async {
    final dateDir = await _getDateDirectory(dateId);
    final imagesDir = Directory(join(dateDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// 获取音频存储目录（按日期组织）
  /// 目录结构: /data/20250816/audio/
  Future<Directory> getAudioDirectory(String dateId) async {
    final dateDir = await _getDateDirectory(dateId);
    final audioDir = Directory(join(dateDir.path, 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// 生成文件的MD5 hash编码（32字符）
  String _generateHash(Uint8List data, String extension) {
    final hash = md5.convert(data);
    return '${hash.toString()}.$extension';
  }

  /// 直接保存图片到指定日期的目录
  /// 使用MD5 hash文件名保存，确保唯一性
  Future<String?> saveImageDirectly(
    Uint8List imageData,
    String originalName,
    String dateId,
  ) async {
    try {
      final imagesDir = await getImagesDirectory(dateId);
      final fileExtension = extension(originalName).replaceAll('.', '');
      final fileName = _generateHash(imageData, fileExtension);
      final filePath = join(imagesDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(imageData);

      return filePath;
    } catch (e) {
      print('直接保存图片失败: $e');
      return null;
    }
  }

  /// 直接保存音频到指定日期的目录
  /// 使用MD5 hash文件名保存，确保唯一性
  Future<String?> saveAudioDirectly(
    String sourcePath,
    String originalName,
    String dateId,
  ) async {
    try {
      print('直接保存音频文件: $sourcePath 到日期目录: $dateId');

      final audioDir = await getAudioDirectory(dateId);
      final fileExtension = extension(originalName).replaceAll('.', '');

      // 检查源文件是否存在
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('源音频文件不存在: $sourcePath');
        return null;
      }

      print('源文件存在，文件大小: ${await sourceFile.length()} bytes');

      // 读取源文件数据
      final audioData = await sourceFile.readAsBytes();
      print('读取音频数据成功，大小: ${audioData.length} bytes');

      final fileName = _generateHash(audioData, fileExtension);
      final targetPath = join(audioDir.path, fileName);

      print('目标路径: $targetPath');

      // 复制文件到目标位置
      await sourceFile.copy(targetPath);

      print('音频文件直接保存成功: $targetPath');
      return targetPath;
    } catch (e) {
      print('直接保存音频失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      return null;
    }
  }

  /// 清理指定日期目录中未使用的文件
  Future<void> cleanupUnusedFiles(
    String dateId,
    List<String> usedFilePaths,
  ) async {
    try {
      final imagesDir = await getImagesDirectory(dateId);
      final audioDir = await getAudioDirectory(dateId);

      // 清理图片文件
      await _cleanupDirectory(imagesDir, usedFilePaths);

      // 清理音频文件
      await _cleanupDirectory(audioDir, usedFilePaths);
    } catch (e) {
      print('清理未使用文件失败: $e');
    }
  }

  Future<void> _cleanupDirectory(
    Directory directory,
    List<String> usedFilePaths,
  ) async {
    try {
      final files = directory.listSync();
      for (final file in files) {
        if (file is File) {
          if (!usedFilePaths.contains(file.path)) {
            await file.delete();
            print('删除未使用的文件: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('清理目录失败: $e');
    }
  }

  /// 获取存储统计信息
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final docsDir = await _documentsDirectory;
      int totalImageCount = 0;
      int totalImageSize = 0;
      int totalAudioCount = 0;
      int totalAudioSize = 0;

      // 遍历data目录下的所有日期目录
      final dataDir = Directory(join(docsDir.path, 'data'));
      if (await dataDir.exists()) {
        final dateDirs = dataDir.listSync();
        for (final dateDir in dateDirs) {
          if (dateDir is Directory) {
            // 统计图片
            final imagesDir = Directory(join(dateDir.path, 'images'));
            if (await imagesDir.exists()) {
              final imageFiles = imagesDir.listSync();
              for (final file in imageFiles) {
                if (file is File) {
                  totalImageCount++;
                  totalImageSize += await file.length();
                }
              }
            }

            // 统计音频
            final audioDir = Directory(join(dateDir.path, 'audio'));
            if (await audioDir.exists()) {
              final audioFiles = audioDir.listSync();
              for (final file in audioFiles) {
                if (file is File) {
                  totalAudioCount++;
                  totalAudioSize += await file.length();
                }
              }
            }
          }
        }
      }

      return {
        'imageCount': totalImageCount,
        'imageSize': totalImageSize,
        'audioCount': totalAudioCount,
        'audioSize': totalAudioSize,
        'totalSize': totalImageSize + totalAudioSize,
      };
    } catch (e) {
      return {
        'imageCount': 0,
        'imageSize': 0,
        'audioCount': 0,
        'audioSize': 0,
        'totalSize': 0,
      };
    }
  }

  // 保留旧方法以保持兼容性
  Future<Directory> get _imagesDirectory async {
    final docsDir = await _documentsDirectory;
    final imagesDir = Directory(join(docsDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  Future<Directory> get _audioDirectory async {
    final docsDir = await _documentsDirectory;
    final audioDir = Directory(join(docsDir.path, 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  Future<String?> saveImage(Uint8List imageData, String originalName) async {
    try {
      final imagesDir = await _imagesDirectory;
      final fileExtension = extension(originalName).replaceAll('.', '');
      final fileName = _generateHash(imageData, fileExtension);
      final filePath = join(imagesDir.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(imageData);

      return filePath;
    } catch (e) {
      print('保存图片失败: $e');
      return null;
    }
  }

  Future<String?> saveAudio(String sourcePath, String originalName) async {
    try {
      print('开始保存音频文件: $sourcePath');

      final audioDir = await _audioDirectory;
      final fileExtension = extension(originalName).replaceAll('.', '');

      // 检查源文件是否存在
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('源音频文件不存在: $sourcePath');
        return null;
      }

      print('源文件存在，文件大小: ${await sourceFile.length()} bytes');

      // 读取源文件数据
      final audioData = await sourceFile.readAsBytes();
      print('读取音频数据成功，大小: ${audioData.length} bytes');

      final fileName = _generateHash(audioData, fileExtension);
      final targetPath = join(audioDir.path, fileName);

      print('目标路径: $targetPath');

      // 复制文件到目标位置
      await sourceFile.copy(targetPath);

      print('音频文件保存成功: $targetPath');
      return targetPath;
    } catch (e) {
      print('保存音频失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      return null;
    }
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除文件失败: $e');
      return false;
    }
  }

  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
