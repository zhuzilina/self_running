import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/user_daily_data.dart';
import '../data/models/diary.dart';
import '../data/models/audio_file.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'self_running.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 用户每日数据表
    await db.execute('''
      CREATE TABLE user_daily_data (
        id TEXT PRIMARY KEY,
        nickname TEXT,
        slogan TEXT,
        avatar_path TEXT,
        background_path TEXT,
        steps INTEGER DEFAULT 0,
        date TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 日记表
    await db.execute('''
      CREATE TABLE diaries (
        id TEXT PRIMARY KEY,
        content TEXT,
        image_paths TEXT,
        audio_files TEXT, -- 存储AudioFile的JSON数组
        date TEXT,
        is_editable INTEGER DEFAULT 1, -- 是否允许修改，1为允许，0为不允许
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加date字段到user_daily_data表
      await db.execute('ALTER TABLE user_daily_data ADD COLUMN date TEXT');
    }
    if (oldVersion < 3) {
      // 添加date和is_editable字段到diaries表
      await db.execute('ALTER TABLE diaries ADD COLUMN date TEXT');
      await db.execute(
        'ALTER TABLE diaries ADD COLUMN is_editable INTEGER DEFAULT 1',
      );
    }
  }

  // UserDailyData CRUD 操作
  Future<void> saveUserDailyData(UserDailyData userData) async {
    final db = await database;
    await db.insert(
      'user_daily_data',
      userData.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserDailyData?> getUserDailyData(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_daily_data',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return UserDailyData.fromJson(maps.first);
  }

  Future<void> updateUserDailyData(UserDailyData userData) async {
    final db = await database;
    await db.update(
      'user_daily_data',
      userData.toJson(),
      where: 'id = ?',
      whereArgs: [userData.id],
    );
  }

  Future<void> updateSteps(String id, int steps) async {
    final db = await database;
    await db.update(
      'user_daily_data',
      {'steps': steps, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserDailyData>> getAllUserDailyData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_daily_data');
    return List.generate(maps.length, (i) => UserDailyData.fromJson(maps[i]));
  }

  Future<void> deleteUserDailyData(String id) async {
    final db = await database;
    await db.delete('user_daily_data', where: 'id = ?', whereArgs: [id]);
  }

  // Diary CRUD 操作
  Future<void> saveDiary(Diary diary) async {
    final db = await database;
    await db.insert('diaries', {
      'id': diary.id,
      'content': diary.content,
      'image_paths': diary.imagePaths.join(','),
      'audio_files': jsonEncode(
        diary.audioFiles.map((audio) => audio.toJson()).toList(),
      ), // 序列化AudioFile列表
      'date': diary.date.toIso8601String(),
      'is_editable': diary.isEditable ? 1 : 0,
      'created_at': diary.createdAt.toIso8601String(),
      'updated_at': diary.updatedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Diary?> getDiary(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diaries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _rowToDiary(maps.first);
  }

  Future<List<Diary>> getAllDiaries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('diaries');
    return List.generate(maps.length, (i) => _rowToDiary(maps[i]));
  }

  Future<void> deleteDiary(String id) async {
    final db = await database;
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  Future<UserDailyData?> getUserDailyDataWithDiary(String id) async {
    final userData = await getUserDailyData(id);
    if (userData == null) return null;

    final diary = await getDiary(id);
    // 这里可以返回包含日记的用户数据，或者分别处理
    return userData;
  }

  Diary _rowToDiary(Map<String, dynamic> row) {
    // 反序列化AudioFile列表
    List<AudioFile> audioFiles = [];
    try {
      final audioFilesJson = row['audio_files'] as String? ?? '[]';
      final audioFilesList = jsonDecode(audioFilesJson) as List<dynamic>;
      audioFiles = audioFilesList
          .map(
            (audioJson) =>
                AudioFile.fromJson(audioJson as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('反序列化音频文件失败: $e');
      audioFiles = [];
    }

    final date = row['date'] != null
        ? DateTime.parse(row['date'] as String)
        : DateTime.parse(row['created_at'] as String);

    final isEditable = (row['is_editable'] as int?) == 1;

    return Diary(
      id: row['id'].toString(),
      content: row['content'] as String? ?? '',
      imagePaths: (row['image_paths'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      audioFiles: audioFiles, // 使用反序列化的AudioFile列表
      date: date,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      isEditable: isEditable,
    );
  }
}
