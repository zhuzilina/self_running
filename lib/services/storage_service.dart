import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../data/models/daily_steps.dart';

class StorageService {
  static const String dailyStepsBoxName = 'daily_steps';
  static const String sensorBaselinePrefix =
      'sensor_baseline:'; // key = sensor_baseline:yyyy-MM-dd
  static bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      await Hive.initFlutter();
      _initialized = true;
    }
    await Hive.openBox(MapBox.key);
  }

  Future<void> saveDailySteps(List<DailySteps> items) async {
    final box = Hive.box(MapBox.key);
    final Map<String, Map<String, dynamic>> toStore = {
      for (final d in items) _formatDay(d.localDay): d.toMap(),
    };
    await box.putAll(toStore);
  }

  List<DailySteps> loadAllDailySteps() {
    final box = Hive.box(MapBox.key);
    final values = box.toMap().values;
    final List<DailySteps> list = [];
    for (final v in values) {
      if (v is Map) {
        try {
          list.add(DailySteps.fromMap(v));
        } catch (_) {}
      }
    }
    list.sort((a, b) => a.localDay.compareTo(b.localDay));
    return list;
  }

  Future<void> clearAll() async {
    final box = Hive.box(MapBox.key);
    await box.clear();
  }

  String _formatDay(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  // --- Sensor baseline helpers ---
  String _sensorKeyForDay(DateTime day) =>
      '$sensorBaselinePrefix${_formatDay(day)}';

  Future<void> saveSensorBaselineForDay({
    required DateTime localDay,
    required int baselineCounter,
  }) async {
    final box = Hive.box(MapBox.key);
    await box.put(_sensorKeyForDay(localDay), baselineCounter);
  }

  int? loadSensorBaselineForDay(DateTime localDay) {
    final box = Hive.box(MapBox.key);
    final value = box.get(_sensorKeyForDay(localDay));
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

class MapBox {
  static String get key => StorageService.dailyStepsBoxName;
}
