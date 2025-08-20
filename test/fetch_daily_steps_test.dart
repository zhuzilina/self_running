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

import 'package:flutter_test/flutter_test.dart';
import 'package:self_running/domain/usecases/fetch_daily_steps_usecase.dart';
import 'package:self_running/data/models/daily_steps.dart';
import 'package:self_running/data/repositories/health_repository.dart';
import 'package:self_running/services/storage_service.dart';

// Mock classes for testing
class MockHealthRepository extends HealthRepository {
  bool _returnEmpty = false;

  @override
  Future<List<DailySteps>> fetchDailySteps(DateTime from, DateTime to) async {
    if (_returnEmpty) {
      return [];
    }

    // 返回一些真实的测试数据
    return [
      DailySteps(
        localDay: DateTime(2024, 12, 15),
        steps: 8000,
        tzOffsetMinutes: 480,
      ),
      DailySteps(
        localDay: DateTime(2024, 12, 16),
        steps: 12000,
        tzOffsetMinutes: 480,
      ),
    ];
  }
}

class MockStorageService extends StorageService {
  List<DailySteps> _cachedData = [
    DailySteps(
      localDay: DateTime(2024, 12, 14),
      steps: 6000,
      tzOffsetMinutes: 480,
    ),
  ];

  @override
  List<DailySteps> loadAllDailySteps() {
    return _cachedData;
  }

  @override
  Future<void> saveDailySteps(List<DailySteps> items) async {
    _cachedData = items;
  }
}

void main() {
  group('FetchDailyStepsUseCase', () {
    test('should not generate test data with 0 steps', () async {
      final useCase = FetchDailyStepsUseCase(
        healthRepository: MockHealthRepository(),
        storage: MockStorageService(),
      );

      final from = DateTime(2024, 12, 10);
      final to = DateTime(2024, 12, 16);

      final result = await useCase.call(from: from, to: to);

      // 验证结果包含真实数据加上今日数据
      expect(result.length, equals(4)); // 3条真实数据 + 1条今日数据

      // 验证所有数据都有真实的步数（除了今日数据）
      final today = DateTime.now();
      for (final step in result) {
        if (step.localDay.year == today.year &&
            step.localDay.month == today.month &&
            step.localDay.day == today.day) {
          // 今日数据可以是0步
          expect(step.steps, greaterThanOrEqualTo(0));
        } else {
          // 其他数据必须大于0
          expect(step.steps, greaterThan(0));
        }
      }

      // 验证日期是真实的
      final dates = result.map((e) => e.localDay).toList();
      expect(dates, contains(DateTime(2024, 12, 14)));
      expect(dates, contains(DateTime(2024, 12, 15)));
      expect(dates, contains(DateTime(2024, 12, 16)));

      // 验证没有填充的日期（如12月10-13日）
      expect(dates, isNot(contains(DateTime(2024, 12, 10))));
      expect(dates, isNot(contains(DateTime(2024, 12, 11))));
      expect(dates, isNot(contains(DateTime(2024, 12, 12))));
      expect(dates, isNot(contains(DateTime(2024, 12, 13))));
    });

    test('should handle empty data correctly', () async {
      final emptyStorage = MockStorageService();
      emptyStorage._cachedData = []; // 清空缓存数据

      final emptyHealthRepository = MockHealthRepository();
      emptyHealthRepository._returnEmpty = true; // 标记返回空数据

      final useCase = FetchDailyStepsUseCase(
        healthRepository: emptyHealthRepository,
        storage: emptyStorage,
      );

      final from = DateTime(2024, 12, 20);
      final to = DateTime(2024, 12, 25);

      final result = await useCase.call(from: from, to: to);

      // 验证没有数据时至少返回今日数据
      expect(result.length, equals(1));
      expect(result.first.steps, equals(0));

      // 验证今日数据
      final today = DateTime.now();
      expect(result.first.localDay.year, equals(today.year));
      expect(result.first.localDay.month, equals(today.month));
      expect(result.first.localDay.day, equals(today.day));
    });

    test('should preserve real data without filling gaps', () async {
      final useCase = FetchDailyStepsUseCase(
        healthRepository: MockHealthRepository(),
        storage: MockStorageService(),
      );

      final from = DateTime(2024, 12, 14);
      final to = DateTime(2024, 12, 16);

      final result = await useCase.call(from: from, to: to);

      // 验证返回真实数据加上今日数据
      expect(result.length, equals(4)); // 3条真实数据 + 1条今日数据

      // 验证步数都是真实的
      final steps = result.map((e) => e.steps).toList();
      expect(steps, contains(6000));
      expect(steps, contains(8000));
      expect(steps, contains(12000));

      // 验证没有0步数据（除了今日数据）
      final today = DateTime.now();
      final todaySteps = result
          .where(
            (e) =>
                e.localDay.year == today.year &&
                e.localDay.month == today.month &&
                e.localDay.day == today.day,
          )
          .map((e) => e.steps)
          .toList();

      // 今日数据可以是0步，但其他数据不能是0步
      final otherSteps = result
          .where(
            (e) =>
                !(e.localDay.year == today.year &&
                    e.localDay.month == today.month &&
                    e.localDay.day == today.day),
          )
          .map((e) => e.steps)
          .toList();

      for (final step in otherSteps) {
        expect(step, greaterThan(0));
      }
    });

    test(
      'should always include today data even when no other data exists',
      () async {
        final emptyStorage = MockStorageService();
        emptyStorage._cachedData = []; // 清空缓存数据

        final emptyHealthRepository = MockHealthRepository();
        emptyHealthRepository._returnEmpty = true; // 标记返回空数据

        final useCase = FetchDailyStepsUseCase(
          healthRepository: emptyHealthRepository,
          storage: emptyStorage,
        );

        final from = DateTime(2024, 12, 10);
        final to = DateTime(2024, 12, 16);

        final result = await useCase.call(from: from, to: to);

        // 验证至少包含今日数据
        expect(result.length, greaterThanOrEqualTo(1));

        // 验证包含今日数据
        final today = DateTime.now();
        final todayData = result
            .where(
              (e) =>
                  e.localDay.year == today.year &&
                  e.localDay.month == today.month &&
                  e.localDay.day == today.day,
            )
            .toList();

        expect(todayData.length, equals(1));
        expect(todayData.first.steps, equals(0)); // 今日数据初始为0步
      },
    );
  });
}
