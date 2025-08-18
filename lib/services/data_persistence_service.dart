import 'dart:typed_data';
import '../data/models/user_daily_data.dart';
import '../data/models/diary.dart';
import '../data/models/audio_file.dart';
import 'database_service.dart';
import 'user_profile_service.dart';
import 'diary_service.dart';
import 'user_daily_data_service.dart';
import 'storage_service.dart';

/// 数据持久化服务
/// 统一管理预保存、智能保存和日期检查逻辑
class DataPersistenceService {
  static final DataPersistenceService _instance =
      DataPersistenceService._internal();
  factory DataPersistenceService() => _instance;
  DataPersistenceService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final UserDailyDataService _userDailyDataService = UserDailyDataService();
  final DiaryService _diaryService = DiaryService();
  UserProfileService? _userProfileService;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final storageService = StorageService();
    await storageService.init();
    _userProfileService = UserProfileService(storageService);
    await _userProfileService!.init();
    _initialized = true;
  }

  /// 预保存用户数据（立即保存，不检查日期）
  Future<void> preSaveUserData({
    required String nickname,
    required String slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    required int steps,
  }) async {
    await _userDailyDataService.preSaveTodayUserData(
      nickname: nickname,
      slogan: slogan,
      avatarData: avatarData,
      backgroundData: backgroundData,
      steps: steps,
    );
  }

  /// 预保存日记数据（立即保存，不检查日期）
  Future<void> preSaveDiaryData({
    required String content,
    required List<Uint8List> imageDataList,
    required List<AudioFile> audioFiles,
  }) async {
    await _diaryService.preSaveTodayDiary(
      content: content,
      imageDataList: imageDataList,
      audioFiles: audioFiles,
    );
  }

  /// 智能保存用户数据（检查编辑权限）
  Future<void> smartSaveUserData({
    required String nickname,
    required String slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    required int steps,
  }) async {
    await _userDailyDataService.smartSaveUserData(
      nickname: nickname,
      slogan: slogan,
      avatarData: avatarData,
      backgroundData: backgroundData,
      steps: steps,
    );
  }

  /// 智能保存日记数据（检查编辑权限）
  Future<void> smartSaveDiaryData({
    required String content,
    required List<Uint8List> imageDataList,
    required List<AudioFile> audioFiles,
  }) async {
    await _diaryService.smartSaveTodayDiary(
      content: content,
      imageDataList: imageDataList,
      audioFiles: audioFiles,
    );
  }

  /// 检查并更新编辑状态（当日期变化时调用）
  Future<void> updateEditableStatusForDateChange() async {
    await _databaseService.updateEditableStatusForDateChange();
  }

  /// 检查今日记录是否可编辑
  Future<bool> isTodayEditable() async {
    final today = DateTime.now();
    return await _databaseService.isDateEditable(today);
  }

  /// 获取今日用户数据
  Future<UserDailyData?> getTodayUserData() async {
    final today = DateTime.now();
    return await _userDailyDataService.getUserDataByDate(today);
  }

  /// 获取今日日记
  Future<Diary?> getTodayDiary() async {
    final today = DateTime.now();
    return await _diaryService.getDiaryByDate(today);
  }

  /// 获取指定日期的用户数据
  Future<UserDailyData?> getUserDataByDate(DateTime date) async {
    return await _userDailyDataService.getUserDataByDate(date);
  }

  /// 获取指定日期的日记
  Future<Diary?> getDiaryByDate(DateTime date) async {
    return await _diaryService.getDiaryByDate(date);
  }

  /// 检查指定日期的记录是否可编辑
  Future<bool> isDateEditable(DateTime date) async {
    return await _databaseService.isDateEditable(date);
  }

  /// 批量预保存数据
  Future<void> preSaveBatch({
    String? nickname,
    String? slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    int? steps,
    String? diaryContent,
    List<Uint8List>? imageDataList,
    List<AudioFile>? audioFiles,
  }) async {
    // 预保存用户数据
    if (nickname != null ||
        slogan != null ||
        avatarData != null ||
        backgroundData != null ||
        steps != null) {
      final userProfile = await _userProfileService!.getUserProfile();
      await preSaveUserData(
        nickname: nickname ?? userProfile.nickname,
        slogan: slogan ?? userProfile.slogan,
        avatarData: avatarData,
        backgroundData: backgroundData,
        steps: steps ?? 0,
      );
    }

    // 预保存日记数据
    if (diaryContent != null || imageDataList != null || audioFiles != null) {
      await preSaveDiaryData(
        content: diaryContent ?? '',
        imageDataList: imageDataList ?? [],
        audioFiles: audioFiles ?? [],
      );
    }
  }

  /// 批量智能保存数据
  Future<void> smartSaveBatch({
    String? nickname,
    String? slogan,
    Uint8List? avatarData,
    Uint8List? backgroundData,
    int? steps,
    String? diaryContent,
    List<Uint8List>? imageDataList,
    List<AudioFile>? audioFiles,
  }) async {
    // 首先检查今日是否可编辑
    final isEditable = await isTodayEditable();
    if (!isEditable) {
      throw Exception('今日记录已锁定，无法修改');
    }

    // 如果可编辑，则进行批量预保存
    await preSaveBatch(
      nickname: nickname,
      slogan: slogan,
      avatarData: avatarData,
      backgroundData: backgroundData,
      steps: steps,
      diaryContent: diaryContent,
      imageDataList: imageDataList,
      audioFiles: audioFiles,
    );
  }

  /// 初始化今日数据（确保今日记录存在）
  Future<void> initializeTodayData() async {
    final today = DateTime.now();
    final todayId =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    // 确保今日用户数据存在
    final existingUserData = await _databaseService.getUserDailyData(todayId);
    if (existingUserData == null) {
      final userProfile = await _userProfileService!.getUserProfile();
      final newUserData = UserDailyData.create(
        nickname: userProfile.nickname,
        slogan: userProfile.slogan,
        avatarPath: userProfile.avatar,
        backgroundPath: userProfile.coverImage,
        steps: 0,
        date: today,
        isEditable: true,
      );
      await _databaseService.preSaveUserDailyData(newUserData);
    }

    // 确保今日日记存在
    final existingDiary = await _databaseService.getDiary(todayId);
    if (existingDiary == null) {
      final newDiary = Diary.create(content: '', date: today, isEditable: true);
      await _databaseService.saveDiary(newDiary);
    }
  }
}
