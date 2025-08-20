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

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Self Running';

  @override
  String get loading => '正在加载...';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get confirm => '确认';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get nickname => '昵称';

  @override
  String get slogan => '口号';

  @override
  String get editNickname => '编辑昵称';

  @override
  String get editSlogan => '编辑口号';

  @override
  String get nicknameEmpty => '昵称不能为空';

  @override
  String saveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get dailyReminder => '每日提醒';

  @override
  String get dailyReminderContent => '记得记录今天的美好瞬间哦！';

  @override
  String get home => '首页';

  @override
  String get diary => '日记';

  @override
  String get memories => '回忆';

  @override
  String get ranking => '排行';

  @override
  String get settings => '设置';
}
