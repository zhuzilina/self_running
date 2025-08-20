import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoPage extends ConsumerWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用信息'),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用图标和名称
          _buildAppHeader(),
          const SizedBox(height: 24),

          // 应用简介
          _buildAppDescription(),
          const SizedBox(height: 24),

          // 免责声明
          _buildDisclaimer(),
          const SizedBox(height: 24),

          // 开源信息
          _buildOpenSourceInfo(),
          const SizedBox(height: 24),

          // 项目地址
          _buildProjectLink(),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/icon.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          const Text(
            'Self Running',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '和过去的自己赛跑',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '版本 1.0.0',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            '榆见晴天',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDescription() {
    return _buildSection(
      title: '应用简介',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本应用致力于帮助用户记录每天的美好瞬间，包括文字、图像、声音等内容。通过记录用户的日常趣事和步数数据，本应用可以：',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('整理并生成可阅读、可搜索的记忆卡片，帮助用户回顾和保存重要回忆'),
          const SizedBox(height: 8),
          _buildBulletPoint('通过步数排行榜，帮助用户与过去的自己"相遇"，体验时光的流动与变化'),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return _buildSection(
      title: '免责声明',
      icon: Icons.warning_outlined,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          '本应用为开源软件，仅供学习和个人使用。开发者不对使用本应用产生的任何后果承担责任。用户应自行承担使用风险，并遵守相关法律法规。',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.orange.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildOpenSourceInfo() {
    return _buildSection(
      title: '开源信息',
      icon: Icons.code,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本应用为开源软件，基于 Apache License 2.0 许可证发布。',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () =>
                _launchUrl('https://www.apache.org/licenses/LICENSE-2.0'),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Apache License 2.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectLink() {
    return _buildSection(
      title: '项目地址',
      icon: Icons.link,
      child: InkWell(
        onTap: () =>
            _launchUrl('https://github.com/zhuzilina/self_running.git'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.link, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'https://github.com/zhuzilina/self_running.git',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw '无法打开链接';
      }
    } catch (e) {
      // 如果url_launcher不可用，可以显示一个对话框
      debugPrint('无法打开链接: $e');
    }
  }
}
