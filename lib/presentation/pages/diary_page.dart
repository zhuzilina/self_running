import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../states/providers.dart';
import '../../data/models/audio_file.dart';

class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  final _textController = TextEditingController();
  final _textFocusNode = FocusNode(); // 添加焦点节点
  final List<Uint8List> _selectedImages = [];
  final List<String> _audioPaths = [];
  final List<AudioPlayer?> _audioPlayers = [];
  final List<String> _audioNames = []; // 添加音频文件名列表
  final List<DateTime> _audioRecordTimes = []; // 添加录音时间列表
  final List<Duration> _audioDurations = []; // 添加音频时长列表
  final List<bool> _isPlaying = []; // 添加播放状态列表
  final List<Duration> _currentPlayPositions = []; // 添加当前播放位置列表
  final List<Timer?> _playTimers = []; // 添加播放计时器列表
  bool _isLoading = false;
  bool _isRecording = false;
  bool _showRecordingIndicator = false; // 添加录音指示器显示状态
  static const int maxImages = 9;
  static const int maxAudios = 9;
  static const Duration maxRecordingDuration = Duration(
    minutes: 5,
  ); // 最大录音时长5分钟
  final _record = AudioRecorder();
  Timer? _recordingTimer; // 添加录音计时器
  Duration _currentRecordingDuration = Duration.zero; // 当前录音时长
  int? _cachedSteps; // 缓存步数数据

  // 用于检测修改的变量
  String? _initialStateHash; // 初始状态的MD5哈希值
  bool _hasUnsavedChanges = false; // 是否有未保存的修改

  @override
  void initState() {
    super.initState();
    _loadCurrentDiary();
    _loadStepsData();

    // 监听焦点变化
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus) {
        // 文本框获得焦点时的处理
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose(); // 释放焦点节点
    for (final player in _audioPlayers) {
      if (player != null) {
        player.dispose();
      }
    }
    for (final timer in _playTimers) {
      timer?.cancel();
    }
    _record.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentDiary() async {
    final diary = await ref.read(diaryServiceProvider).getTodayDiary();

    setState(() {
      _textController.text = diary?.content ?? '';

      if (diary != null) {
        // 加载已保存的音频信息
        _audioNames.clear();
        _audioNames.addAll(diary.audioNames);
        _audioDurations.clear();
        _audioDurations.addAll(
          diary.audioDurations.map((ms) => Duration(milliseconds: ms)),
        );

        // 加载已保存的音频路径
        _audioPaths.clear();
        _audioPaths.addAll(diary.audioPaths);

        // 初始化音频播放器列表
        _audioPlayers.clear();
        _audioRecordTimes.clear();
        _isPlaying.clear();
        _currentPlayPositions.clear();
        _playTimers.clear();

        for (int i = 0; i < _audioPaths.length; i++) {
          _audioPlayers.add(null);
          _audioRecordTimes.add(DateTime.now()); // 使用当前时间作为占位符，实际应该从数据库获取
          _isPlaying.add(false);
          _currentPlayPositions.add(Duration.zero);
          _playTimers.add(null);
        }

        // 加载已保存的图片
        _loadSavedImages(diary.imagePaths);
      } else {
        // 如果没有日记，也要生成初始状态哈希值
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _textFocusNode.unfocus();
            _initialStateHash = _generateStateHash();
          }
        });
      }
    });
  }

  Future<void> _loadSavedImages(List<String> imagePaths) async {
    try {
      _selectedImages.clear();
      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          final imageData = await file.readAsBytes();
          _selectedImages.add(imageData);
        }
      }
      setState(() {});

      // 图片加载完成后，生成初始状态哈希值
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _textFocusNode.unfocus();
          _initialStateHash = _generateStateHash();
        }
      });
    } catch (e) {
      print('加载已保存图片失败: $e');

      // 即使加载失败，也要生成初始状态哈希值
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _textFocusNode.unfocus();
          _initialStateHash = _generateStateHash();
        }
      });
    }
  }

  Future<void> _loadStepsData() async {
    try {
      // 首先尝试从用户每日数据获取步数
      final userData = await ref
          .read(userDailyDataServiceProvider)
          .getTodayUserData();
      if (userData != null) {
        setState(() {
          _cachedSteps = userData.steps;
        });
        return;
      }

      // 如果用户数据不存在，则从健康数据获取
      final stepsData = await ref
          .read(fetchDailyStepsUseCaseProvider)
          .call(from: DateTime.now(), to: DateTime.now());

      if (mounted && stepsData.isNotEmpty) {
        final steps = stepsData.first.steps;
        setState(() {
          _cachedSteps = steps;
        });

        // 保存到用户每日数据
        await ref.read(userDailyDataServiceProvider).updateSteps(steps);
      }
    } catch (e) {
      // 忽略错误，使用默认值
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('最多只能添加9张图片')));
      return;
    }

    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = maxImages - _selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        for (final file in filesToAdd) {
          final bytes = await File(file.path).readAsBytes();
          _selectedImages.add(bytes);
        }

        setState(() {});

        if (pickedFiles.length > remainingSlots) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已添加${filesToAdd.length}张图片，超出限制的图片已忽略'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败：$e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _startRecording() async {
    if (_audioPaths.length >= maxAudios) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('最多只能录制9条语音')));
      return;
    }

    // 防止重复触发
    if (_isRecording) {
      return;
    }

    // 在开始录音前移除文本框焦点
    _textFocusNode.unfocus();

    try {
      final hasPermission = await _record.hasPermission();
      if (hasPermission) {
        final directory = await getApplicationDocumentsDirectory();
        final audioPath =
            '${directory.path}/diary_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _record.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: audioPath,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _showRecordingIndicator = true;
            _currentRecordingDuration = Duration.zero;
          });
        }

        // 启动录音计时器，降低更新频率以减少界面重建
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 500), (
          timer,
        ) {
          if (mounted) {
            setState(() {
              _currentRecordingDuration += const Duration(milliseconds: 500);
            });
          }

          // 检查是否达到最大录音时长
          if (_currentRecordingDuration >= maxRecordingDuration) {
            _stopRecording();
          }
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('需要录音权限')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('开始录音失败：$e')));
    }
  }

  Future<void> _stopRecording() async {
    // 停止计时器
    _recordingTimer?.cancel();

    try {
      final path = await _record.stop();
      if (path != null) {
        // 检查录音时长是否小于1秒
        if (_currentRecordingDuration.inMilliseconds < 1000) {
          // 删除录音文件
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('录音时间太短，请重新录音'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            _audioPaths.add(path);
            // 不立即创建播放器，只在播放时创建
            _audioPlayers.add(null); // 占位符
            _audioNames.add('录音 ${_audioPaths.length}'); // 添加默认文件名
            _audioRecordTimes.add(DateTime.now()); // 添加录音时间
            _audioDurations.add(_currentRecordingDuration); // 使用实际录音时长
            _isPlaying.add(false); // 添加播放状态
            _currentPlayPositions.add(Duration.zero); // 添加播放位置
            _playTimers.add(null); // 添加播放计时器
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('停止录音失败：$e')));
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _showRecordingIndicator = false;
          _currentRecordingDuration = Duration.zero;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  Widget _buildRecordingIndicator() {
    final progress =
        _currentRecordingDuration.inSeconds / maxRecordingDuration.inSeconds;
    final remainingProgress = 1.0 - progress;

    return Container(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环（灰色）
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade300),
            ),
          ),
          // 进度圆环（白色）
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          // 中心时间显示
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatRecordingDuration(_currentRecordingDuration),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '录音中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeAudio(int index) {
    setState(() {
      _playTimers[index]?.cancel(); // 取消播放计时器
      // 只有在播放器存在时才销毁
      if (_audioPlayers[index] != null) {
        _audioPlayers[index]!.dispose();
      }
      _audioPlayers.removeAt(index);
      _audioPaths.removeAt(index);
      _audioNames.removeAt(index);
      _audioRecordTimes.removeAt(index);
      _audioDurations.removeAt(index);
      _isPlaying.removeAt(index);
      _currentPlayPositions.removeAt(index);
      _playTimers.removeAt(index);
    });
  }

  Future<void> _playAudio(int index) async {
    try {
      // 如果播放器不存在，则创建
      if (_audioPlayers[index] == null) {
        _audioPlayers[index] = AudioPlayer();
      }
      final player = _audioPlayers[index]!;

      // 如果当前正在播放，则暂停
      if (_isPlaying[index]) {
        await player.pause();
        _playTimers[index]?.cancel();
        setState(() {
          _isPlaying[index] = false;
        });
        return;
      }

      // 停止其他正在播放的音频
      for (int i = 0; i < _isPlaying.length; i++) {
        if (_isPlaying[i] && i != index && _audioPlayers[i] != null) {
          await _audioPlayers[i]!.pause();
          _playTimers[i]?.cancel();
          setState(() {
            _isPlaying[i] = false;
            _currentPlayPositions[i] = Duration.zero;
          });
        }
      }

      // 开始播放当前音频
      await player.setSource(DeviceFileSource(_audioPaths[index]));
      await player.resume();

      setState(() {
        _isPlaying[index] = true;
        _currentPlayPositions[index] = Duration.zero;
      });

      // 启动播放计时器，降低更新频率以减少界面重建
      _playTimers[index] = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) {
        if (!_isPlaying[index]) {
          timer.cancel();
          return;
        }

        setState(() {
          _currentPlayPositions[index] += const Duration(milliseconds: 500);
        });

        // 检查是否播放完成
        if (_currentPlayPositions[index] >= _audioDurations[index]) {
          timer.cancel();
          setState(() {
            _isPlaying[index] = false;
            _currentPlayPositions[index] = Duration.zero;
          });
        }
      });

      // 监听播放完成事件
      player.onPlayerComplete.listen((_) {
        if (mounted) {
          _playTimers[index]?.cancel();
          setState(() {
            _isPlaying[index] = false;
            _currentPlayPositions[index] = Duration.zero;
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('播放失败：$e')));
    }
  }

  Future<bool> _saveDiary({bool autoReturn = true}) async {
    setState(() => _isLoading = true);

    try {
      final diaryService = ref.read(diaryServiceProvider);

      // 获取现有的日记数据
      final existingDiary = await diaryService.getTodayDiary();

      // 创建AudioFile对象列表（使用新的保存方式）
      final List<AudioFile> audioFiles = [];

      // 处理音频文件：只保存新录制的音频，保留已存在的音频
      for (int i = 0; i < _audioPaths.length; i++) {
        final audioFile = File(_audioPaths[i]);
        if (await audioFile.exists()) {
          // 检查是否是临时录音文件（新录制的）
          if (_audioPaths[i].contains('/tmp/') ||
              _audioPaths[i].contains('cache')) {
            // 新录制的音频文件，需要保存
            final savedAudioFile = await diaryService.saveAudioDirectly(
              sourcePath: _audioPaths[i],
              displayName: _audioNames[i],
              duration: _audioDurations[i].inMilliseconds,
              recordTime: _audioRecordTimes[i],
            );
            if (savedAudioFile != null) {
              audioFiles.add(savedAudioFile);
            }
          } else {
            // 已存在的音频文件，直接使用
            final existingAudioFile = AudioFile.create(
              displayName: _audioNames[i],
              filePath: _audioPaths[i],
              duration: _audioDurations[i].inMilliseconds,
              recordTime: _audioRecordTimes[i],
            );
            audioFiles.add(existingAudioFile);
          }
        } else {
          print('音频文件不存在: ${_audioPaths[i]}');
        }
      }

      // 如果有现有日记，只更新内容，不删除文件
      if (existingDiary != null) {
        // 更新现有日记，保留未删除的音频文件
        final updatedDiary = existingDiary.copyWith(
          content: _textController.text.trim(),
          imagePaths: [], // 图片会通过saveTodayDiary重新处理
          audioFiles: audioFiles,
        );

        // 保存更新的日记
        await diaryService.saveTodayDiary(
          content: updatedDiary.content,
          imageDataList: _selectedImages,
          audioFiles: updatedDiary.audioFiles,
        );
      } else {
        // 创建新日记
        await diaryService.saveTodayDiary(
          content: _textController.text.trim(),
          imageDataList: _selectedImages,
          audioFiles: audioFiles,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功'), duration: Duration(seconds: 1)),
        );

        // 保存成功后重置初始状态哈希值
        _resetInitialStateHash();

        // 刷新今日日记数据
        ref.invalidate(todayDiaryProvider);

        // 根据参数决定是否自动返回
        if (autoReturn) {
          Navigator.of(context).pop();
        }
      }

      return true; // 保存成功
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
      return false; // 保存失败
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 48.0;
    final imageSize = (screenWidth - padding) / 3;

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Text(
                  '图片',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_selectedImages.length}/$maxImages)',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: [
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageBytes = entry.value;
                return Container(
                  width: imageSize,
                  height: imageSize,
                  child: Stack(
                    children: [
                      Container(
                        width: imageSize,
                        height: imageSize,
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: imageSize,
                          height: imageSize,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_selectedImages.length < maxImages)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '添加图片\n(可多选)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Text(
                  '声音',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_audioPaths.length}/$maxAudios)',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // 先显示录音文件列表
          if (_audioPaths.isNotEmpty)
            Column(
              children: _audioPaths.asMap().entries.map((entry) {
                final index = entry.key;
                return _AudioListItem(
                  index: index,
                  audioName: _audioNames[index],
                  recordTime: _audioRecordTimes[index],
                  duration: _audioDurations[index],
                  isPlaying: _isPlaying[index],
                  currentPosition: _currentPlayPositions[index],
                  onPlay: () => _playAudio(index),
                  onDelete: () => _removeAudio(index),
                  onNameChanged: (newName) {
                    setState(() {
                      _audioNames[index] = newName;
                    });
                  },
                  onEditingStarted: () {
                    // 编辑开始
                  },
                  onEditingFinished: () {
                    // 编辑结束
                  },
                );
              }).toList(),
            ),
          // 录音按钮放在录音文件列表下面
          if (_audioPaths.length < maxAudios) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red.shade100
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: _isRecording
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : Colors.grey.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording ? '松开停止录音' : '按住录音',
                      style: TextStyle(
                        color: _isRecording ? Colors.red : Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '今日记录',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: _handleBackPress,
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveDiary,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          await _handleBackPress();
          return false; // 我们已经在_handleBackPress中处理了导航
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getFormattedDate(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatSteps(_cachedSteps ?? 0),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _textController,
                    focusNode: _textFocusNode, // 使用焦点节点
                    cursorColor: Colors.grey,
                    decoration: const InputDecoration(
                      hintText: '记录今天的心情、想法或发生的事情...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    enableInteractiveSelection: true, // 启用交互选择
                    onTap: () {
                      // 主文本编辑框点击
                      _textFocusNode.requestFocus();
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildImageGrid(),
                  const SizedBox(height: 32),
                  _buildAudioSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // 录音指示器覆盖层
            if (_showRecordingIndicator)
              Positioned(
                right: 0,
                left: 0,
                top: MediaQuery.of(context).size.height * 0.1,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(child: _buildRecordingIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 生成当前状态的MD5哈希值
  String _generateStateHash() {
    // 创建包含所有状态信息的Map
    final stateData = {
      'content': _textController.text,
      'images': _selectedImages.map((img) => base64Encode(img)).toList(),
      'audioPaths': _audioPaths,
      'audioNames': _audioNames,
      'audioDurations': _audioDurations.map((d) => d.inMilliseconds).toList(),
      'audioRecordTimes': _audioRecordTimes
          .map((t) => t.toIso8601String())
          .toList(),
    };

    // 将Map转换为JSON字符串
    final jsonString = jsonEncode(stateData);

    // 生成MD5哈希值
    final bytes = utf8.encode(jsonString);
    final digest = md5.convert(bytes);

    return digest.toString();
  }

  /// 检查是否有未保存的修改
  bool _hasChanges() {
    if (_initialStateHash == null) {
      print('初始状态哈希值为空，返回false');
      return false;
    }
    final currentHash = _generateStateHash();
    final hasChanges = _initialStateHash != currentHash;

    // 调试信息
    print('初始状态哈希值: $_initialStateHash');
    print('当前状态哈希值: $currentHash');
    print('是否有修改: $hasChanges');

    return hasChanges;
  }

  /// 显示保存确认对话框
  Future<bool> _showSaveConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                '保存提示',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              content: const Text(
                '您有未保存的修改，是否要保存？',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                // 使用Expanded让两个按钮各占一半宽度
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // 不保存
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '不保存',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey, // 灰色
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // 保存
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black, // 黑色
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// 重置初始状态哈希值（在保存成功后调用）
  void _resetInitialStateHash() {
    _initialStateHash = _generateStateHash();
    print('重置初始状态哈希值: $_initialStateHash');
  }

  /// 处理返回按钮点击
  Future<void> _handleBackPress() async {
    if (_hasChanges()) {
      final shouldSave = await _showSaveConfirmDialog();
      if (shouldSave) {
        // 用户选择保存，不自动返回
        final success = await _saveDiary(autoReturn: false);
        if (success && mounted) {
          // 保存成功后手动返回
          Navigator.of(context).pop();
        }
        return;
      }
      // 用户选择不保存，直接返回
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // 没有修改，直接返回
      Navigator.of(context).pop();
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.year}年${now.month}月${now.day}日 $weekday';
  }
}

class _AudioListItem extends StatefulWidget {
  final int index;
  final String audioName;
  final DateTime recordTime;
  final Duration duration;
  final bool isPlaying;
  final Duration currentPosition;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final ValueChanged<String> onNameChanged;
  final VoidCallback? onEditingStarted;
  final VoidCallback? onEditingFinished;

  const _AudioListItem({
    required this.index,
    required this.audioName,
    required this.recordTime,
    required this.duration,
    required this.isPlaying,
    required this.currentPosition,
    required this.onPlay,
    required this.onDelete,
    required this.onNameChanged,
    this.onEditingStarted,
    this.onEditingFinished,
  });

  @override
  State<_AudioListItem> createState() => _AudioListItemState();
}

class _AudioListItemState extends State<_AudioListItem> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.audioName);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    // 通知父组件进入编辑状态
    widget.onEditingStarted?.call();

    setState(() {
      _isEditing = true;
    });
    // 延迟聚焦，确保widget已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isEditing) {
        _nameController.selection = TextSelection(
          baseOffset: _nameController.text.length,
          extentOffset: _nameController.text.length,
        );
      }
    });
  }

  void _finishEditing() {
    setState(() {
      _isEditing = false;
    });
    final trimmedText = _nameController.text.trim();
    // 确保显示名称不超过6个字符
    final limitedText = trimmedText.length > 6
        ? trimmedText.substring(0, 6)
        : trimmedText;
    widget.onNameChanged(
      limitedText.isEmpty ? '录音 ${widget.index + 1}' : limitedText,
    );

    // 通知父组件编辑结束
    widget.onEditingFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onPlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        TextField(
                          controller: _nameController,
                          cursorColor: Colors.grey,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          onSubmitted: (_) => _finishEditing(),
                          onEditingComplete: _finishEditing,
                          autofocus: true,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onTap: () {
                            // 防止点击时退出编辑状态
                          },
                        )
                      else
                        GestureDetector(
                          onTap: _startEditing,
                          child: Text(
                            widget.audioName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.isPlaying
                          ? _formatDuration(
                              widget.duration - widget.currentPosition,
                            )
                          : _formatDuration(widget.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isPlaying
                            ? Colors.blue.shade600
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTime(widget.recordTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
