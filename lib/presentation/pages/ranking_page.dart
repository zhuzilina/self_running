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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_steps.dart';
import '../../data/models/user_daily_data.dart';
import '../states/providers.dart';
import '../widgets/ranking_cover_widget.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDailyDataRankingProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final coverHeight = screenHeight * 0.45; // 45%的屏幕高度

    return userDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (userDataList) {
        return profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (profile) {
            return _buildRankingList(userDataList, coverHeight, profile);
          },
        );
      },
    );
  }

  Widget _buildRankingList(
    List<UserDailyData> userDataList,
    double coverHeight,
    dynamic profile,
  ) {
    // 添加调试信息
    assert(() {
      print('RankingPage: 加载到 ${userDataList.length} 条用户数据');
      return true;
    }());
    for (final data in userDataList) {
      assert(() {
        print('RankingPage: ${data.date} - ${data.nickname} - ${data.steps} 步');
        return true;
      }());
    }

    // 按步数排序，步数多的在前面
    final sorted = List<UserDailyData>.from(userDataList)
      ..sort((b, a) => a.steps - b.steps);

    // 获取今日数据（最新的数据）
    final today = userDataList.isNotEmpty ? userDataList.first : null;

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
              // 调试信息卡片（仅在开发模式下显示）
              if (userDataList.isEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '暂无排行数据',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请先设置今日数据，数据将显示在这里',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              // 用户信息卡片
              if (userDataList.isNotEmpty && today != null) ...[
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
                        radius: 25,
                        backgroundColor: Colors.transparent,
                        child: today.avatarPath != null
                            ? ClipOval(
                                child: _buildAvatarImage(today.avatarPath!),
                              )
                            : const Icon(Icons.person, size: 25),
                      ),
                      const SizedBox(width: 16),
                      // 用户信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 用户昵称
                            Text(
                              today.nickname,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today.slogan,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
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
              ...sorted.map((userData) {
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
                            child: userData.avatarPath != null
                                ? ClipOval(
                                    child: _buildAvatarImage(
                                      userData.avatarPath!,
                                    ),
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
                              userData.nickname,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userData.slogan,
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
                              '${userData.date.year}-${userData.date.month.toString().padLeft(2, '0')}-${userData.date.day.toString().padLeft(2, '0')}',
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
                            _formatSteps(userData.steps),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: userData.steps >= 10000
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: userData.steps >= 10000
                                  ? Colors.black
                                  : Colors.grey.shade600,
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
}
