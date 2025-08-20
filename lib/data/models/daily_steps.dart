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

class DailySteps {
  final DateTime localDay;
  final int steps;
  final int? goal;
  final int tzOffsetMinutes;

  const DailySteps({
    required this.localDay,
    required this.steps,
    required this.tzOffsetMinutes,
    this.goal,
  });

  DailySteps copyWith({
    DateTime? localDay,
    int? steps,
    int? goal,
    int? tzOffsetMinutes,
  }) {
    return DailySteps(
      localDay: localDay ?? this.localDay,
      steps: steps ?? this.steps,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      goal: goal ?? this.goal,
    );
  }

  String get dayKey => DateFormat('yyyy-MM-dd').format(localDay);

  Map<String, dynamic> toMap() {
    return {
      'localDay': localDay.toIso8601String(),
      'steps': steps,
      'goal': goal,
      'tzOffsetMinutes': tzOffsetMinutes,
    };
  }

  factory DailySteps.fromMap(Map map) {
    return DailySteps(
      localDay: DateTime.parse(map['localDay'] as String),
      steps: (map['steps'] as num).toInt(),
      tzOffsetMinutes: (map['tzOffsetMinutes'] as num).toInt(),
      goal: map['goal'] == null ? null : (map['goal'] as num).toInt(),
    );
  }
}


