import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'privacy_settings_page.dart';
import 'app_info_page.dart';
import 'reminder_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 提醒设置
          _buildSettingsSection(
            context,
            title: '提醒设置',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                title: '每日提醒',
                subtitle: '提示用户记录每天的日记',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReminderSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 隐私权限设置
          _buildSettingsSection(
            context,
            title: '隐私权限',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.privacy_tip,
                title: '隐私设置',
                subtitle: '管理数据隐私和权限',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 关于
          _buildSettingsSection(
            context,
            title: '关于',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.info,
                title: '应用信息',
                subtitle: '版本号、开发者信息等',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AppInfoPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
