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
