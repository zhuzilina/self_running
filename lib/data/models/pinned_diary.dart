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
