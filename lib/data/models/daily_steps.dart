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


