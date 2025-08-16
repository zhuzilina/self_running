import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 个人信息设置
          _buildSettingsSection(
            context,
            title: '个人信息',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.person,
                title: '默认个人信息',
                subtitle: '设置昵称、口号、头像等默认值',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 应用设置
          _buildSettingsSection(
            context,
            title: '应用设置',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.notifications,
                title: '通知设置',
                subtitle: '管理推送通知和提醒',
                onTap: () {
                  // TODO: 实现通知设置页面
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('功能开发中...')));
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.privacy_tip,
                title: '隐私设置',
                subtitle: '管理数据隐私和权限',
                onTap: () {
                  // TODO: 实现隐私设置页面
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('功能开发中...')));
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
                  // TODO: 实现应用信息页面
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('功能开发中...')));
                },
              ),
              _buildSettingsItem(
                context,
                icon: Icons.help,
                title: '帮助与反馈',
                subtitle: '使用帮助和问题反馈',
                onTap: () {
                  // TODO: 实现帮助页面
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('功能开发中...')));
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
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
