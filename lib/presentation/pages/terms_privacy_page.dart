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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../services/terms_agreement_service.dart';

class TermsPrivacyPage extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const TermsPrivacyPage({super.key, this.isFromSettings = false});

  @override
  ConsumerState<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends ConsumerState<TermsPrivacyPage> {
  bool _hasAgreed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.isFromSettings) {
                        Navigator.of(context).pop();
                      } else {
                        // 如果用户不同意，退出应用
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      widget.isFromSettings ? Icons.arrow_back : Icons.close,
                      color: Colors.grey,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '用户协议与隐私政策',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 平衡布局
                ],
              ),
            ),

            // 协议内容
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '用户协议与隐私政策',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '生效日期：2025年8月20日',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '欢迎使用本应用（以下简称"本应用"）。请您在使用前仔细阅读并理解本用户协议与隐私政策。使用本应用即表示您同意以下内容。',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 一、应用简介
                      _buildSection(
                        '一、应用简介',
                        '本应用致力于帮助用户记录每天的美好瞬间，包括文字、图像、声音等内容。通过记录用户的日常趣事和步数数据，本应用可以：\n\n'
                            '• 整理并生成可阅读、可搜索的记忆卡片，帮助用户回顾和保存重要回忆；\n\n'
                            '• 通过步数排行榜，帮助用户与过去的自己"相遇"，体验时光的流动与变化。',
                      ),

                      // 二、数据处理与隐私保护
                      _buildSection(
                        '二、数据处理与隐私保护',
                        '本地存储与处理\n\n'
                            '本应用不会联网处理任何用户数据，所有数据（包括文字、图片、音频、步数等）均存储于用户本地设备中。\n\n'
                            '用户可随时管理、导出或删除其在本应用中的数据。\n\n'
                            '数据使用范围\n\n'
                            '本应用仅在本地使用用户数据，用于生成记忆卡片、步数排行榜等功能。\n\n'
                            '本应用不会将用户数据用于广告、商业分析或其他非本应用功能的目的。\n\n'
                            '第三方服务\n\n'
                            '本应用未接入任何第三方 SDK 或服务，不会通过第三方渠道收集或传输用户数据。',
                      ),

                      // 三、权限说明
                      _buildSection(
                        '三、权限说明',
                        '为了正常提供功能，本应用可能会向用户申请以下权限：\n\n'
                            '• 存储权限：用于保存文字、图片、音频等用户记录内容；\n\n'
                            '• 相机/麦克风权限：用于拍摄照片或录制音频；\n\n'
                            '• 运动与健康权限（或传感器权限）：用于获取步数数据并生成步数排行榜；\n\n'
                            '• 通知权限：用于向用户推送提醒，例如每日记录提醒、重要事件回顾提示。\n\n'
                            '以上权限均为实现对应功能所必需，用户可选择是否授权。拒绝授权可能导致部分功能无法使用，但不影响其他功能的正常使用。本应用不会将相关数据上传或分享。',
                      ),

                      // 四、开源声明
                      _buildSection(
                        '四、开源声明',
                        '本应用为开源软件，遵循 Apache License 2.0 开源协议。\n\n'
                            '用户可以在遵循开源协议的前提下，自由使用、修改和分发本应用的源代码。',
                      ),

                      // 五、免责声明
                      _buildSection(
                        '五、免责声明',
                        '本应用所提供的功能仅用于个人记录和回忆整理，不保证在任何情况下的准确性、完整性或适用性。\n\n'
                            '用户需自行对其输入、保存的数据内容负责，本应用开发者不对因使用本应用而产生的任何直接或间接损失承担责任。',
                      ),

                      // 六、儿童隐私
                      _buildSection(
                        '六、儿童隐私',
                        '本应用主要面向普通用户，不特别针对儿童用户。若用户未满 14 周岁，请在监护人指导下使用本应用。',
                      ),

                      // 七、协议与政策的更新
                      _buildSection(
                        '七、协议与政策的更新',
                        '随着功能调整或法律法规变化，本用户协议与隐私政策可能会适时更新。更新后的内容将在本应用中公布，自公布之日起生效。若您继续使用本应用，即视为接受修改后的协议与政策。',
                      ),

                      // 八、联系方式
                      _buildSection(
                        '八、联系方式',
                        '如您对本应用或本用户协议与隐私政策有任何问题或建议，请通过应用发布页面提供的联系方式与开发者取得联系。',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 底部确认区域（仅在首次使用时显示）
            if (!widget.isFromSettings)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 同意复选框
                    Row(
                      children: [
                        Checkbox(
                          value: _hasAgreed,
                          onChanged: (value) {
                            setState(() {
                              _hasAgreed = value ?? false;
                            });
                          },
                          activeColor: Colors.black87,
                          checkColor: Colors.white,
                        ),
                        const Expanded(
                          child: Text(
                            '我已阅读并同意《用户协议与隐私政策》',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 确认按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _hasAgreed && !_isLoading
                            ? _onConfirm
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasAgreed
                              ? Colors.black87
                              : Colors.grey.shade300,
                          foregroundColor: _hasAgreed
                              ? Colors.white
                              : Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                '确认并继续',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _onConfirm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 保存用户同意状态
      final storageService = StorageService();
      final termsService = TermsAgreementService(storageService);
      await termsService.setAgreedToTerms(true);

      // 导航到主页
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
