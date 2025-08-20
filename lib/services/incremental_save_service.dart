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

import 'dart:isolate';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/models/audio_file.dart';
import '../data/models/image_info.dart';
import 'file_storage_service.dart';
import 'audio_file_manager.dart';

/// 增量保存数据模型
class IncrementalSaveData {
  final String? newContent; // 新的文本内容（如果为null表示没有变化）
  final List<Uint8List>? newImages; // 新增的图片（如果为null表示没有变化）
  final List<int>? removedImageIndices; // 删除的图片索引
  final List<AudioFile>? newAudioFiles; // 新增的音频文件
  final List<int>? removedAudioIndices; // 删除的音频索引
  final Map<int, String>? updatedAudioNames; // 更新的音频名称 {index: newName}
  final String todayId; // 今日ID
  final bool isUpdate; // 是否是更新现有日记

  IncrementalSaveData({
    this.newContent,
    this.newImages,
    this.removedImageIndices,
    this.newAudioFiles,
    this.removedAudioIndices,
    this.updatedAudioNames,
    required this.todayId,
    required this.isUpdate,
  });

  /// 检查是否有任何变化
  bool get hasChanges {
    return newContent != null ||
        newImages != null ||
        removedImageIndices != null ||
        newAudioFiles != null ||
        removedAudioIndices != null ||
        updatedAudioNames != null;
  }
}

/// 增量保存结果模型
class IncrementalSaveResult {
  final bool success;
  final String? error;
  final List<ImageInfo>? savedImages; // 保存的图片信息
  final List<AudioFile>? savedAudioFiles; // 保存的音频文件
  final List<String>? removedImagePaths; // 删除的图片路径
  final List<String>? removedAudioPaths; // 删除的音频路径

  IncrementalSaveResult({
    required this.success,
    this.error,
    this.savedImages,
    this.savedAudioFiles,
    this.removedImagePaths,
    this.removedAudioPaths,
  });
}

/// Isolate消息模型
class _IsolateMessage {
  final SendPort sendPort;
  final IncrementalSaveData saveData;

  _IsolateMessage({required this.sendPort, required this.saveData});
}

/// 增量保存服务 - 在isolate中运行
class IncrementalSaveService {
  static const String _isolateName = 'incremental_save_isolate';

  /// 在后台isolate中执行增量保存
  static Future<IncrementalSaveResult> saveIncrementalInBackground(
    IncrementalSaveData saveData,
  ) async {
    try {
      // 创建isolate
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _saveIncrementalIsolate,
        _IsolateMessage(sendPort: receivePort.sendPort, saveData: saveData),
      );

      // 等待结果
      final result = await receivePort.first as IncrementalSaveResult;

      // 清理isolate
      isolate.kill();

      return result;
    } catch (e) {
      return IncrementalSaveResult(success: false, error: '启动增量保存失败: $e');
    }
  }

  /// 在isolate中执行的增量保存逻辑
  @pragma('vm:entry-point')
  static Future<void> _saveIncrementalIsolate(_IsolateMessage message) async {
    try {
      final result = await _performIncrementalSave(message.saveData);
      message.sendPort.send(result);
    } catch (e) {
      message.sendPort.send(
        IncrementalSaveResult(success: false, error: '增量保存过程中发生错误: $e'),
      );
    }
  }

  /// 执行实际的增量保存操作
  static Future<IncrementalSaveResult> _performIncrementalSave(
    IncrementalSaveData saveData,
  ) async {
    try {
      // 初始化文件存储服务
      final fileStorageService = FileStorageService.instance;
      final audioFileManager = AudioFileManager.instance;

      final List<ImageInfo> savedImages = [];
      final List<AudioFile> savedAudioFiles = [];
      final List<String> removedImagePaths = [];
      final List<String> removedAudioPaths = [];

      // 处理新增图片
      if (saveData.newImages != null && saveData.newImages!.isNotEmpty) {
        for (int i = 0; i < saveData.newImages!.length; i++) {
          final imageData = saveData.newImages![i];
          final imagePaths = await fileStorageService.saveImageWithThumbnail(
            imageData,
            'diary_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            saveData.todayId,
          );

          if (imagePaths != null) {
            savedImages.add(
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
      }

      // 处理删除的图片
      if (saveData.removedImageIndices != null) {
        // 这里需要从现有日记中获取图片路径进行删除
        // 实际实现中需要传入现有图片信息
        for (final index in saveData.removedImageIndices!) {
          // 标记图片文件为删除状态
          // 实际删除操作在数据库更新后进行
        }
      }

      // 处理新增音频文件
      if (saveData.newAudioFiles != null &&
          saveData.newAudioFiles!.isNotEmpty) {
        for (int i = 0; i < saveData.newAudioFiles!.length; i++) {
          final audioFile = saveData.newAudioFiles![i];
          final sourceFile = File(audioFile.filePath);

          if (await sourceFile.exists()) {
            // 检查是否是临时录音文件（新录制的）
            if (audioFile.filePath.contains('/tmp/') ||
                audioFile.filePath.contains('cache')) {
              // 新录制的音频文件，需要保存到永久位置
              final savedAudioPath = await fileStorageService.saveAudioDirectly(
                audioFile.filePath,
                'diary_audio_${DateTime.now().millisecondsSinceEpoch}_$i.m4a',
                saveData.todayId,
              );
              if (savedAudioPath != null) {
                // 创建新的AudioFile对象，使用保存后的路径
                final savedAudioFile = AudioFile.create(
                  displayName: audioFile.displayName,
                  filePath: savedAudioPath,
                  duration: audioFile.duration,
                  recordTime: audioFile.recordTime,
                );
                savedAudioFiles.add(savedAudioFile);
              }
            } else {
              // 已存在的音频文件，直接使用
              savedAudioFiles.add(audioFile);
            }
          }
        }
      }

      // 处理删除的音频文件
      if (saveData.removedAudioIndices != null) {
        // 这里需要从现有日记中获取音频路径进行删除
        // 实际实现中需要传入现有音频信息
        for (final index in saveData.removedAudioIndices!) {
          // 标记音频文件为删除状态
          // 实际删除操作在数据库更新后进行
        }
      }

      // 处理更新的音频名称
      if (saveData.updatedAudioNames != null) {
        // 音频名称更新不需要文件操作，只需要在数据库中更新
        // 这里可以记录需要更新的音频信息
      }

      return IncrementalSaveResult(
        success: true,
        savedImages: savedImages.isNotEmpty ? savedImages : null,
        savedAudioFiles: savedAudioFiles.isNotEmpty ? savedAudioFiles : null,
        removedImagePaths: removedImagePaths.isNotEmpty
            ? removedImagePaths
            : null,
        removedAudioPaths: removedAudioPaths.isNotEmpty
            ? removedAudioPaths
            : null,
      );
    } catch (e) {
      return IncrementalSaveResult(success: false, error: '增量保存文件失败: $e');
    }
  }
}
