import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../states/providers.dart';
import '../widgets/saving_overlay.dart';
import '../../data/models/audio_file.dart';
import '../../data/models/image_info.dart' as models;
import '../../services/diary_save_service.dart';
import '../../services/incremental_save_service.dart';

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
  bool _isClickMode = false; // true: 点击模式, false: 长按模式
  bool _showSavingOverlay = false; // 显示保存动画覆盖层
  bool _showSaveSuccessOverlay = false; // 显示保存成功动画
  double _saveProgress = 0.0; // 保存进度
  String _saveMessage = '正在保存...'; // 保存消息
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
  bool _hasUnsavedChanges = false; // 是否有未保存的修改
  String _initialContent = ''; // 初始文本内容
  List<Uint8List> _initialImages = []; // 初始图片列表
  List<String> _initialAudioPaths = []; // 初始音频路径列表
  List<String> _initialAudioNames = []; // 初始音频名称列表

  // 增量保存相关变量
  String? _contentChange; // 文本内容变化
  List<Uint8List> _newImages = []; // 新增的图片
  List<int> _removedImageIndices = []; // 删除的图片索引
  List<AudioFile> _newAudioFiles = []; // 新增的音频文件
  List<int> _removedAudioIndices = []; // 删除的音频索引
  Map<int, String> _updatedAudioNames = {}; // 更新的音频名称

  @override
  void initState() {
    super.initState();
    _loadCurrentDiary();
    _loadStepsData();

    // 监听文本变化
    _textController.addListener(_onTextChanged);

    // 监听焦点变化
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus) {
        // 文本框获得焦点时的处理
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
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
        // 如果没有日记，也要设置初始状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _textFocusNode.unfocus();
            _setInitialState();
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

      // 图片加载完成后，设置初始状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _textFocusNode.unfocus();
          _setInitialState();
        }
      });
    } catch (e) {
      assert(() {
        print('加载已保存图片失败: $e');
        return true;
      }());

      // 即使加载失败，也要设置初始状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _textFocusNode.unfocus();
          _setInitialState();
        }
      });
    }
  }

  Future<void> _loadStepsData() async {
    try {
      // 使用与主页相同的方式获取步数数据
      final stepsDataAsync = ref.read(dailyStepsProvider);

      stepsDataAsync.when(
        data: (stepsData) async {
          if (mounted && stepsData.isNotEmpty) {
            final steps = stepsData.last.steps; // 获取最新的步数数据
            setState(() {
              _cachedSteps = steps;
            });

            // 同时更新用户每日数据，保持数据一致性
            await ref.read(userDailyDataServiceProvider).updateSteps(steps);
          }
        },
        loading: () {
          // 正在加载时不做任何操作
        },
        error: (error, stack) {
          assert(() {
            print('Error loading steps data in diary page: $error');
            return true;
          }());
          // 如果获取失败，尝试从用户每日数据获取缓存值
          _loadCachedStepsData();
        },
      );
    } catch (e) {
      assert(() {
        print('Error loading steps data in diary page: $e');
        return true;
      }());
      _loadCachedStepsData();
    }
  }

  Future<void> _loadCachedStepsData() async {
    try {
      final userData = await ref
          .read(userDailyDataServiceProvider)
          .getTodayUserData();
      if (userData != null) {
        setState(() {
          _cachedSteps = userData.steps;
        });
      }
    } catch (e) {
      assert(() {
        print('Error loading cached steps data: $e');
        return true;
      }());
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
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = maxImages - _selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();

        for (final file in filesToAdd) {
          final bytes = await File(file.path).readAsBytes();
          _selectedImages.add(bytes);
          // 记录新增的图片
          _newImages.add(bytes);
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

        _updateChangeStatus();
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

    // 记录删除的图片索引
    // 需要调整索引，因为删除操作会影响后续索引
    final adjustedIndex = _removedImageIndices.where((i) => i < index).length;
    _removedImageIndices.add(index - adjustedIndex);

    _updateChangeStatus();
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

          // 记录新增的音频文件
          final newAudioFile = AudioFile.create(
            displayName: '录音 ${_audioPaths.length}',
            filePath: path,
            duration: _currentRecordingDuration.inMilliseconds,
            recordTime: DateTime.now(),
          );
          _newAudioFiles.add(newAudioFile);

          _updateChangeStatus();
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

    // 记录删除的音频索引
    // 需要调整索引，因为删除操作会影响后续索引
    final adjustedIndex = _removedAudioIndices.where((i) => i < index).length;
    _removedAudioIndices.add(index - adjustedIndex);

    _updateChangeStatus();
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
    // 显示保存动画
    setState(() {
      _showSavingOverlay = true;
      _saveProgress = 0.0;
      _saveMessage = '正在准备保存...';
    });

    try {
      // 更新保存进度
      setState(() {
        _saveProgress = 0.1;
        _saveMessage = '正在处理音频文件...';
      });

      // 创建AudioFile对象列表
      final List<AudioFile> audioFiles = [];
      for (int i = 0; i < _audioPaths.length; i++) {
        final audioFile = File(_audioPaths[i]);
        if (await audioFile.exists()) {
          final existingAudioFile = AudioFile.create(
            displayName: _audioNames[i],
            filePath: _audioPaths[i],
            duration: _audioDurations[i].inMilliseconds,
            recordTime: _audioRecordTimes[i],
          );
          audioFiles.add(existingAudioFile);
        }
      }

      setState(() {
        _saveProgress = 0.3;
        _saveMessage = '正在准备数据...';
      });

      // 获取现有的日记数据
      final diaryService = ref.read(diaryServiceProvider);
      final existingDiary = await diaryService.getTodayDiary();

      setState(() {
        _saveProgress = 0.5;
        _saveMessage = '正在后台保存...';
      });

      // 获取今日ID
      final today = DateTime.now();
      final todayId =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // 创建增量保存数据
      final incrementalSaveData = _createIncrementalSaveData(
        todayId,
        existingDiary != null,
      );

      // 检查是否有变化
      if (!incrementalSaveData.hasChanges) {
        setState(() {
          _saveProgress = 1.0;
          _saveMessage = '没有变化需要保存';
        });

        // 隐藏保存动画，显示成功动画
        setState(() {
          _showSavingOverlay = false;
          _showSaveSuccessOverlay = true;
        });

        // 等待成功动画完成后处理
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showSaveSuccessOverlay = false;
            });

            // 根据参数决定是否自动返回
            if (autoReturn) {
              Navigator.of(context).pop();
            }
          }
        });

        return true;
      }

      // 在后台isolate中执行增量保存
      final result = await IncrementalSaveService.saveIncrementalInBackground(
        incrementalSaveData,
      );

      if (result.success) {
        setState(() {
          _saveProgress = 0.8;
          _saveMessage = '正在保存...';
        });

        // 将增量保存的结果与数据库集成
        if (existingDiary != null) {
          // 更新现有日记 - 应用增量变化
          List<models.ImageInfo> updatedImages = List.from(
            existingDiary.images,
          );
          List<AudioFile> updatedAudioFiles = List.from(
            existingDiary.audioFiles,
          );

          // 应用新增图片
          if (result.savedImages != null) {
            updatedImages.addAll(result.savedImages!);
          }

          // 应用新增音频文件
          if (result.savedAudioFiles != null) {
            updatedAudioFiles.addAll(result.savedAudioFiles!);
          }

          // 应用音频名称变化
          for (final entry in _updatedAudioNames.entries) {
            if (entry.key < updatedAudioFiles.length) {
              updatedAudioFiles[entry.key] = updatedAudioFiles[entry.key]
                  .copyWith(displayName: entry.value);
            }
          }

          final updatedDiary = existingDiary.copyWith(
            content: _contentChange ?? existingDiary.content,
            images: updatedImages.isNotEmpty ? updatedImages : null,
            audioFiles: updatedAudioFiles.isNotEmpty ? updatedAudioFiles : null,
          );

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
            audioFiles: result.savedAudioFiles ?? [],
          );
        }

        setState(() {
          _saveProgress = 1.0;
          _saveMessage = '保存完成';
        });

        // 隐藏保存动画，显示成功动画
        setState(() {
          _showSavingOverlay = false;
          _showSaveSuccessOverlay = true;
        });

        // 保存成功后重置初始状态
        _resetInitialState();

        // 刷新今日日记数据
        ref.invalidate(todayDiaryProvider);

        // 等待成功动画完成后处理
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showSaveSuccessOverlay = false;
            });

            // 根据参数决定是否自动返回
            if (autoReturn) {
              Navigator.of(context).pop();
            }
          }
        });

        return true;
      } else {
        // 保存失败
        setState(() {
          _showSavingOverlay = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('保存失败：${result.error}')));
        }
        return false;
      }
    } catch (e) {
      setState(() {
        _showSavingOverlay = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
      return false;
    }
  }

  Widget _buildImageGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 48.0;
    final imageSize = (screenWidth - padding) / 3;

    return SizedBox(
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
                return SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: Stack(
                    children: [
                      SizedBox(
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
                              color: Colors.black.withValues(alpha: 0.6),
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
    return SizedBox(
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

                    // 记录音频名称变化
                    _updatedAudioNames[index] = newName;

                    _updateChangeStatus();
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
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 点击录音按钮（点击开始/停止）
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: _isClickMode ? 100 : 56,
                        height: _isClickMode ? 100 : 56,
                        child: GestureDetector(
                          onTap: () {
                            if (_isClickMode) {
                              // 激活状态：执行点击录音逻辑
                              if (_isRecording) {
                                _stopRecording();
                              } else {
                                _startRecording();
                              }
                            } else {
                              // 非激活状态：切换到点击模式
                              setState(() {
                                _isClickMode = true;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isClickMode
                                  ? (_isRecording
                                        ? Colors.red.shade100
                                        : Colors.blue.shade100)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: _isClickMode
                                    ? (_isRecording
                                          ? Colors.red.shade300
                                          : Colors.blue.shade300)
                                    : Colors.grey.shade200,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: _isClickMode
                                  ? (_isRecording
                                        ? [
                                            BoxShadow(
                                              color: Colors.red.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.blue.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ])
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  (_isClickMode && _isRecording)
                                      ? Icons.stop
                                      : Icons.radio_button_checked,
                                  color: _isClickMode
                                      ? (_isRecording
                                            ? Colors.red
                                            : Colors.blue.shade600)
                                      : Colors.grey.shade400,
                                  size: _isClickMode ? 36 : 20,
                                ),
                                if (_isClickMode) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    (_isClickMode && _isRecording)
                                        ? '停止录音'
                                        : '点击录音',
                                    style: TextStyle(
                                      color: _isRecording
                                          ? Colors.red
                                          : Colors.blue.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 长按录音按钮（按住录音，松开停止）
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: !_isClickMode ? 100 : 56,
                        height: !_isClickMode ? 100 : 56,
                        child: GestureDetector(
                          onTap: () {
                            if (_isClickMode) {
                              // 非激活状态：切换到长按模式
                              setState(() {
                                _isClickMode = false;
                              });
                            }
                          },
                          onTapDown: (_) {
                            if (!_isClickMode) {
                              // 激活状态：执行长按录音逻辑
                              _startRecording();
                            }
                          },
                          onTapUp: (_) {
                            if (!_isClickMode) {
                              // 激活状态：停止录音
                              _stopRecording();
                            }
                          },
                          onTapCancel: () {
                            if (!_isClickMode) {
                              // 激活状态：停止录音
                              _stopRecording();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isClickMode
                                  ? (_isRecording
                                        ? Colors.red.shade100
                                        : Colors.blue.shade100)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: !_isClickMode
                                    ? (_isRecording
                                          ? Colors.red.shade300
                                          : Colors.blue.shade300)
                                    : Colors.grey.shade200,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: !_isClickMode
                                  ? (_isRecording
                                        ? [
                                            BoxShadow(
                                              color: Colors.red.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.blue.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ])
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  (!_isClickMode && _isRecording)
                                      ? Icons.stop
                                      : Icons.mic,
                                  color: !_isClickMode
                                      ? (_isRecording
                                            ? Colors.red
                                            : Colors.blue.shade600)
                                      : Colors.grey.shade400,
                                  size: !_isClickMode ? 36 : 20,
                                ),
                                if (!_isClickMode) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    (!_isClickMode && _isRecording)
                                        ? '松开停止'
                                        : '按住录音',
                                    style: TextStyle(
                                      color: _isRecording
                                          ? Colors.red
                                          : Colors.blue.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
        title: _isRecording
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatRecordingDuration(
                      maxRecordingDuration - _currentRecordingDuration,
                    ),
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
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
          TextButton(
            onPressed: _showSavingOverlay ? null : _saveDiary,
            child: Text(
              '保存',
              style: TextStyle(
                color: _showSavingOverlay ? Colors.grey : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: PopScope(
        canPop: !_showSavingOverlay, // 如果正在保存，不允许返回
        onPopInvoked: (didPop) async {
          if (didPop) return; // 如果已经弹出，不需要处理

          await _handleBackPress();
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

            // 保存动画覆盖层
            if (_showSavingOverlay)
              SavingOverlay(message: _saveMessage, progress: _saveProgress),
            // 保存成功动画覆盖层
            if (_showSaveSuccessOverlay)
              SaveSuccessOverlay(
                onAnimationComplete: () {
                  setState(() {
                    _showSaveSuccessOverlay = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 设置初始状态
  void _setInitialState() {
    _initialContent = _textController.text;
    _initialImages = List.from(_selectedImages);
    _initialAudioPaths = List.from(_audioPaths);
    _initialAudioNames = List.from(_audioNames);
    _hasUnsavedChanges = false;

    // 重置增量保存变量
    _contentChange = null;
    _newImages.clear();
    _removedImageIndices.clear();
    _newAudioFiles.clear();
    _removedAudioIndices.clear();
    _updatedAudioNames.clear();
  }

  /// 检查是否有未保存的修改
  bool _hasChanges() {
    // 检查文本内容是否有变化
    final contentChanged = _textController.text != _initialContent;

    // 检查图片是否有变化
    final imagesChanged =
        _selectedImages.length != _initialImages.length ||
        !_areImagesEqual(_selectedImages, _initialImages);

    // 检查音频路径是否有变化
    final audioPathsChanged =
        _audioPaths.length != _initialAudioPaths.length ||
        !_areListsEqual(_audioPaths, _initialAudioPaths);

    // 检查音频名称是否有变化
    final audioNamesChanged =
        _audioNames.length != _initialAudioNames.length ||
        !_areListsEqual(_audioNames, _initialAudioNames);

    final hasChanges =
        contentChanged ||
        imagesChanged ||
        audioPathsChanged ||
        audioNamesChanged;

    // 调试信息
    assert(() {
      print('内容变化: $contentChanged');
      print('图片变化: $imagesChanged');
      print('音频路径变化: $audioPathsChanged');
      print('音频名称变化: $audioNamesChanged');
      print('是否有修改: $hasChanges');
      return true;
    }());

    return hasChanges;
  }

  /// 比较两个图片列表是否相等
  bool _areImagesEqual(List<Uint8List> list1, List<Uint8List> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].length != list2[i].length) return false;
      // 简单比较长度，如果需要更精确的比较可以比较内容
    }
    return true;
  }

  /// 比较两个字符串列表是否相等
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// 文本变化监听器
  void _onTextChanged() {
    if (_initialContent.isNotEmpty || _textController.text.isNotEmpty) {
      // 记录文本内容变化
      if (_textController.text != _initialContent) {
        _contentChange = _textController.text;
      } else {
        _contentChange = null;
      }

      final hasChanges = _hasChanges();
      if (hasChanges != _hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = hasChanges;
        });
      }
    }
  }

  /// 更新修改状态
  void _updateChangeStatus() {
    final hasChanges = _hasChanges();
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  /// 创建增量保存数据
  IncrementalSaveData _createIncrementalSaveData(
    String todayId,
    bool isUpdate,
  ) {
    return IncrementalSaveData(
      newContent: _contentChange,
      newImages: _newImages.isNotEmpty ? _newImages : null,
      removedImageIndices: _removedImageIndices.isNotEmpty
          ? _removedImageIndices
          : null,
      newAudioFiles: _newAudioFiles.isNotEmpty ? _newAudioFiles : null,
      removedAudioIndices: _removedAudioIndices.isNotEmpty
          ? _removedAudioIndices
          : null,
      updatedAudioNames: _updatedAudioNames.isNotEmpty
          ? _updatedAudioNames
          : null,
      todayId: todayId,
      isUpdate: isUpdate,
    );
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

  /// 重置初始状态（在保存成功后调用）
  void _resetInitialState() {
    _setInitialState();
    assert(() {
      print('重置初始状态完成');
      return true;
    }());
  }

  /// 处理返回按钮点击
  Future<void> _handleBackPress() async {
    // 如果正在保存，不允许返回
    if (_showSavingOverlay) {
      return;
    }

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
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周天'];
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
                color: Colors.grey.withValues(alpha: 0.5),
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
