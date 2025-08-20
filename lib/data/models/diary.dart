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

import 'audio_file.dart';
import 'image_info.dart';

class Diary {
  final String id;
  final String content;
  final List<ImageInfo> images; // 使用ImageInfo列表
  final List<AudioFile> audioFiles; // 使用新的AudioFile模型
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEditable; // 是否允许修改

  Diary({
    required this.id,
    required this.content,
    this.images = const [], // 使用ImageInfo列表
    this.audioFiles = const [], // 使用AudioFile列表
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.isEditable = true, // 默认允许修改
  });

  factory Diary.create({
    required String content,
    required DateTime date,
    List<ImageInfo> images = const [],
    List<AudioFile> audioFiles = const [], // 使用AudioFile列表
    bool isEditable = true,
  }) {
    final now = DateTime.now();
    return Diary(
      id: '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}', // 使用YYYYMMDD格式
      content: content,
      images: images,
      audioFiles: audioFiles,
      date: date,
      createdAt: now,
      updatedAt: now,
      isEditable: isEditable,
    );
  }

  Diary copyWith({
    String? content,
    List<ImageInfo>? images,
    List<AudioFile>? audioFiles, // 使用AudioFile列表
    DateTime? updatedAt,
    bool? isEditable,
  }) {
    return Diary(
      id: id,
      content: content ?? this.content,
      images: images ?? this.images,
      audioFiles: audioFiles ?? this.audioFiles,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isEditable: isEditable ?? this.isEditable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'images': images
          .map((image) => image.toJson())
          .toList(), // 序列化ImageInfo列表
      'audioFiles': audioFiles
          .map((audio) => audio.toJson())
          .toList(), // 序列化AudioFile列表
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEditable': isEditable,
    };
  }

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'] as String,
      content: json['content'] as String,
      images: (json['images'] as List<dynamic>? ?? [])
          .map(
            (imageJson) =>
                ImageInfo.fromJson(imageJson as Map<String, dynamic>),
          )
          .toList(), // 反序列化ImageInfo列表
      audioFiles: (json['audioFiles'] as List<dynamic>? ?? [])
          .map(
            (audioJson) =>
                AudioFile.fromJson(audioJson as Map<String, dynamic>),
          )
          .toList(), // 反序列化AudioFile列表
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isEditable: json['isEditable'] as bool? ?? true,
    );
  }

  // 兼容性方法：获取音频路径列表
  List<String> get audioPaths =>
      audioFiles.map((audio) => audio.filePath).toList();

  // 兼容性方法：获取音频名称列表
  List<String> get audioNames =>
      audioFiles.map((audio) => audio.displayName).toList();

  // 兼容性方法：获取音频时长列表
  List<int> get audioDurations =>
      audioFiles.map((audio) => audio.duration).toList();

  // 兼容性方法：获取图片路径列表（原图）
  List<String> get imagePaths =>
      images.map((image) => image.originalPath).toList();

  // 兼容性方法：获取缩略图路径列表
  List<String> get thumbnailPaths =>
      images.map((image) => image.thumbnailPath).toList();
}
