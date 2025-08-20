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

    // 确保至少包含今日数据，但不填充历史0值数据
    final today = DateTime.now();
    final todayKey = _key(today);

    // 如果没有今日数据，创建一个今日记录（步数为0，但至少显示）
    if (!dayToItem.containsKey(todayKey)) {
      dayToItem[todayKey] = DailySteps(
        localDay: DateTime(today.year, today.month, today.day),
        steps: 0,
        tzOffsetMinutes: today.timeZoneOffset.inMinutes,
      );
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
