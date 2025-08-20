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
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettingsPage extends ConsumerStatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  ConsumerState<ReminderSettingsPage> createState() =>
      _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends ConsumerState<ReminderSettingsPage> {
  // 提醒时间段配置
  final List<ReminderTimeSlot> _timeSlots = [
    ReminderTimeSlot('早上', '06:00-09:00', Icons.wb_sunny, Colors.orange),
    ReminderTimeSlot(
      '上午',
      '09:00-12:00',
      Icons.wb_sunny_outlined,
      Colors.yellow,
    ),
    ReminderTimeSlot('中午', '12:00-14:00', Icons.wb_sunny, Colors.orange),
    ReminderTimeSlot('下午', '14:00-18:00', Icons.wb_cloudy, Colors.blue),
    ReminderTimeSlot('傍晚', '18:00-20:00', Icons.nights_stay, Colors.purple),
    ReminderTimeSlot('晚上', '20:00-22:00', Icons.nightlight, Colors.indigo),
  ];

  // 存储每个时间段的开关状态
  final Map<String, bool> _reminderStates = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminderStates();
  }

  @override
  void dispose() {
    // 页面销毁时保存所有状态
    _saveAllReminderStates();
    super.dispose();
  }

  Future<void> _saveAllReminderStates() async {
    final prefs = await SharedPreferences.getInstance();
    for (var slot in _timeSlots) {
      final key = 'reminder_${slot.title}';
      final currentState = _reminderStates[slot.title] ?? false;
      await prefs.setBool(key, currentState);
    }
  }

  Future<void> _initializeNotifications() async {
    // 本地通知已在main.dart中初始化，这里不需要重复初始化
  }

  Future<void> _loadReminderStates() async {
    // 检查通知权限状态
    final permissionStatus = await Permission.notification.status;
    final hasNotificationPermission = permissionStatus.isGranted;

    // 从SharedPreferences加载提醒状态
    final prefs = await SharedPreferences.getInstance();

    for (var slot in _timeSlots) {
      final key = 'reminder_${slot.title}';
      final savedState = prefs.getBool(key) ?? false;

      // 如果没有通知权限，强制设置为false
      _reminderStates[slot.title] = hasNotificationPermission
          ? savedState
          : false;
    }
    setState(() {});
  }

  Future<void> _toggleReminder(String title, bool enabled) async {
    if (enabled) {
      // 检查通知权限
      final permissionStatus = await Permission.notification.status;

      if (permissionStatus.isDenied) {
        // 尝试请求权限
        final result = await Permission.notification.request();

        if (result.isDenied || result.isPermanentlyDenied) {
          // 权限获取失败，显示提示并保持开关关闭状态
          String message = '通知权限获取失败';
          if (result.isPermanentlyDenied) {
            message = '通知权限被永久拒绝，请在设置中手动开启';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '去设置',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return; // 不更新开关状态
        }
      }

      // 权限获取成功，继续开启提醒
      setState(() {
        _reminderStates[title] = enabled;
      });

      // 保存状态到SharedPreferences
      await _saveReminderState(title, enabled);

      await _scheduleReminder(title);
    } else {
      // 关闭提醒不需要权限检查
      setState(() {
        _reminderStates[title] = enabled;
      });

      // 保存状态到SharedPreferences
      await _saveReminderState(title, enabled);

      await _cancelReminder(title);
    }
  }

  Future<void> _saveReminderState(String title, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reminder_$title';
    await prefs.setBool(key, enabled);
  }

  Future<void> _scheduleReminder(String title) async {
    // 为每个时间段设置一个随机时间
    final timeSlot = _timeSlots.firstWhere((slot) => slot.title == title);
    final randomTime = _getRandomTimeInSlot(timeSlot.timeRange);

    // 创建通知详情
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder',
          '每日提醒',
          channelDescription: '提醒用户记录每天的日记',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 注册WorkManager任务
    await Workmanager().registerPeriodicTask(
      'reminder_$title',
      'showReminderNotification',
      frequency: const Duration(days: 1),
      inputData: {'title': title, 'timeSlot': timeSlot.timeRange},
    );

    // 显示确认消息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已开启$title提醒'), backgroundColor: Colors.green),
    );
  }

  Future<void> _cancelReminder(String title) async {
    // 取消WorkManager任务
    await Workmanager().cancelByUniqueName('reminder_$title');

    // 移除关闭提示
  }

  TimeOfDay _getRandomTimeInSlot(String timeRange) {
    // 解析时间范围，返回一个随机时间
    final parts = timeRange.split('-');
    final startTime = _parseTimeString(parts[0]);
    final endTime = _parseTimeString(parts[1]);

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final randomMinutes =
        startMinutes + (endMinutes - startMinutes) ~/ 2; // 取中间时间

    return TimeOfDay(hour: randomMinutes ~/ 60, minute: randomMinutes % 60);
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日提醒'),
        elevation: 0,
        backgroundColor: Colors.white,
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
          // 提醒时间段列表
          ..._timeSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;

            return Column(
              children: [
                _buildTimeSlotItem(slot),
                // 添加分割线，最后一项不添加
                if (index < _timeSlots.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.grey.shade200,
                    indent: 56, // 与leading图标对齐
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeSlotItem(ReminderTimeSlot slot) {
    final isEnabled = _reminderStates[slot.title] ?? false;

    return ListTile(
      leading: Icon(slot.icon, color: Colors.grey.shade700, size: 24),
      title: Text(
        slot.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: CupertinoSwitch(
        value: isEnabled,
        onChanged: (value) => _toggleReminder(slot.title, value),
        activeColor: Colors.blue,
      ),
    );
  }
}

class ReminderTimeSlot {
  final String title;
  final String timeRange;
  final IconData icon;
  final Color color;

  ReminderTimeSlot(this.title, this.timeRange, this.icon, this.color);
}
