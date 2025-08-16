import 'package:flutter/services.dart';

class SensorChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.example.self_running/sensor',
  );

  static Future<int?> getCumulativeStepCount() async {
    try {
      final int? value = await _channel.invokeMethod<int>(
        'getCumulativeStepCount',
      );
      return value;
    } catch (_) {
      return null;
    }
  }
}


