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
import 'dart:io';
import '../states/providers.dart';
import '../pages/diary_page.dart';

class DiaryCard extends ConsumerWidget {
  const DiaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryAsync = ref.watch(todayDiaryProvider);
    final todayEditable = ref.watch(todayEditableProvider);

    return diaryAsync.when(
      loading: () => _buildCard(
        context,
        content: '加载中...',
        isEmpty: true,
        imagePaths: [],
        isEditable: true,
      ),
      error: (e, _) => _buildCard(
        context,
        content: '加载失败',
        isEmpty: true,
        imagePaths: [],
        isEditable: true,
      ),
      data: (diary) {
        if (diary == null || diary.content.isEmpty) {
          return _buildCard(
            context,
            content: '点击添加今日记录',
            isEmpty: true,
            imagePaths: [],
            isEditable: true,
          );
        }

        // 限制显示三行文本
        final lines = diary.content.split('\n');
        String displayText = diary.content;

        if (lines.length > 3) {
          // 如果超过三行，取前三行并添加省略号
          displayText = lines.take(3).join('\n');
          if (displayText.length > 100) {
            // 如果前三行总长度超过100字符，截断并添加省略号
            displayText = displayText.substring(0, 100) + '...';
          } else {
            displayText += '...';
          }
        } else if (diary.content.length > 100) {
          // 如果内容超过100字符，截断并添加省略号
          displayText = diary.content.substring(0, 100) + '...';
        }

        return todayEditable.when(
          loading: () => _buildCard(
            context,
            content: displayText,
            isEmpty: false,
            imagePaths: diary.imagePaths,
            isEditable: true,
          ),
          error: (_, __) => _buildCard(
            context,
            content: displayText,
            isEmpty: false,
            imagePaths: diary.imagePaths,
            isEditable: true,
          ),
          data: (editable) => _buildCard(
            context,
            content: displayText,
            isEmpty: false,
            imagePaths: diary.imagePaths,
            isEditable: editable,
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String content,
    required bool isEmpty,
    required List<String> imagePaths,
    required bool isEditable,
  }) {
    return GestureDetector(
      onTap: isEditable
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DiaryPage()),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isEditable
              ? Colors.white.withOpacity(0.9)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEditable ? Icons.edit_note : Icons.lock,
                          color: isEmpty
                              ? Colors.grey.shade400
                              : (isEditable
                                    ? Colors.black87
                                    : Colors.grey.shade600),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditable ? '今日记录' : '今日记录（已锁定）',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isEmpty
                                ? Colors.grey.shade400
                                : (isEditable
                                      ? Colors.black87
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isEmpty
                            ? Colors.grey.shade400
                            : (isEditable
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade600),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (imagePaths.isNotEmpty) ...[
                const SizedBox(width: 12),
                _buildImageGrid(imagePaths),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imagePaths) {
    // 最多显示4张图片
    final displayImages = imagePaths.take(4).toList();
    const gridSize = 32.0; // 每个缩略图的大小（缩小到32x32）
    const spacing = 2.0; // 图片间距

    return Container(
      width: gridSize * 2 + spacing, // 2列
      height: gridSize * 2 + spacing, // 2行
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: displayImages.asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;

          return FutureBuilder<bool>(
            future: File(imagePath).exists(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return Container(
                  width: gridSize,
                  height: gridSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              } else {
                // 如果图片不存在，显示占位符
                return Container(
                  width: gridSize,
                  height: gridSize,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.image,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
