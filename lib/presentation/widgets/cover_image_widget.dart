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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/providers.dart';
import 'edit_cover_image_dialog.dart';

class CoverImageWidget extends ConsumerStatefulWidget {
  const CoverImageWidget({super.key});

  @override
  ConsumerState<CoverImageWidget> createState() => _CoverImageWidgetState();
}

class _CoverImageWidgetState extends ConsumerState<CoverImageWidget> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => Container(
        height: double.infinity, // 使用无限高度以适应SliverAppBar
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(0), // 去掉圆角，完全填充
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        height: double.infinity, // 使用无限高度以适应SliverAppBar
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(0), // 去掉圆角，完全填充
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text('加载失败：$error'),
            ],
          ),
        ),
      ),
      data: (profile) => GestureDetector(
        onTap: () => _showEditCoverImageDialog(context, ref, profile),
        child: Container(
          height: double.infinity, // 使用无限高度以适应SliverAppBar
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0), // 去掉圆角，完全填充
            image: profile.coverImage != null
                ? DecorationImage(
                    image: _getCoverImageProvider(profile.coverImage!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // 如果图片加载失败，使用默认渐变背景
                    },
                  )
                : null,
            gradient: profile.coverImage == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                      Colors.purple.shade600,
                    ],
                  )
                : null,
          ),
          child: Stack(
            children: [
              // 背景装饰（仅在默认背景时显示）
              if (profile.coverImage == null) ...[
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // 跑步图标
                Center(
                  child: Icon(
                    Icons.directions_run,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                // 装饰性文字
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    '今日跑步',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditCoverImageDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          EditCoverImageDialog(currentCoverImage: profile.coverImage),
    );

    if (result == true) {
      ref.invalidate(userProfileProvider);
    }
  }

  ImageProvider _getCoverImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    } else {
      return FileImage(File(imagePath));
    }
  }
}
