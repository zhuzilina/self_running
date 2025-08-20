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
