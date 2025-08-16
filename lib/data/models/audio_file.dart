class AudioFile {
  final String id; // 唯一标识（文件名）
  final String displayName; // 显示名称
  final String filePath; // 文件路径
  final int duration; // 时长（毫秒）
  final DateTime recordTime; // 录音时间

  AudioFile({
    required this.id,
    required this.displayName,
    required this.filePath,
    required this.duration,
    required this.recordTime,
  });

  factory AudioFile.create({
    required String displayName,
    required String filePath,
    required int duration,
    required DateTime recordTime,
  }) {
    // 从文件路径生成唯一标识（文件名）
    final fileName = filePath.split('/').last;
    final id = fileName.split('.').first; // 去掉扩展名

    return AudioFile(
      id: id,
      displayName: displayName,
      filePath: filePath,
      duration: duration,
      recordTime: recordTime,
    );
  }

  AudioFile copyWith({
    String? id,
    String? displayName,
    String? filePath,
    int? duration,
    DateTime? recordTime,
  }) {
    return AudioFile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      recordTime: recordTime ?? this.recordTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'filePath': filePath,
      'duration': duration,
      'recordTime': recordTime.toIso8601String(),
    };
  }

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      filePath: json['filePath'] as String,
      duration: json['duration'] as int,
      recordTime: DateTime.parse(json['recordTime'] as String),
    );
  }
}

