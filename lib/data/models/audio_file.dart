enum AudioFileStatus {
  pending, // 临时状态，文件已写入但未确认
  active, // 正常状态，文件可用
  deleted, // 已删除状态，等待物理清理
}

class AudioFile {
  final String id; // 唯一标识（文件名hash）
  final String displayName; // 显示名称（限制6个字符）
  final String filePath; // 文件路径
  final int duration; // 时长（毫秒）
  final DateTime recordTime; // 录音时间
  final AudioFileStatus status; // 文件状态
  final DateTime? deletedAt; // 删除时间
  final DateTime createdAt; // 创建时间
  final DateTime updatedAt; // 更新时间

  AudioFile({
    required this.id,
    required this.displayName,
    required this.filePath,
    required this.duration,
    required this.recordTime,
    this.status = AudioFileStatus.active,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(displayName.length <= 6, '显示名称不能超过6个字符');

  factory AudioFile.create({
    required String displayName,
    required String filePath,
    required int duration,
    required DateTime recordTime,
  }) {
    final now = DateTime.now();
    // 从文件路径生成唯一标识（文件名hash）
    final fileName = filePath.split('/').last;
    final id = fileName.split('.').first; // 去掉扩展名

    // 限制显示名称长度为6个字符
    final limitedDisplayName = displayName.length > 6
        ? displayName.substring(0, 6)
        : displayName;

    return AudioFile(
      id: id,
      displayName: limitedDisplayName,
      filePath: filePath,
      duration: duration,
      recordTime: recordTime,
      status: AudioFileStatus.pending, // 初始状态为pending
      createdAt: now,
      updatedAt: now,
    );
  }

  AudioFile copyWith({
    String? id,
    String? displayName,
    String? filePath,
    int? duration,
    DateTime? recordTime,
    AudioFileStatus? status,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    // 限制显示名称长度为6个字符
    final limitedDisplayName = displayName != null && displayName.length > 6
        ? displayName.substring(0, 6)
        : displayName ?? this.displayName;

    return AudioFile(
      id: id ?? this.id,
      displayName: limitedDisplayName,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      recordTime: recordTime ?? this.recordTime,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // 标记为已删除
  AudioFile markAsDeleted() {
    return copyWith(status: AudioFileStatus.deleted, deletedAt: DateTime.now());
  }

  // 标记为激活状态
  AudioFile markAsActive() {
    return copyWith(status: AudioFileStatus.active);
  }

  // 检查文件是否可用
  bool get isActive => status == AudioFileStatus.active;
  bool get isPending => status == AudioFileStatus.pending;
  bool get isDeleted => status == AudioFileStatus.deleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'filePath': filePath,
      'duration': duration,
      'recordTime': recordTime.toIso8601String(),
      'status': status.name,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as String;
    // 确保从JSON加载时也限制长度
    final limitedDisplayName = displayName.length > 6
        ? displayName.substring(0, 6)
        : displayName;

    return AudioFile(
      id: json['id'] as String,
      displayName: limitedDisplayName,
      filePath: json['filePath'] as String,
      duration: json['duration'] as int,
      recordTime: DateTime.parse(json['recordTime'] as String),
      status: AudioFileStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AudioFileStatus.active,
      ),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
