import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_steps.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/diary.dart';
import '../../data/models/user_daily_data.dart';
import '../../data/models/audio_file.dart';
import '../../data/repositories/health_repository.dart';
import '../../data/repositories/sensor_repository.dart';
import '../../domain/usecases/compute_ranking_usecase.dart';
import '../../domain/usecases/fetch_daily_steps_usecase.dart';
import '../../services/storage_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/diary_service.dart';
import '../../services/database_service.dart';
import '../../services/file_storage_service.dart';
import '../../services/user_daily_data_service.dart';
import '../../services/data_initialization_service.dart';
import '../../platform/sensor_channel.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../services/data_persistence_service.dart';
import '../../services/health_data_sync_service.dart';
import '../../services/pinned_diary_service.dart';
import '../../services/sensor_steps_service.dart';
import '../../services/realtime_steps_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(ref.read(storageServiceProvider));
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.read(userProfileServiceProvider);
  await service.init();
  return service.getUserProfile();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService.instance;
});

final userDailyDataServiceProvider = Provider<UserDailyDataService>((ref) {
  return UserDailyDataService();
});

final diaryServiceProvider = Provider<DiaryService>((ref) {
  return DiaryService();
});

final todayDiaryProvider = FutureProvider<Diary?>((ref) async {
  final service = ref.read(diaryServiceProvider);
  return service.getTodayDiary();
});

final allDiariesProvider = FutureProvider<List<Diary>>((ref) async {
  final diaryService = ref.read(diaryServiceProvider);
  return diaryService.getAllDiaries();
});

// 搜索查询状态Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// 搜索日记Provider
final searchDiariesProvider = FutureProvider.family<List<Diary>, String>((
  ref,
  query,
) async {
  final diaryService = ref.read(diaryServiceProvider);
  return diaryService.searchDiaries(query);
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

final fetchDailyStepsUseCaseProvider = Provider<FetchDailyStepsUseCase>((ref) {
  // Android-only 传感器适配：这里以占位实现，真实项目中应接入 pedometer 或原生传感器
  final storage = ref.read(storageServiceProvider);
  SensorRepository? sensor;
  sensor = SensorRepository(
    storage: storage,
    getCurrentCumulativeCount: () async {
      // 通过 MethodChannel 调用 Android 原生传感器（若不可用则返回 null）
      return await SensorChannel.getCumulativeStepCount();
    },
  );
  return FetchDailyStepsUseCase(
    healthRepository: ref.read(healthRepositoryProvider),
    storage: storage,
    sensorRepository: sensor,
  );
});

final selectedRangeDaysProvider = StateProvider<int>((ref) => 30);

final dailyStepsProvider = FutureProvider<List<DailySteps>>((ref) async {
  try {
    final storage = ref.read(storageServiceProvider);
    await storage.init();
    final usecase = ref.read(fetchDailyStepsUseCaseProvider);
    final now = DateTime.now();
    // 获取最近30天的数据
    final from = now.subtract(const Duration(days: 30));
    final to = now;
    final result = await usecase.call(from: from, to: to);

    // 同步健康数据到每日数据表
    final syncService = ref.read(healthDataSyncServiceProvider);
    await syncService.syncHealthDataToDailyData();

    // 强制刷新步数数据
    await _refreshStepsData(ref);

    return result;
  } catch (e, stackTrace) {
    print('dailyStepsProvider: Error - $e');
    print('Stack trace: $stackTrace');
    // 返回一个默认的空列表，避免应用崩溃
    return [];
  }
});

/// 强制刷新步数数据
Future<void> _refreshStepsData(Ref ref) async {
  try {
    // 手动触发传感器步数服务更新
    final sensorService = SensorStepsService();
    await sensorService.refreshSteps();

    // 手动触发实时步数服务更新（现在也使用传感器）
    final realtimeService = RealtimeStepsService();
    await realtimeService.refreshTodaySteps();

    print('Steps data refreshed successfully');
  } catch (e) {
    print('Error refreshing steps data: $e');
  }
}

class TodayRanking {
  final int rank;
  final double percentile;
  final int surpassedDays;
  const TodayRanking({
    required this.rank,
    required this.percentile,
    required this.surpassedDays,
  });
  factory TodayRanking.empty() =>
      const TodayRanking(rank: 0, percentile: 1.0, surpassedDays: 0);
}

final todayRankingProvider = Provider<TodayRanking>((ref) {
  final asyncData = ref.watch(dailyStepsProvider);
  return asyncData.when(
    data: (data) {
      if (data.isEmpty) return TodayRanking.empty();
      final today = data.last.steps;
      final history = data.take(data.length - 1).map((e) => e.steps).toList();
      final r = computeRanking(historicalSteps: history, todaySteps: today);
      return TodayRanking(
        rank: r.rank,
        percentile: r.percentile,
        surpassedDays: r.surpassedDays,
      );
    },
    loading: () => TodayRanking.empty(),
    error: (_, __) => TodayRanking.empty(),
  );
});

// 数据初始化服务Provider
final dataInitializationServiceProvider = Provider<DataInitializationService>((
  ref,
) {
  final service = DataInitializationService();
  service.initialize(
    databaseService: ref.read(databaseServiceProvider),
    userProfileService: ref.read(userProfileServiceProvider),
    healthDataSyncService: ref.read(healthDataSyncServiceProvider),
  );
  return service;
});

// 系统日期状态Provider
final systemDateStatusProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(dataInitializationServiceProvider);
  return service.getSystemDateStatus();
});

// 数据持久化服务Provider
final dataPersistenceServiceProvider = Provider<DataPersistenceService>((ref) {
  return DataPersistenceService();
});

// 今日记录可编辑状态Provider
final todayEditableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();
  return service.isTodayEditable();
});

// 预保存Provider
final preSaveProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();

  await service.preSaveBatch(
    nickname: data['nickname'] as String?,
    slogan: data['slogan'] as String?,
    steps: data['steps'] as int?,
    diaryContent: data['diaryContent'] as String?,
    avatarData: data['avatarData'] as Uint8List?,
    backgroundData: data['backgroundData'] as Uint8List?,
    imageDataList: data['imageDataList'] as List<Uint8List>?,
    audioFiles: data['audioFiles'] as List<AudioFile>?,
  );
});

// 智能保存Provider
final smartSaveProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();

  await service.smartSaveBatch(
    nickname: data['nickname'] as String?,
    slogan: data['slogan'] as String?,
    steps: data['steps'] as int?,
    diaryContent: data['diaryContent'] as String?,
    avatarData: data['avatarData'] as Uint8List?,
    backgroundData: data['backgroundData'] as Uint8List?,
    imageDataList: data['imageDataList'] as List<Uint8List>?,
    audioFiles: data['audioFiles'] as List<AudioFile>?,
  );
});

// 日期状态更新Provider
final dateStatusUpdateProvider = FutureProvider<void>((ref) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();
  await service.updateEditableStatusForDateChange();
});

// 今日用户数据Provider
final todayUserDataProvider = FutureProvider<UserDailyData?>((ref) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();
  return service.getTodayUserData();
});

// 今日日记Provider
final todayDiaryDataProvider = FutureProvider<Diary?>((ref) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();
  return service.getTodayDiary();
});

// 用户配置更新Provider
final userProfileUpdateProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
      final service = ref.read(userProfileServiceProvider);
      await service.init();

      final nickname = data['nickname'] as String?;
      final slogan = data['slogan'] as String?;

      if (nickname != null) {
        await service.updateProfile(nickname: nickname);
      }

      if (slogan != null) {
        await service.updateProfile(slogan: slogan);
      }

      ref.invalidate(userProfileProvider); // 刷新用户配置
    });

// 用户每日数据排行Provider - 从数据库获取数据用于排行
final userDailyDataRankingProvider = FutureProvider<List<UserDailyData>>((
  ref,
) async {
  try {
    // 监听用户配置变化，确保配置更新时排行数据自动刷新
    await ref.read(userProfileProvider.future);

    final service = ref.read(userDailyDataServiceProvider);

    // 获取所有用户数据
    final allData = await service.getAllUserData();

    // 按日期排序，最新的在前面
    allData.sort((a, b) => b.date.compareTo(a.date));

    return allData;
  } catch (e) {
    print('userDailyDataRankingProvider: Error - $e');
    return [];
  }
});

// 初始化今日数据Provider
final initializeTodayDataProvider = FutureProvider<void>((ref) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();
  await service.initializeTodayData();
});

// 用户数据预保存Provider
final userDataPreSaveProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
      final service = ref.read(dataPersistenceServiceProvider);
      await service.init();

      await service.preSaveUserData(
        nickname: data['nickname'] as String,
        slogan: data['slogan'] as String,
        avatarData: data['avatarData'] as Uint8List?,
        backgroundData: data['backgroundData'] as Uint8List?,
        steps: data['steps'] as int,
      );
    });

// 用户数据智能保存Provider
final userDataSmartSaveProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
      final service = ref.read(dataPersistenceServiceProvider);
      await service.init();

      await service.smartSaveUserData(
        nickname: data['nickname'] as String,
        slogan: data['slogan'] as String,
        avatarData: data['avatarData'] as Uint8List?,
        backgroundData: data['backgroundData'] as Uint8List?,
        steps: data['steps'] as int,
      );
    });

// 日记预保存Provider
final diaryPreSaveProvider = FutureProvider.family<void, Map<String, dynamic>>((
  ref,
  data,
) async {
  final service = ref.read(dataPersistenceServiceProvider);
  await service.init();

  await service.preSaveDiaryData(
    content: data['content'] as String,
    imageDataList: data['imageDataList'] as List<Uint8List>,
    audioFiles: data['audioFiles'] as List<AudioFile>,
  );
});

// 日记智能保存Provider
final diarySmartSaveProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
      final service = ref.read(dataPersistenceServiceProvider);
      await service.init();

      await service.smartSaveDiaryData(
        content: data['content'] as String,
        imageDataList: data['imageDataList'] as List<Uint8List>,
        audioFiles: data['audioFiles'] as List<AudioFile>,
      );
    });

final healthDataSyncServiceProvider = Provider<HealthDataSyncService>((ref) {
  return HealthDataSyncService(
    storageService: ref.read(storageServiceProvider),
    databaseService: ref.read(databaseServiceProvider),
    userProfileService: ref.read(userProfileServiceProvider),
  );
});

final pinnedDiaryServiceProvider = Provider<PinnedDiaryService>((ref) {
  return PinnedDiaryService(ref.read(databaseServiceProvider));
});

// 置顶日记Provider
final pinnedDiariesProvider = FutureProvider<List<Diary>>((ref) async {
  final service = ref.read(pinnedDiaryServiceProvider);
  await service.init();
  return service.getPinnedDiariesWithData();
});
