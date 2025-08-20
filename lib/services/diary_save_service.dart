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

/// 日记保存数据模型
class DiarySaveData {
  final String content;
  final List<Uint8List> imageDataList;
  final List<AudioFile> audioFiles;
  final bool isUpdate; // 是否是更新现有日记
  final String todayId; // 今日ID

  DiarySaveData({
    required this.content,
    required this.imageDataList,
    required this.audioFiles,
    required this.isUpdate,
    required this.todayId,
  });
}

/// 日记保存结果模型
class DiarySaveResult {
  final bool success;
  final String? error;
  final List<ImageInfo>? savedImages; // 保存的图片信息
  final List<AudioFile>? savedAudioFiles; // 保存的音频文件

  DiarySaveResult({
    required this.success,
    this.error,
    this.savedImages,
    this.savedAudioFiles,
  });
}

/// Isolate消息模型
class _IsolateMessage {
  final SendPort sendPort;
  final DiarySaveData saveData;

  _IsolateMessage({required this.sendPort, required this.saveData});
}

/// 日记保存服务 - 在isolate中运行
class DiarySaveService {
  static const String _isolateName = 'diary_save_isolate';

  /// 在后台isolate中保存日记
  static Future<DiarySaveResult> saveDiaryInBackground(
    DiarySaveData saveData,
  ) async {
    try {
      // 创建isolate
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _saveDiaryIsolate,
        _IsolateMessage(sendPort: receivePort.sendPort, saveData: saveData),
      );

      // 等待结果
      final result = await receivePort.first as DiarySaveResult;

      // 清理isolate
      isolate.kill();

      return result;
    } catch (e) {
      return DiarySaveResult(success: false, error: '启动后台保存失败: $e');
    }
  }

  /// 在isolate中执行的保存逻辑
  @pragma('vm:entry-point')
  static Future<void> _saveDiaryIsolate(_IsolateMessage message) async {
    try {
      final result = await _performSave(message.saveData);
      message.sendPort.send(result);
    } catch (e) {
      message.sendPort.send(
        DiarySaveResult(success: false, error: '保存过程中发生错误: $e'),
      );
    }
  }

  /// 执行实际的保存操作
  static Future<DiarySaveResult> _performSave(DiarySaveData saveData) async {
    try {
      // 初始化文件存储服务
      final fileStorageService = FileStorageService.instance;
      final audioFileManager = AudioFileManager.instance;

      // 保存图片（原图 + 缩略图）
      final List<ImageInfo> savedImages = [];
      for (int i = 0; i < saveData.imageDataList.length; i++) {
        final imageData = saveData.imageDataList[i];
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

      // 处理音频文件
      final List<AudioFile> savedAudioFiles = [];
      for (int i = 0; i < saveData.audioFiles.length; i++) {
        final audioFile = saveData.audioFiles[i];
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

      return DiarySaveResult(
        success: true,
        savedImages: savedImages,
        savedAudioFiles: savedAudioFiles,
      );
    } catch (e) {
      return DiarySaveResult(success: false, error: '保存文件失败: $e');
    }
  }
}
