class PinnedDiary {
  final int id;
  final int diaryId;
  final DateTime pinnedAt;

  PinnedDiary({
    required this.id,
    required this.diaryId,
    required this.pinnedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diaryId': diaryId,
      'pinnedAt': pinnedAt.millisecondsSinceEpoch,
    };
  }

  factory PinnedDiary.fromMap(Map<String, dynamic> map) {
    return PinnedDiary(
      id: map['id'],
      diaryId: map['diaryId'],
      pinnedAt: DateTime.fromMillisecondsSinceEpoch(map['pinnedAt']),
    );
  }
}
