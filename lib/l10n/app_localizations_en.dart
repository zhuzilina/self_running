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
