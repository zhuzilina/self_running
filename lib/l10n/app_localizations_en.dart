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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Self Running';

  @override
  String get loading => 'Loading...';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get nickname => 'Nickname';

  @override
  String get slogan => 'Slogan';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get editSlogan => 'Edit Slogan';

  @override
  String get nicknameEmpty => 'Nickname cannot be empty';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get dailyReminderContent => 'Remember to record today\'s beautiful moments!';

  @override
  String get home => 'Home';

  @override
  String get diary => 'Diary';

  @override
  String get memories => 'Memories';

  @override
  String get ranking => 'Ranking';

  @override
  String get settings => 'Settings';
}
