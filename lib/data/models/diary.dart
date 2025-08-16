import 'audio_file.dart';

class Diary {
  final String id;
  final String content;
  final List<String> imagePaths;
  final List<AudioFile> audioFiles; // 使用新的AudioFile模型
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEditable; // 是否允许修改

  Diary({
    required this.id,
    required this.content,
    this.imagePaths = const [],
    this.audioFiles = const [], // 使用AudioFile列表
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.isEditable = true, // 默认允许修改
  });

  factory Diary.create({
    required String content,
    required DateTime date,
    List<String> imagePaths = const [],
    List<AudioFile> audioFiles = const [], // 使用AudioFile列表
    bool isEditable = true,
  }) {
    final now = DateTime.now();
    return Diary(
      id: '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}', // 使用YYYYMMDD格式
      content: content,
      imagePaths: imagePaths,
      audioFiles: audioFiles,
      date: date,
      createdAt: now,
      updatedAt: now,
      isEditable: isEditable,
    );
  }

  Diary copyWith({
    String? content,
    List<String>? imagePaths,
    List<AudioFile>? audioFiles, // 使用AudioFile列表
    DateTime? updatedAt,
    bool? isEditable,
  }) {
    return Diary(
      id: id,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
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
      'imagePaths': imagePaths,
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
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
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
}
