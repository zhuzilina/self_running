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
      assert(() {
        print('检查用户协议同意状态失败: $e');
        return true;
      }());
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
      assert(() {
        print('保存用户协议同意状态失败: $e');
        return true;
      }());
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
      assert(() {
        print('清除用户协议同意状态失败: $e');
        return true;
      }());
      rethrow;
    }
  }
}
