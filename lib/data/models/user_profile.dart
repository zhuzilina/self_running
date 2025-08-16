class UserProfile {
  final String? avatar;
  final String nickname;
  final String slogan;
  final String? coverImage;
  final DateTime? lastUpdated;

  const UserProfile({
    this.avatar,
    required this.nickname,
    required this.slogan,
    this.coverImage,
    this.lastUpdated,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      nickname: '吃个炸鸡',
      slogan: '无忧无虑又一天',
      avatar: 'assets/images/avatar.jpg',
      coverImage: 'assets/images/user_bg.jpg',
      lastUpdated: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? avatar,
    String? nickname,
    String? slogan,
    String? coverImage,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      avatar: avatar ?? this.avatar,
      nickname: nickname ?? this.nickname,
      slogan: slogan ?? this.slogan,
      coverImage: coverImage ?? this.coverImage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar,
      'nickname': nickname,
      'slogan': slogan,
      'coverImage': coverImage,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      avatar: json['avatar'],
      nickname: json['nickname'] ?? '吃个炸鸡',
      slogan: json['slogan'] ?? '无忧无虑又一天',
      coverImage: json['coverImage'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }
}
