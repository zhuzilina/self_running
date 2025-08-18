import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import '../states/providers.dart';
import '../../data/models/diary.dart';
import '../../data/models/audio_file.dart';
import '../../data/models/user_daily_data.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'diary_detail_page.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final diariesAsync = searchQuery.isEmpty
        ? ref.watch(allDiariesProvider)
        : ref.watch(searchDiariesProvider(searchQuery));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            boxShadow: [],
          ),
          child: TextField(
            controller: _searchController,
            cursorColor: Colors.grey.withOpacity(0.7),
            decoration: InputDecoration(
              hintText: '搜索日记内容、日期或数字...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(allDiariesProvider);
        },
        child: diariesAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载日记数据...'),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('加载失败：$e'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allDiariesProvider),
                  child: Text('重试'),
                ),
              ],
            ),
          ),
          data: (diaries) {
            if (diaries.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty ? '未找到相关日记' : '暂无足迹记录',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          searchQuery.isNotEmpty ? '尝试使用其他关键词搜索' : '开始记录你的每一天',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // 按日期排序，最新的在前面
            final sortedDiaries = List<Diary>.from(diaries)
              ..sort((a, b) => b.date.compareTo(a.date));

            // 获取置顶日记ID列表
            final pinnedDiariesAsync = ref.watch(pinnedDiariesProvider);
            final pinnedDiaryIds = pinnedDiariesAsync.when(
              data: (pinnedDiaries) => pinnedDiaries.map((d) => d.id).toSet(),
              loading: () => <String>{},
              error: (_, __) => <String>{},
            );

            // 过滤掉已置顶的日记
            final nonPinnedDiaries = sortedDiaries
                .where((diary) => !pinnedDiaryIds.contains(diary.id))
                .toList();

            // 按年份和月份分组
            final groupedDiaries = _groupDiariesByYearMonth(nonPinnedDiaries);

            return CustomScrollView(
              slivers: [
                // 置顶日记
                Consumer(
                  builder: (context, ref, child) {
                    final pinnedDiariesAsync = ref.watch(pinnedDiariesProvider);
                    return pinnedDiariesAsync.when(
                      loading: () =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                      error: (_, __) =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                      data: (pinnedDiaries) {
                        if (pinnedDiaries.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }

                        return SliverStickyHeader(
                          header: Container(
                            height: 50.0,
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '置顶',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final diary = pinnedDiaries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: _buildDiaryCard(
                                  context,
                                  diary,
                                  ref,
                                  diaries,
                                ),
                              );
                            }, childCount: pinnedDiaries.length),
                          ),
                        );
                      },
                    );
                  },
                ),
                // 日记列表
                ...groupedDiaries.entries.map((entry) {
                  final yearMonth = entry.key;
                  final diariesInMonth = entry.value;

                  return SliverStickyHeader(
                    header: Container(
                      height: 50.0,
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        yearMonth,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final diary = diariesInMonth[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: _buildDiaryCard(context, diary, ref, diaries),
                        );
                      }, childCount: diariesInMonth.length),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiaryCard(
    BuildContext context,
    Diary diary,
    WidgetRef ref,
    List<Diary> allDiaries,
  ) {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final timeFormat = DateFormat('HH:mm');

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
          return '周日';
        default:
          return '未知';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiaryDetailPage(
              diary: diary,
              allDiaries: allDiaries,
              initialIndex: allDiaries.indexOf(diary),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像和昵称信息
              Consumer(
                builder: (context, ref, child) {
                  final userDataAsync = ref.watch(userDailyDataRankingProvider);
                  return userDataAsync.when(
                    loading: () => Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '加载中...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    error: (error, stack) => Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '加载失败',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
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

                      if (userData == null) {
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '未知用户',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const Spacer(),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: userData.avatarPath != null
                                ? FileImage(File(userData.avatarPath!))
                                : null,
                            child: userData.avatarPath == null
                                ? Text(
                                    userData.nickname.isNotEmpty
                                        ? userData.nickname[0]
                                        : '我',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userData.nickname.isNotEmpty
                                  ? userData.nickname
                                  : '我的日记',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Spacer(),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 12),

              // 日记内容
              if (diary.content.isNotEmpty) ...[
                Text(
                  diary.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
              ],

              // 媒体文件区域
              if (diary.images.isNotEmpty || diary.audioFiles.isNotEmpty) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 音频文件数量显示
                    if (diary.audioFiles.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${diary.audioFiles.length}个声音',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // 图片预览区域
                    if (diary.images.isNotEmpty) ...[
                      _buildImageGrid(diary.thumbnailPaths),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // 锁定状态
              if (!diary.isEditable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '已锁定',
                    style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                  ),
                ),

              // 日期和时间信息（移到末尾）
              Row(
                children: [
                  Text(
                    dateFormat.format(diary.date),
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
                      '更新于 ${timeFormat.format(diary.updatedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imagePaths) {
    // 限制最多显示9张图片
    final displayImages = imagePaths.take(9).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: displayImages.length, // 只显示实际图片数量
      itemBuilder: (context, index) {
        return _buildImageWidget(displayImages[index]);
      },
    );
  }

  Widget _buildImageWidget(String imagePath) {
    return Container(
      color: Colors.grey[200],
      child: FutureBuilder<File>(
        future: Future.value(File(imagePath)),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.existsSync()) {
            return ClipRect(
              child: Image.file(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            );
          } else {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, color: Colors.grey),
            );
          }
        },
      ),
    );
  }

  Map<String, List<Diary>> _groupDiariesByYearMonth(List<Diary> diaries) {
    final Map<String, List<Diary>> grouped = {};

    for (final diary in diaries) {
      final year = diary.date.year;
      final month = diary.date.month;

      // 生成标题：跨年时显示年份，跨月时显示月份
      String title;
      if (year != DateTime.now().year) {
        // 跨年时显示年份
        title = '$year年';
      } else {
        // 跨月时显示月份
        final monthNames = [
          '一月',
          '二月',
          '三月',
          '四月',
          '五月',
          '六月',
          '七月',
          '八月',
          '九月',
          '十月',
          '十一月',
          '十二月',
        ];
        title = monthNames[month - 1];
      }

      if (!grouped.containsKey(title)) {
        grouped[title] = [];
      }
      grouped[title]!.add(diary);
    }

    return grouped;
  }
}

// 全局音频播放管理器
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
    for (var player in _activePlayers) {
      if (player != currentPlayer) {
        player.stopAndReset();
      }
    }
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final AudioFile audioFile;

  const AudioPlayerWidget({super.key, required this.audioFile});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  bool _isInitialized = false;
  AudioPlayer? _audioPlayer;
  Timer? _playTimer;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    AudioPlayerManager().registerPlayer(this);
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();

      // 监听播放完成事件
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          _playTimer?.cancel();
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero; // 播放完成后重置进度
          });
        }
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ 音频播放器初始化失败: $e');
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _audioPlayer?.dispose();
    AudioPlayerManager().unregisterPlayer(this);
    super.dispose();
  }

  void stopAndReset() async {
    if (_isPlaying || _currentPosition.inMilliseconds > 0) {
      // 停止播放器
      await _audioPlayer?.stop();
      // 取消计时器
      _playTimer?.cancel();
      // 重置状态
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    }
  }

  // 缓动函数：更平缓的先快后缓
  double _easeOutCubic(double t) {
    // 使用更平缓的指数，从3改为2，让增长更温和
    return 1 - pow(1 - t, 2).toDouble();
  }

  void _togglePlay() async {
    if (!_isInitialized || _audioPlayer == null) {
      return;
    }

    try {
      if (_isPlaying) {
        // 暂停播放
        await _audioPlayer!.pause();
        _playTimer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // 停止其他播放器
        AudioPlayerManager().stopOtherPlayers(this);

        // 等待一小段时间确保其他播放器停止
        await Future.delayed(const Duration(milliseconds: 50));

        if (_currentPosition.inMilliseconds >= widget.audioFile.duration ||
            _currentPosition.inMilliseconds == 0) {
          // 如果播放完成或首次播放，设置音频源并开始播放
          await _audioPlayer!.setSource(
            DeviceFileSource(widget.audioFile.filePath),
          );
          await _audioPlayer!.resume();
          setState(() {
            _isPlaying = true;
            _currentPosition = Duration.zero;
          });
        } else {
          // 继续播放
          await _audioPlayer!.resume();
          setState(() {
            _isPlaying = true;
          });
        }

        // 启动播放计时器
        _playTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
          if (!_isPlaying) {
            timer.cancel();
            return;
          }

          setState(() {
            _currentPosition += const Duration(milliseconds: 150);
          });

          // 检查是否播放完成 - 只更新进度，不重置状态
          if (_currentPosition.inMilliseconds >= widget.audioFile.duration) {
            timer.cancel();
            // 不在这里重置状态，让 onPlayerComplete 事件处理
          }
        });
      }
    } catch (e) {
      print('❌ 播放控制失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据音频长度计算宽度 - 先快后缓的非线性映射
    final minDuration = 1000; // 1秒
    final maxDuration = 300000; // 5分钟
    final minWidth = 80.0; // 最小宽度
    final maxWidth = 200.0; // 最大宽度

    // 使用对数函数实现先快后缓的效果
    // 将时长映射到对数空间，然后归一化
    final logMinDuration = log(minDuration.toDouble());
    final logMaxDuration = log(maxDuration.toDouble());
    final logCurrentDuration = log(widget.audioFile.duration.toDouble());

    // 计算对数空间的比例
    final logRatio =
        (logCurrentDuration - logMinDuration) /
        (logMaxDuration - logMinDuration);
    final clampedLogRatio = logRatio.clamp(0.0, 1.0);

    // 应用缓动函数，让短音频增长更快，长音频增长更慢
    final easedRatio = _easeOutCubic(clampedLogRatio);
    final width = minWidth + (maxWidth - minWidth) * easedRatio;

    // 计算播放进度
    final progress =
        _currentPosition.inMilliseconds / widget.audioFile.duration;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        width: width,
        height: 32, // 还原高度
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // 还原圆角
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Stack(
          children: [
            // 背景层（未播放部分）
            Container(
              width: width,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // 进度层（使用 LinearPercentIndicator）
            LinearPercentIndicator(
              width: width - 2, // 减去边框宽度
              lineHeight: 30, // 减去边框高度
              percent: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              progressColor: Colors.grey[400]!,
              barRadius: const Radius.circular(15),
              padding: const EdgeInsets.all(1), // 留出边框空间
              animation: false, // 关闭动画，避免抖动
            ),
            // 内容层
            Container(width: width, height: 32, child: _buildDefaultView()),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultView() {
    // 播放时保持进度条UI，只显示点击区域
    if (_isPlaying) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isInitialized ? Icons.play_arrow : Icons.volume_up,
            size: 16,
            color: _isInitialized ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.audioFile.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _isInitialized ? Colors.grey[700] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
