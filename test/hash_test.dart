import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';

void main() {
  group('MD5 Hash Tests', () {
    test('should generate MD5 hash for image data', () {
      // 模拟图片数据
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      // 生成MD5 hash
      final hash = md5.convert(imageData);
      final fileName = '${hash.toString()}.jpg';

      // 验证hash长度（MD5应该是32个字符）
      expect(hash.toString().length, equals(32));

      // 验证文件名格式
      expect(fileName.endsWith('.jpg'), isTrue);
      expect(fileName.length, equals(36)); // 32字符hash + 4字符扩展名

      print('Generated filename: $fileName');
    });

    test('should generate MD5 hash for audio data', () {
      // 模拟音频数据
      final audioData = Uint8List.fromList([
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        90,
        100,
      ]);

      // 生成MD5 hash
      final hash = md5.convert(audioData);
      final fileName = '${hash.toString()}.m4a';

      // 验证hash长度（MD5应该是32个字符）
      expect(hash.toString().length, equals(32));

      // 验证文件名格式
      expect(fileName.endsWith('.m4a'), isTrue);
      expect(fileName.length, equals(36)); // 32字符hash + 4字符扩展名

      print('Generated filename: $fileName');
    });

    test('should generate different hashes for different data', () {
      final data1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final data2 = Uint8List.fromList([5, 4, 3, 2, 1]);

      final hash1 = md5.convert(data1);
      final hash2 = md5.convert(data2);

      // 验证不同的数据生成不同的hash
      expect(hash1.toString(), isNot(equals(hash2.toString())));

      print('Hash1: ${hash1.toString()}');
      print('Hash2: ${hash2.toString()}');
    });

    test('should generate same hash for same data', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      final hash1 = md5.convert(data);
      final hash2 = md5.convert(data);

      // 验证相同的数据生成相同的hash
      expect(hash1.toString(), equals(hash2.toString()));

      print('Consistent hash: ${hash1.toString()}');
    });
  });
}
