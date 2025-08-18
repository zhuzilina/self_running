import 'package:flutter_test/flutter_test.dart';
import 'package:self_running/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('should generate default nickname without date format', () {
      final profile = UserProfile.defaultProfile();
      expect(profile.nickname, equals('吃个炸鸡'));
      expect(profile.slogan, equals('无忧无虑又一天'));
      expect(profile.avatar, equals('assets/images/avatar.jpg'));
      expect(profile.coverImage, equals('assets/images/user_bg.jpg'));
      expect(profile.lastUpdated, isNotNull);
    });

    test('should handle fromJson with null nickname', () {
      final json = {
        'avatar': 'test_avatar.jpg',
        'slogan': 'test slogan',
        'coverImage': 'test_cover.jpg',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.nickname, equals('吃个炸鸡'));
      expect(profile.slogan, equals('test slogan'));
      expect(profile.avatar, equals('test_avatar.jpg'));
      expect(profile.coverImage, equals('test_cover.jpg'));
    });

    test('should preserve existing nickname in fromJson', () {
      final json = {
        'nickname': '自定义昵称',
        'slogan': '自定义口号',
        'avatar': 'test_avatar.jpg',
        'coverImage': 'test_cover.jpg',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.nickname, equals('自定义昵称'));
      expect(profile.slogan, equals('自定义口号'));
    });

    test('should handle fromJson with null slogan', () {
      final json = {
        'nickname': 'test nickname',
        'avatar': 'test_avatar.jpg',
        'coverImage': 'test_cover.jpg',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.nickname, equals('test nickname'));
      expect(profile.slogan, equals('无忧无虑又一天'));
    });
  });
}
