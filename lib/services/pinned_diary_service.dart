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

import '../data/models/pinned_diary.dart';
import '../data/models/diary.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class PinnedDiaryService {
  final DatabaseService _databaseService;

  PinnedDiaryService(this._databaseService);

  Future<void> init() async {
    await _createPinnedDiaryTable();
  }

  Future<void> _createPinnedDiaryTable() async {
    final db = await _databaseService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pinned_diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diaryId INTEGER NOT NULL,
        pinnedAt INTEGER NOT NULL,
        UNIQUE(diaryId)
      )
    ''');
  }

  Future<void> pinDiary(int diaryId) async {
    final db = await _databaseService.database;
    await db.insert('pinned_diaries', {
      'diaryId': diaryId,
      'pinnedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unpinDiary(int diaryId) async {
    final db = await _databaseService.database;
    await db.delete(
      'pinned_diaries',
      where: 'diaryId = ?',
      whereArgs: [diaryId],
    );
  }

  Future<List<PinnedDiary>> getPinnedDiaries() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pinned_diaries',
      orderBy: 'pinnedAt DESC',
    );
    return List.generate(maps.length, (i) => PinnedDiary.fromMap(maps[i]));
  }

  Future<List<Diary>> getPinnedDiariesWithData() async {
    final pinnedDiaries = await getPinnedDiaries();
    final List<Diary> result = [];

    for (final pinnedDiary in pinnedDiaries) {
      final diary = await _databaseService.getDiary(
        pinnedDiary.diaryId.toString(),
      );
      if (diary != null) {
        result.add(diary);
      }
    }

    return result;
  }

  Future<bool> isDiaryPinned(int diaryId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pinned_diaries',
      where: 'diaryId = ?',
      whereArgs: [diaryId],
    );
    return maps.isNotEmpty;
  }
}
