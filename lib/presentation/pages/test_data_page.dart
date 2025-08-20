import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/providers.dart';
import '../../services/data_persistence_service.dart';
import '../../services/terms_agreement_service.dart';
import '../../services/storage_service.dart';

class TestDataPage extends ConsumerStatefulWidget {
  const TestDataPage({super.key});

  @override
  ConsumerState<TestDataPage> createState() => _TestDataPageState();
}

class _TestDataPageState extends ConsumerState<TestDataPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nicknameController.text = '测试用户';
    _sloganController.text = '测试口号';
    _stepsController.text = '8000';
    _daysController.text = '7';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _sloganController.dispose();
    _stepsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试数据管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 今日数据设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日数据设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _sloganController,
                      decoration: const InputDecoration(
                        labelText: '口号',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stepsController,
                      decoration: const InputDecoration(
                        labelText: '步数',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveTodayData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('保存今日数据'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _smartSaveTodayData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('智能保存'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 批量测试数据
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '批量测试数据',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _daysController,
                      decoration: const InputDecoration(
                        labelText: '生成天数',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generateTestData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('生成测试数据'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 数据管理
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '数据管理',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearAllData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('清空所有数据'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateDateStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('更新日期状态'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _resetTermsAgreement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('重置用户协议同意状态'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 查看数据
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '查看数据',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _viewAllData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('查看所有数据'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('更新用户配置'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testDataPersistence,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('测试数据持久化'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _simulateDateChange,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('模拟日期变化'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _syncHealthData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('同步健康数据'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _refreshRankingData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('刷新排行数据'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTodayData() async {
    try {
      final nickname = _nicknameController.text.trim();
      final slogan = _sloganController.text.trim();
      final steps = int.tryParse(_stepsController.text.trim()) ?? 0;

      if (nickname.isEmpty) {
        _showSnackBar('请输入昵称', Colors.red);
        return;
      }

      await ref.read(
        preSaveProvider({
          'nickname': nickname,
          'slogan': slogan,
          'steps': steps,
        }).future,
      );

      _showSnackBar('今日数据已预保存', Colors.green);
    } catch (e) {
      _showSnackBar('保存失败: $e', Colors.red);
    }
  }

  Future<void> _smartSaveTodayData() async {
    try {
      final nickname = _nicknameController.text.trim();
      final slogan = _sloganController.text.trim();
      final steps = int.tryParse(_stepsController.text.trim()) ?? 0;

      if (nickname.isEmpty) {
        _showSnackBar('请输入昵称', Colors.red);
        return;
      }

      await ref.read(
        smartSaveProvider({
          'nickname': nickname,
          'slogan': slogan,
          'steps': steps,
        }).future,
      );

      _showSnackBar('今日数据已智能保存', Colors.green);
    } catch (e) {
      _showSnackBar('保存失败: $e', Colors.red);
    }
  }

  Future<void> _generateTestData() async {
    try {
      final days = int.tryParse(_daysController.text.trim()) ?? 7;
      final nickname = _nicknameController.text.trim();
      final slogan = _sloganController.text.trim();

      if (nickname.isEmpty) {
        _showSnackBar('请输入昵称', Colors.red);
        return;
      }

      final service = ref.read(userDailyDataServiceProvider);

      for (int i = 0; i < days; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final steps = 5000 + (i * 1000) + (DateTime.now().millisecond % 2000);

        // 为指定日期创建数据
        await service.createUserDataForDate(
          nickname: nickname,
          slogan: slogan,
          steps: steps,
          date: date,
        );
      }

      _showSnackBar('已生成 $days 天的测试数据', Colors.green);
    } catch (e) {
      _showSnackBar('生成测试数据失败: $e', Colors.red);
    }
  }

  Future<void> _clearAllData() async {
    try {
      final service = ref.read(userDailyDataServiceProvider);
      final allData = await service.getAllUserData();

      for (final data in allData) {
        await service.deleteUserData(data.id);
      }

      _showSnackBar('已清空所有数据', Colors.orange);
    } catch (e) {
      _showSnackBar('清空数据失败: $e', Colors.red);
    }
  }

  Future<void> _updateDateStatus() async {
    try {
      await ref.read(dateStatusUpdateProvider.future);
      _showSnackBar('日期状态已更新', Colors.green);
    } catch (e) {
      _showSnackBar('更新日期状态失败: $e', Colors.red);
    }
  }

  Future<void> _viewAllData() async {
    try {
      final service = ref.read(userDailyDataServiceProvider);
      final allData = await service.getAllUserData();

      if (allData.isEmpty) {
        _showSnackBar('暂无数据', Colors.orange);
        return;
      }

      String message = '共有 ${allData.length} 条数据:\n';
      for (final data in allData.take(5)) {
        message += '${data.date} - ${data.nickname} - ${data.steps} 步\n';
      }
      if (allData.length > 5) {
        message += '... 还有 ${allData.length - 5} 条数据';
      }

      _showSnackBar(message, Colors.blue);
    } catch (e) {
      _showSnackBar('查看数据失败: $e', Colors.red);
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      final nickname = _nicknameController.text.trim();
      final slogan = _sloganController.text.trim();
      final steps = int.tryParse(_stepsController.text.trim()) ?? 0;

      if (nickname.isEmpty) {
        _showSnackBar('请输入昵称', Colors.red);
        return;
      }

      await ref.read(
        userProfileUpdateProvider({
          'nickname': nickname,
          'slogan': slogan,
          'steps': steps,
        }).future,
      );

      _showSnackBar('用户配置已更新', Colors.green);
    } catch (e) {
      _showSnackBar('更新用户配置失败: $e', Colors.red);
    }
  }

  Future<void> _testDataPersistence() async {
    try {
      final service = ref.read(userDailyDataServiceProvider);
      final allData = await service.getAllUserData();

      if (allData.isEmpty) {
        _showSnackBar('暂无数据，请先生成一些测试数据', Colors.orange);
        return;
      }

      _showSnackBar('正在测试数据持久化...', Colors.blue);

      // 模拟保存操作
      for (final data in allData) {
        await service.createUserDataForDate(
          nickname: data.nickname,
          slogan: data.slogan,
          steps: data.steps,
          date: data.date,
        );
      }

      _showSnackBar('数据持久化测试成功！', Colors.green);
    } catch (e) {
      _showSnackBar('数据持久化测试失败: $e', Colors.red);
    }
  }

  Future<void> _simulateDateChange() async {
    try {
      final service = ref.read(userDailyDataServiceProvider);
      final allData = await service.getAllUserData();

      if (allData.isEmpty) {
        _showSnackBar('暂无数据，请先生成一些测试数据', Colors.orange);
        return;
      }

      _showSnackBar('正在模拟日期变化...', Colors.blue);

      // 模拟日期变化 - 更新编辑状态
      await ref.read(dateStatusUpdateProvider.future);

      _showSnackBar('日期变化模拟成功！', Colors.green);
    } catch (e) {
      _showSnackBar('日期变化模拟失败: $e', Colors.red);
    }
  }

  Future<void> _syncHealthData() async {
    try {
      final service = ref.read(userDailyDataServiceProvider);
      final allData = await service.getAllUserData();

      if (allData.isEmpty) {
        _showSnackBar('暂无数据，请先生成一些测试数据', Colors.orange);
        return;
      }

      _showSnackBar('正在同步健康数据...', Colors.blue);

      for (final data in allData) {
        await service.createUserDataForDate(
          nickname: data.nickname,
          slogan: data.slogan,
          steps: data.steps,
          date: data.date,
        );
      }

      _showSnackBar('健康数据同步成功！', Colors.green);
    } catch (e) {
      _showSnackBar('健康数据同步失败: $e', Colors.red);
    }
  }

  Future<void> _refreshRankingData() async {
    try {
      final service = ref.read(userDailyDataServiceProvider);
      final allData = await service.getAllUserData();

      if (allData.isEmpty) {
        _showSnackBar('暂无数据，请先生成一些测试数据', Colors.orange);
        return;
      }

      _showSnackBar('正在刷新排行数据...', Colors.blue);

      for (final data in allData) {
        await service.createUserDataForDate(
          nickname: data.nickname,
          slogan: data.slogan,
          steps: data.steps,
          date: data.date,
        );
      }

      _showSnackBar('排行数据刷新成功！', Colors.green);
    } catch (e) {
      _showSnackBar('排行数据刷新失败: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetTermsAgreement() async {
    try {
      final storageService = StorageService();
      final termsService = TermsAgreementService(storageService);
      await termsService.clearAgreementStatus();
      _showSnackBar('用户协议同意状态已重置！', Colors.green);
    } catch (e) {
      _showSnackBar('重置用户协议同意状态失败: $e', Colors.red);
    }
  }
}
