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

import 'package:hive/hive.dart';

part 'daily_steps_base.g.dart';

@HiveType(typeId: 4)
class DailyStepsBase extends HiveObject {
  @HiveField(0)
  final DateTime localDay;

  @HiveField(1)
  final int baseStepCount;

  @HiveField(2)
  final int actualStepCount;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  DailyStepsBase({
    required this.localDay,
    required this.baseStepCount,
    required this.actualStepCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计算今日实际步数
  int get todaySteps {
    return actualStepCount - baseStepCount;
  }

  /// 更新实际步数
  DailyStepsBase copyWith({
    DateTime? localDay,
    int? baseStepCount,
    int? actualStepCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyStepsBase(
      localDay: localDay ?? this.localDay,
      baseStepCount: baseStepCount ?? this.baseStepCount,
      actualStepCount: actualStepCount ?? this.actualStepCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DailyStepsBase(localDay: $localDay, baseStepCount: $baseStepCount, actualStepCount: $actualStepCount, todaySteps: $todaySteps)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyStepsBase &&
        other.localDay == localDay &&
        other.baseStepCount == baseStepCount &&
        other.actualStepCount == actualStepCount;
  }

  @override
  int get hashCode {
    return localDay.hashCode ^
        baseStepCount.hashCode ^
        actualStepCount.hashCode;
  }
}
