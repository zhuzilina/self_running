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

class ImageInfo {
  final String originalPath; // 原图文件路径
  final String thumbnailPath; // 缩略图文件路径
  final String originalName; // 原始文件名
  final DateTime createdAt; // 创建时间

  ImageInfo({
    required this.originalPath,
    required this.thumbnailPath,
    required this.originalName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'thumbnailPath': thumbnailPath,
      'originalName': originalName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      originalPath: json['originalPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      originalName: json['originalName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ImageInfo copyWith({
    String? originalPath,
    String? thumbnailPath,
    String? originalName,
    DateTime? createdAt,
  }) {
    return ImageInfo(
      originalPath: originalPath ?? this.originalPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      originalName: originalName ?? this.originalName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
