import 'package:intl/intl.dart';
import '../../data/models/daily_steps.dart';
import '../../data/repositories/health_repository.dart';
import '../../services/storage_service.dart';
import '../../data/repositories/sensor_repository.dart';

class FetchDailyStepsUseCase {
  final HealthRepository healthRepository;
  final StorageService storage;
  final SensorRepository? sensorRepository; // Android-only 可选兜底

  FetchDailyStepsUseCase({
    required this.healthRepository,
    required this.storage,
    this.sensorRepository,
  });

  Future<List<DailySteps>> call({
    required DateTime from,
    required DateTime to,
  }) async {
    // Load cached
    final cached = storage.loadAllDailySteps();
    final Map<String, DailySteps> dayToItem = {
      for (final d in cached) _key(d.localDay): d,
    };

    // Fetch fresh
    final fresh = await healthRepository.fetchDailySteps(from, to);
    for (final d in fresh) {
      dayToItem[_key(d.localDay)] = d;
    }

    // Fill gaps with 0 to keep continuity
    DateTime cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      final key = _key(cursor);
      dayToItem[key] =
          dayToItem[key] ??
          DailySteps(
            localDay: cursor,
            steps: 0,
            tzOffsetMinutes: cursor.timeZoneOffset.inMinutes,
          );
      cursor = cursor.add(const Duration(days: 1));
    }

    final result = dayToItem.values.toList()
      ..sort((a, b) => a.localDay.compareTo(b.localDay));

    // Persist
    await storage.saveDailySteps(result);

    // Android-only 兜底：若 Health 无法取到“今天”的数据，尝试用传感器补今天
    if (result.isNotEmpty) {
      final last = result.last;
      final todayLocal = DateTime.now();
      final isSameDay =
          last.localDay.year == todayLocal.year &&
          last.localDay.month == todayLocal.month &&
          last.localDay.day == todayLocal.day;
      final healthTodayIsZero = isSameDay && last.steps == 0;
      if (healthTodayIsZero && sensorRepository != null) {
        final sensorToday = await sensorRepository!.fetchTodayBySensor();
        if (sensorToday != null && sensorToday.steps > 0) {
          // 用传感器的“今天”覆盖 0 值，以提升体验
          result[result.length - 1] = sensorToday;
          await storage.saveDailySteps(result);
        }
      }
    }
    return result;
  }

  String _key(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
}
