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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../data/models/diary.dart';
import '../../data/models/audio_file.dart';
import '../../data/models/user_daily_data.dart';
import '../../presentation/states/providers.dart';

/// 日记内容查看浮窗
class DiaryContentDialog extends StatelessWidget {
  final String content;
  final String title;

  const DiaryContentDialog({
    super.key,
    required this.content,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 内容
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 裁切文本组件
class TruncatedText extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String title;

  const TruncatedText({
    super.key,
    required this.text,
    required this.maxLines,
    this.style,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用简单的文本长度估算，避免TextDirection问题
        final textStyle = style ?? const TextStyle(fontSize: 16, height: 1.6);
        final estimatedCharsPerLine = (constraints.maxWidth / 12)
            .floor(); // 估算每行字符数
        final estimatedLines = (text.length / estimatedCharsPerLine).ceil();

        // 检查是否需要截断
        if (estimatedLines > maxLines) {
          // 文本被裁切，显示"查看更多"
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    DiaryContentDialog(content: text, title: title),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: textStyle,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '查看更多',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else {
          // 文本未超出，直接显示
          return Text(text, style: textStyle);
        }
      },
    );
  }
}

class DiaryDetailPage extends ConsumerStatefulWidget {
  final Diary diary;
  final List<Diary>? allDiaries;
  final List<Diary>? pinnedDiaries; // 新增置顶日记参数
  final int initialIndex;
  final bool isFromPinned; // 新增标识是否来自置顶列表

  const DiaryDetailPage({
    super.key,
    required this.diary,
    this.allDiaries,
    this.pinnedDiaries, // 新增置顶日记参数
    this.initialIndex = 0,
    this.isFromPinned = false, // 新增标识是否来自置顶列表
  });

  @override
  ConsumerState<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends ConsumerState<DiaryDetailPage> {
  late PageController _pageController;
  int _currentDiaryIndex = 0;
  int _currentPage = 0; // 图片轮播的当前页

  @override
  void initState() {
    super.initState();
    // 添加调试信息
    assert(() {
      assert(() {
        print('🚀 DiaryDetailPage 初始化:');
        return true;
      }());
      assert(() {
        print('  - isFromPinned: ${widget.isFromPinned}');
        return true;
      }());
      assert(() {
        print('  - allDiaries 数量: ${widget.allDiaries?.length ?? 0}');
        return true;
      }());
      assert(() {
        print('  - pinnedDiaries 数量: ${widget.pinnedDiaries?.length ?? 0}');
        return true;
      }());
      assert(() {
        print('  - initialIndex: ${widget.initialIndex}');
        return true;
      }());
      return true;
    }());

    // 根据来源决定使用哪个数据源
    List<Diary>? targetDiaries;
    if (widget.isFromPinned) {
      targetDiaries = widget.pinnedDiaries;
      assert(() {
        assert(() {
          print('  - 使用置顶日记数据源');
          return true;
        }());
        return true;
      }());
    } else {
      targetDiaries = widget.allDiaries;
      assert(() {
        assert(() {
          print('  - 使用普通日记数据源');
          return true;
        }());
        return true;
      }());
    }

    // 安全检查初始索引
    if (targetDiaries != null && targetDiaries.isNotEmpty) {
      _currentDiaryIndex = widget.initialIndex.clamp(
        0,
        targetDiaries.length - 1,
      );
      assert(() {
        assert(() {
          print('  - 设置初始页面索引: $_currentDiaryIndex');
          return true;
        }());
        return true;
      }());
    } else {
      _currentDiaryIndex = 0;
      assert(() {
        assert(() {
          print('  - 使用默认页面索引: $_currentDiaryIndex');
          return true;
        }());
        return true;
      }());
    }
    _pageController = PageController(initialPage: _currentDiaryIndex);
    assert(() {
      assert(() {
        print('  ✅ 初始化完成');
        return true;
      }());
      return true;
    }());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 格式化步数显示，添加千分隔符
  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  // 将英文星期转换为中文格式
  String _getChineseWeekday(DateTime date) {
    final weekday = date.weekday;
    switch (weekday) {
      case 1:
        return '周一';
      case 2:
        return '周二';
      case 3:
        return '周三';
      case 4:
        return '周四';
      case 5:
        return '周五';
      case 6:
        return '周六';
      case 7:
        return '周天';
      default:
        return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据来源决定使用哪个数据源
    List<Diary>? targetDiaries;
    if (widget.isFromPinned) {
      targetDiaries = widget.pinnedDiaries;
    } else {
      targetDiaries = widget.allDiaries;
    }

    // 如果没有目标数据源，显示单页
    if (targetDiaries == null || targetDiaries.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildDiaryContent(widget.diary),
      );
    }

    // 使用PageView显示多页
    return Scaffold(
      appBar: _buildAppBar(),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: targetDiaries!.length, // 这里已经检查过非空
        onPageChanged: (index) {
          setState(() {
            _currentDiaryIndex = index;
          });
          assert(() {
            assert(() {
              print('📄 PageView 页面切换:');
              return true;
            }());
            assert(() {
              print('  - 从页面: $_currentDiaryIndex');
              return true;
            }());
            assert(() {
              print('  - 到页面: $index');
              return true;
            }());
            assert(() {
              print('  - 总页面数: ${targetDiaries!.length}');
              return true;
            }()); // 这里已经检查过非空
            assert(() {
              print('  - 数据源: ${widget.isFromPinned ? "置顶日记" : "普通日记"}');
              return true;
            }());
            assert(() {
              print('  ✅ 页面切换成功');
              return true;
            }());
            return true;
          }());
        },
        itemBuilder: (context, index) {
          final diary = targetDiaries![index]; // 这里已经检查过非空
          return _buildDiaryContent(diary);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Consumer(
        builder: (context, ref, child) {
          // 获取当前显示的日记
          List<Diary>? targetDiaries;
          if (widget.isFromPinned) {
            targetDiaries = widget.pinnedDiaries;
          } else {
            targetDiaries = widget.allDiaries;
          }

          final currentDiary = targetDiaries != null && targetDiaries.isNotEmpty
              ? targetDiaries[_currentDiaryIndex]
              : widget.diary;

          final userDataAsync = ref.watch(userDailyDataRankingProvider);

          return userDataAsync.when(
            loading: () => Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '加载中...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            error: (_, __) => Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.error, size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '加载失败',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            data: (userDataList) {
              // 查找与当前日记日期对应的用户数据
              UserDailyData? userData;
              try {
                userData = userDataList.firstWhere(
                  (data) =>
                      data.date.year == currentDiary.date.year &&
                      data.date.month == currentDiary.date.month &&
                      data.date.day == currentDiary.date.day,
                );
              } catch (e) {
                // 如果找不到对应日期的数据，使用第一条数据作为默认值
                userData = userDataList.isNotEmpty ? userDataList.first : null;
              }

              if (userData == null) {
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '未知用户',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  // 用户头像
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: userData.avatarPath != null
                        ? FileImage(File(userData.avatarPath!))
                        : null,
                    child: userData.avatarPath == null
                        ? Text(
                            userData.nickname.isNotEmpty
                                ? userData.nickname[0]
                                : '我',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // 用户昵称
                  Expanded(
                    child: Text(
                      userData.nickname.isNotEmpty ? userData.nickname : '我的日记',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 步数显示
                  Text(
                    _formatSteps(userData.steps),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDiaryContent(Diary diary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 轮播图（如果有图片）
          if (diary.images.isNotEmpty) ...[
            _buildImageCarousel(
              diary.images.map((img) => img.originalPath).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // 用户slogan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Consumer(
              builder: (context, ref, child) {
                final userDataAsync = ref.watch(userDailyDataRankingProvider);
                return userDataAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (userDataList) {
                    // 查找与日记日期对应的用户数据
                    UserDailyData? userData;
                    try {
                      userData = userDataList.firstWhere(
                        (data) =>
                            data.date.year == diary.date.year &&
                            data.date.month == diary.date.month &&
                            data.date.day == diary.date.day,
                      );
                    } catch (e) {
                      userData = userDataList.isNotEmpty
                          ? userDataList.first
                          : null;
                    }

                    if (userData?.slogan == null || userData!.slogan.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              userData.slogan,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // 置顶按钮
                        Consumer(
                          builder: (context, ref, child) {
                            final pinnedDiariesAsync = ref.watch(
                              pinnedDiariesProvider,
                            );
                            return pinnedDiariesAsync.when(
                              loading: () => Text(
                                '置顶',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              error: (_, __) => Text(
                                '置顶',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              data: (pinnedDiaries) {
                                final isPinned = pinnedDiaries.any(
                                  (diaryItem) => diaryItem.id == diary.id,
                                );
                                return GestureDetector(
                                  onTap: () async {
                                    final service = ref.read(
                                      pinnedDiaryServiceProvider,
                                    );
                                    await service.init();

                                    if (isPinned) {
                                      await service.unpinDiary(
                                        int.tryParse(diary.id) ?? 0,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('已取消置顶'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      await service.pinDiary(
                                        int.tryParse(diary.id) ?? 0,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('已将日记置顶'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }

                                    // 刷新置顶列表
                                    ref.invalidate(pinnedDiariesProvider);
                                  },
                                  child: Text(
                                    isPinned ? '取消置顶' : '置顶',
                                    style: TextStyle(
                                      color: isPinned
                                          ? Colors.grey[600]
                                          : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 日期信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  DateFormat('yyyy年MM月dd日').format(diary.date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Text(
                  _getChineseWeekday(diary.date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (diary.updatedAt != null)
                  Text(
                    '更新于 ${DateFormat('HH:mm').format(diary.updatedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 音频文件区域（如果有音频）
          if (diary.audioFiles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildAudioSection(diary.audioFiles),
            ),
            const SizedBox(height: 20),
          ],

          // 分割线（始终显示）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),

          // 正文部分
          if (diary.content.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TruncatedText(
                text: diary.content,
                maxLines: 5,
                title: '日记内容',
              ),
            ),
          ],

          // 锁定状态
          if (!diary.isEditable) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      '已锁定',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imagePaths) {
    return Container(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ImagePreviewPage(
                        imagePaths: imagePaths,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  color: Colors.grey[200],
                  child: FutureBuilder<File>(
                    future: Future.value(File(imagePaths[index])),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.existsSync()) {
                        final file = snapshot.data!;
                        return Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            assert(() {
                              assert(() {
                                print('图片加载错误: $error');
                                return true;
                              }());
                              assert(() {
                                print('图片路径: ${file.path}');
                                return true;
                              }());
                              return true;
                            }());
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '图片加载失败',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
          // 右上角指示器文字
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${imagePaths.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(List<AudioFile> audioFiles) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 两行横向瀑布流布局
        Container(
          height: 80, // 两行高度：32px * 2 + 间距
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // 横向滚动
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: audioFiles
                      .asMap()
                      .entries
                      .where((entry) => entry.key.isEven)
                      .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 4),
                          child: _buildAudioItem(entry.value),
                        );
                      })
                      .toList(),
                ),
                // 第二行
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: audioFiles
                      .asMap()
                      .entries
                      .where((entry) => entry.key.isOdd)
                      .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4, top: 4),
                          child: _buildAudioItem(entry.value),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioItem(AudioFile audioFile) {
    return AudioPlayerWidget(audioFile: audioFile);
  }
}

class ImagePreviewPage extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  final Map<int, PhotoViewController> _photoViewControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // 为每个图片创建PhotoViewController
    for (int i = 0; i < widget.imagePaths.length; i++) {
      _photoViewControllers[i] = PhotoViewController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // 释放所有PhotoViewController
    for (var controller in _photoViewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片轮播
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(widget.imagePaths[index])),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: widget.imagePaths[index],
                ),
                controller: _photoViewControllers[index],
                onTapUp: (_, __, ___) {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                errorBuilder: (context, error, stackTrace) {
                  assert(() {
                    assert(() {
                      print('图片预览加载错误: $error');
                      return true;
                    }());
                    assert(() {
                      print('图片路径: ${widget.imagePaths[index]}');
                      return true;
                    }());
                    return true;
                  }());
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.white, size: 50),
                          SizedBox(height: 16),
                          Text(
                            '图片加载失败',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            itemCount: widget.imagePaths.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            pageController: _pageController,
            onPageChanged: _onPageChanged,
          ),
          // 控制栏
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentIndex + 1}/${widget.imagePaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 音频播放器管理器（单例模式）
class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal();

  final Set<_AudioPlayerWidgetState> _activePlayers = {};

  void registerPlayer(_AudioPlayerWidgetState player) {
    _activePlayers.add(player);
  }

  void unregisterPlayer(_AudioPlayerWidgetState player) {
    _activePlayers.remove(player);
  }

  void stopOtherPlayers(_AudioPlayerWidgetState currentPlayer) {
    for (final player in _activePlayers) {
      if (player != currentPlayer) {
        player.stopAndReset();
      }
    }
  }
}

/// 音频播放器组件
class AudioPlayerWidget extends StatefulWidget {
  final AudioFile audioFile;

  const AudioPlayerWidget({super.key, required this.audioFile});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    AudioPlayerManager().registerPlayer(this);

    _audioPlayer!.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
      _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    AudioPlayerManager().unregisterPlayer(this);
    super.dispose();
  }

  void stopAndReset() {
    _audioPlayer?.stop();
    setState(() {
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
    _timer?.cancel();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      // 暂停播放
      await _audioPlayer?.pause();
      setState(() {
        _isPlaying = false;
      });
      _timer?.cancel();
    } else {
      // 开始播放
      AudioPlayerManager().stopOtherPlayers(this);

      if (_currentPosition.inMilliseconds >= widget.audioFile.duration ||
          _currentPosition.inMilliseconds == 0) {
        // 重新开始播放
        await _audioPlayer?.setSource(
          DeviceFileSource(widget.audioFile.filePath),
        );
        await _audioPlayer?.resume();
        setState(() {
          _isPlaying = true;
          _currentPosition = Duration.zero;
        });
      } else {
        // 继续播放
        await _audioPlayer?.resume();
        setState(() {
          _isPlaying = true;
        });
      }

      // 启动定时器更新进度
      _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        if (_isPlaying) {
          setState(() {
            _currentPosition += const Duration(milliseconds: 150);
          });
        }
      });
    }
  }

  // 根据音频时长计算宽度
  double _calculateWidth() {
    final durationSeconds = widget.audioFile.duration / 1000;
    const minWidth = 120.0; // 最小宽度：能装下6个字符 + 播放图标 + 间距
    const maxWidth = 200.0; // 最大宽度
    const minDuration = 1.0; // 最小时长（1秒）
    const maxDuration = 120.0; // 最大时长（2分钟）

    // 线性插值计算宽度
    final ratio = (durationSeconds - minDuration) / (maxDuration - minDuration);
    final clampedRatio = ratio.clamp(0.0, 1.0);

    return minWidth + (maxWidth - minWidth) * clampedRatio;
  }

  Widget _buildDefaultView() {
    if (_isPlaying) {
      return const SizedBox.shrink(); // 播放时隐藏图标和文字
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          widget.audioFile.displayName,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _currentPosition.inMilliseconds / widget.audioFile.duration;
    final width = _calculateWidth();

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: width,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          children: [
            // 进度条
            if (_isPlaying)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LinearPercentIndicator(
                    width: width - 2,
                    lineHeight: 32,
                    percent: progress.clamp(0.0, 1.0),
                    progressColor: Colors.grey[400]!,
                    backgroundColor: Colors.transparent,
                    barRadius: const Radius.circular(16),
                    animation: false,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            // 内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildDefaultView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
