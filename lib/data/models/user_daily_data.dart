class UserDailyData {
  final String id; // 格式：20250815
  final String nickname;
  final String slogan;
  final String? avatarPath; // 头像文件路径，null表示使用默认头像
  final String? backgroundPath; // 背景图片路径，null表示使用默认背景
  final int steps; // 今日步数
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEditable; // 是否允许编辑

  UserDailyData({
    required this.id,
    required this.nickname,
    required this.slogan,
    this.avatarPath,
    this.backgroundPath,
    required this.steps,
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.isEditable = true, // 默认允许编辑
  });

  factory UserDailyData.create({
    required String nickname,
    required String slogan,
    String? avatarPath,
    String? backgroundPath,
    required int steps,
    required DateTime date,
    bool isEditable = true,
  }) {
    final now = DateTime.now();
    final id =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return UserDailyData(
      id: id,
      nickname: nickname,
      slogan: slogan,
      avatarPath: avatarPath,
      backgroundPath: backgroundPath,
      steps: steps,
      date: date,
      createdAt: now,
      updatedAt: now,
      isEditable: isEditable,
    );
  }

  UserDailyData copyWith({
    String? nickname,
    String? slogan,
    String? avatarPath,
    String? backgroundPath,
    int? steps,
    DateTime? updatedAt,
    bool? isEditable,
  }) {
    return UserDailyData(
      id: id,
      nickname: nickname ?? this.nickname,
      slogan: slogan ?? this.slogan,
      avatarPath: avatarPath ?? this.avatarPath,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      steps: steps ?? this.steps,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isEditable: isEditable ?? this.isEditable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'slogan': slogan,
      'avatar_path': avatarPath,
      'background_path': backgroundPath,
      'steps': steps,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_editable': isEditable ? 1 : 0,
    };
  }

  factory UserDailyData.fromJson(Map<String, dynamic> json) {
    return UserDailyData(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      slogan: json['slogan'] as String,
      avatarPath: json['avatar_path'] as String?,
      backgroundPath: json['background_path'] as String?,
      steps: json['steps'] as int,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isEditable: (json['is_editable'] as int?) == 1,
    );
  }

  // 获取默认头像路径
  static String get defaultAvatarPath => 'assets/images/default_avatar.jpg';

  // 获取默认背景路径
  static String get defaultBackgroundPath =>
      'assets/images/default_background.jpg';

  // 获取实际头像路径（如果为空则返回默认路径）
  String get effectiveAvatarPath => avatarPath ?? defaultAvatarPath;

  // 获取实际背景路径（如果为空则返回默认路径）
  String get effectiveBackgroundPath => backgroundPath ?? defaultBackgroundPath;
}
