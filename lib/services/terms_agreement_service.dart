import 'package:hive_flutter/hive_flutter.dart';
import 'storage_service.dart';

class TermsAgreementService {
  static const String _agreementKey = 'has_agreed_terms';

  final StorageService _storageService;

  TermsAgreementService(this._storageService);

  /// 检查用户是否已同意用户协议
  Future<bool> hasAgreedToTerms() async {
    try {
      await _storageService.init();
      final box = Hive.box(StorageService.dailyStepsBoxName);
      return box.get(_agreementKey, defaultValue: false) ?? false;
    } catch (e) {
      print('检查用户协议同意状态失败: $e');
      return false;
    }
  }

  /// 保存用户同意状态
  Future<void> setAgreedToTerms(bool agreed) async {
    try {
      await _storageService.init();
      final box = Hive.box(StorageService.dailyStepsBoxName);
      await box.put(_agreementKey, agreed);
    } catch (e) {
      print('保存用户协议同意状态失败: $e');
      rethrow;
    }
  }

  /// 清除用户同意状态（用于测试或重置）
  Future<void> clearAgreementStatus() async {
    try {
      await _storageService.init();
      final box = Hive.box(StorageService.dailyStepsBoxName);
      await box.delete(_agreementKey);
    } catch (e) {
      print('清除用户协议同意状态失败: $e');
      rethrow;
    }
  }
}
