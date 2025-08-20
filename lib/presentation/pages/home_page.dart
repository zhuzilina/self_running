import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/providers.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/cover_image_widget.dart';
import '../widgets/diary_card.dart';
import 'ranking_page.dart';
import 'memories_page.dart';
import 'settings_page.dart';
import '../../services/health_permission_service.dart';
import '../../services/sensor_steps_service.dart';
import '../../services/realtime_steps_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 设置状态栏透明
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    // 检查运动权限
    _checkActivityPermission();

    // 初始化步数服务
    _initializeStepsServices();
  }

  /// 检查运动权限
  Future<void> _checkActivityPermission() async {
    try {
      final healthPermissionService = HealthPermissionService();

      // 检查是否设置了"不再提醒"
      final dontRemind = await healthPermissionService.isDontRemindSet();
      if (dontRemind) {
        return; // 用户选择了不再提醒，不做任何操作
      }

      // 检查运动权限
      final hasPermission = await healthPermissionService
          .checkActivityPermission();
      if (!hasPermission) {
        // 尝试请求权限
        final granted = await healthPermissionService
            .requestActivityPermission();
        if (!granted && mounted) {
          // 如果权限请求失败，显示提示对话框
          _showPermissionDialog();
        }
      }
    } catch (e) {
      print('权限检查失败: $e');
    }
  }

  /// 显示权限提示对话框
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要运动权限'),
          content: const Text('如果不授权运动健康权限则App无法记录每日步数'),
          actions: [
            TextButton(
              onPressed: () async {
                // 设置"不再提醒"
                final healthPermissionService = HealthPermissionService();
                await healthPermissionService.setDontRemind();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('不再提醒'),
            ),
            TextButton(
              onPressed: () async {
                // 打开设置页面
                final healthPermissionService = HealthPermissionService();
                await healthPermissionService.openAppSettingsPage();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('设置'),
            ),
          ],
        );
      },
    );
  }

  /// 初始化步数服务
  Future<void> _initializeStepsServices() async {
    try {
      print('Initializing steps services in HomePage...');

      // 初始化传感器步数服务
      final sensorService = SensorStepsService();
      await sensorService.initialize();

      // 初始化实时步数服务
      final realtimeService = RealtimeStepsService();
      await realtimeService.initialize();

      print('Steps services initialized in HomePage');
    } catch (e) {
      print('Error initializing steps services in HomePage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _OverviewTab(),
      const RankingPage(),
      const MemoriesPage(),
    ];
    return Scaffold(
      extendBodyBehindAppBar: _index != 2, // 只有在第三屏时不延伸到AppBar后面
      backgroundColor: Colors.white, // 设置整体背景为白色
      appBar: (_index == 1 || _index == 2)
          ? null
          : AppBar(
              // 第三屏不显示AppBar
              backgroundColor: Colors.transparent, // 完全透明背景
              elevation: 0, // 去掉阴影
              title: const Text(''), // 去掉标题
              surfaceTintColor: Colors.transparent, // 移除Material 3的表面色调
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: '主页'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: '排行'),
          NavigationDestination(icon: Icon(Icons.history), label: '足迹'),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab();

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab>
    with TickerProviderStateMixin {
  double _contentOffset = 0.0;
  static const double _maxCoverHeight = 400.0;
  static const double _minCoverHeight = 160.0; // 40%的封面高度（60%位置）

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animation.addListener(() {
      setState(() {
        _contentOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateToRest() {
    _animation = Tween<double>(begin: _contentOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward(from: 0.0);
  }

  /// 刷新步数数据
  Future<void> _refreshStepsData() async {
    try {
      print('Refreshing steps data in OverviewTab...');

      // 手动触发传感器步数服务更新
      final sensorService = SensorStepsService();
      await sensorService.refreshSteps();

      // 手动触发实时步数服务更新（现在也使用传感器）
      final realtimeService = RealtimeStepsService();
      await realtimeService.refreshTodaySteps();

      print('Steps data refreshed in OverviewTab');
    } catch (e) {
      print('Error refreshing steps data in OverviewTab: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyStepsProvider);
    final ranking = ref.watch(todayRankingProvider);
    final todayEditable = ref.watch(todayEditableProvider);

    return dailyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('同步失败：$e')),
      data: (data) {
        final today = data.isEmpty ? 0 : data.last.steps;
        final historyCount = data.length - 1;
        final percent = (1 - ranking.percentile) * 100;

        // 计算封面图片的缩放比例（最大5%放大）
        final scale =
            1.0 + (_contentOffset / (_maxCoverHeight - _minCoverHeight)) * 0.05;

        return RefreshIndicator(
          onRefresh: () async {
            // 刷新步数数据
            await _refreshStepsData();
            // 刷新Provider数据
            ref.invalidate(dailyStepsProvider);
            await ref.read(dailyStepsProvider.future);
          },
          child: Stack(
            children: [
              // 动态缩放的封面图片
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 400,
                child: Transform.scale(
                  scale: scale,
                  child: const CoverImageWidget(),
                ),
              ),
              // 动态定位的内容区域
              Positioned(
                top: _contentOffset + 240, // 从封面卡片的60%位置开始
                left: 0,
                right: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    // 只处理下拉展开效果，添加阻尼
                    if (details.delta.dy > 0) {
                      // 向下滑动，添加阻尼效果（减少响应敏感度）
                      final dampedDelta = details.delta.dy * 0.6; // 阻尼系数0.6
                      final newOffset = (_contentOffset + dampedDelta).clamp(
                        0.0,
                        _maxCoverHeight - _minCoverHeight,
                      );
                      if (newOffset != _contentOffset) {
                        setState(() {
                          _contentOffset = newOffset;
                        });
                      }
                    }
                  },
                  onPanEnd: (details) {
                    // 松开后恢复原状态，添加阻尼效果
                    if (_contentOffset > 0) {
                      // 使用动画控制器实现平滑恢复
                      _animateToRest();
                    }
                  },
                  child: Container(
                    color: Colors.white, // 添加纯色背景
                    child: Column(
                      children: [
                        // 内容区域
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // 用户信息卡片
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
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
                                child: const UserProfileCard(),
                              ),
                              // 今日步数卡片
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            '今日步数',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$today',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (historyCount > 0)
                                        Text(
                                          '超过了过去约 ${ranking.surpassedDays} 天（约 ${percent.toStringAsFixed(0)}%）',
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // 记录卡片
                              todayEditable.when(
                                data: (editable) => editable
                                    ? const DiaryCard()
                                    : Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.lock,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '过去的记忆已锁定，无法编辑哦',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                loading: () => const DiaryCard(),
                                error: (_, __) => const DiaryCard(),
                              ),
                              const SizedBox(height: 100), // 底部留白
                            ],
                          ),
                        ),
                      ],
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
