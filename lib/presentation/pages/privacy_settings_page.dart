import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'terms_privacy_page.dart';

class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() =>
      _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私设置'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 隐私
          _buildPrivacySection(),
          const SizedBox(height: 24),

          // 权限设置
          _buildPermissionsSection(),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '隐私',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // 用户协议与隐私政策
        _buildPermissionItem(
          icon: Icons.description,
          title: '用户协议与隐私政策',
          description: '查看应用使用条款和隐私政策',
          onTap: () => _openTermsPrivacy(),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '权限',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // 存储权限
        _buildPermissionItem(
          icon: Icons.folder,
          title: '存储权限',
          description: '用于保存文字、图片、音频等用户记录内容',
          onTap: () => _openAppSettings(),
        ),

        const SizedBox(height: 12),

        // 相机/麦克风权限
        _buildPermissionItem(
          icon: Icons.camera_alt,
          title: '相机/麦克风权限',
          description: '用于拍摄照片或录制音频',
          onTap: () => _openAppSettings(),
        ),

        const SizedBox(height: 12),

        // 运动与健康权限
        _buildPermissionItem(
          icon: Icons.favorite,
          title: '运动与健康权限',
          description: '用于获取步数数据并生成步数排行榜',
          onTap: () => _openAppSettings(),
        ),

        const SizedBox(height: 12),

        // 通知权限
        _buildPermissionItem(
          icon: Icons.notifications,
          title: '通知权限',
          description: '用于每日提醒',
          onTap: () => _openAppSettings(),
        ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开应用设置'), backgroundColor: Colors.red),
      );
    }
  }

  void _openTermsPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsPrivacyPage(isFromSettings: true),
      ),
    );
  }
}
