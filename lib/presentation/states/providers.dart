import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_steps.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/diary.dart';
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
    return await usecase.call(from: from, to: to);
  } catch (e, stackTrace) {
    print('dailyStepsProvider: Error - $e');
    // 返回一个默认的空列表，避免应用崩溃
    return [];
  }
});

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
  return DataInitializationService();
});

// 系统日期状态Provider
final systemDateStatusProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(dataInitializationServiceProvider);
  await service.init();
  return service.getSystemDateStatus();
});

// 今日记录可编辑状态Provider
final todayEditableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(dataInitializationServiceProvider);
  await service.init();
  return service.isTodayEditable();
});
