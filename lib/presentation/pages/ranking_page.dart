import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_steps.dart';
import '../states/providers.dart';
import '../widgets/ranking_cover_widget.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyStepsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final coverHeight = screenHeight * 0.45; // 45%的屏幕高度

    return dailyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (data) {
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (profile) {
            return _buildRankingList(data, coverHeight, profile);
          },
        );
      },
    );
  }

  Widget _buildRankingList(
    List<DailySteps> data,
    double coverHeight,
    dynamic profile,
  ) {
    // 去掉数量判断，即使只有一天的数据也应该显示排行

    final sorted = List<DailySteps>.from(data)
      ..sort((b, a) => a.steps - b.steps);
    final today = data.isNotEmpty ? data.last : null;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 封面卡片区域
        SizedBox(height: coverHeight, child: const RankingCoverWidget()),

        // 内容区域
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // 用户信息卡片
              if (data.isNotEmpty && today != null) ...[
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 用户头像
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: profile.avatar != null
                            ? ClipOval(
                                child: _buildAvatarImage(profile.avatar!),
                              )
                            : const Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 16),
                      // 用户信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 用户昵称
                            Text(
                              profile.nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // 今日步数
                            Text(
                              _formatSteps(today.steps),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: today.steps >= 10000
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: today.steps >= 10000
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 排名信息
                      Text(
                        '${_getTodayRank(sorted, today)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 分割线
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ],

              // 排行列表
              ...sorted.map((d) {
                final rank = sorted.indexOf(d) + 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 头像列
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade100,
                            child: profile.avatar != null
                                ? ClipOval(
                                    child: _buildAvatarImage(profile.avatar!),
                                  )
                                : const Icon(Icons.person, size: 25),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // 昵称列
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profile.nickname,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.slogan,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${d.localDay.year}-${d.localDay.month.toString().padLeft(2, '0')}-${d.localDay.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 步数列
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _formatSteps(d.steps),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: d.steps >= 10000
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: d.steps >= 10000
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // 排名列
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$rank',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // 底部留白
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 25),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 25),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 25),
      );
    }
  }

  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  int _getTodayRank(List<DailySteps> sorted, DailySteps today) {
    final todayIndex = sorted.indexWhere((d) => d.localDay == today.localDay);
    return todayIndex >= 0 ? todayIndex + 1 : 0;
  }
}
