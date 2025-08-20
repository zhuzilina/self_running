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

import 'package:health/health.dart';
import '../models/daily_steps.dart';

class HealthRepository {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
    ];
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      assert(() {
        print('Health permissions granted: $granted');
        return true;
      }());
      return granted;
    } catch (e) {
      assert(() {
        print('Health permissions error: $e');
        return true;
      }());
      return false;
    }
  }

  Future<List<DailySteps>> fetchDailySteps(DateTime from, DateTime to) async {
    try {
      print(
        'Fetching health data from ${from.toIso8601String()} to ${to.toIso8601String()}',
      );

      // 不再自动请求权限，直接尝试获取数据
      // 如果没有权限，将返回空列表

      assert(() {

        print('Requesting health data...');

        return true;

      }());
      final raw = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.STEPS],
        startTime: from,
        endTime: to,
      );

      assert(() {

        print('Received ${raw.length} health data points');

        return true;

      }());
      final mapped = raw;
      final Map<DateTime, int> bucket = {};

      for (final d in mapped) {
        final local = DateTime(
          d.dateFrom.year,
          d.dateFrom.month,
          d.dateFrom.day,
        );
        final value = (d.value as num?)?.toInt() ?? 0;
        bucket[local] = (bucket[local] ?? 0) + value;
        assert(() {
          print('Health data: ${d.dateFrom} -> $value steps');
          return true;
        }());
      }

      final List<DailySteps> list =
          bucket.entries
              .map(
                (e) => DailySteps(
                  localDay: e.key,
                  steps: e.value,
                  tzOffsetMinutes: e.key.timeZoneOffset.inMinutes,
                ),
              )
              .toList()
            ..sort((a, b) => a.localDay.compareTo(b.localDay));

      assert(() {

        print('Processed ${list.length} daily steps records');

        return true;

      }());
      return list;
    } catch (e) {
      assert(() {
        print('Error fetching health data: $e');
        return true;
      }());
      // 在非支持平台或无权限时，容错返回空列表
      return [];
    }
  }
}
