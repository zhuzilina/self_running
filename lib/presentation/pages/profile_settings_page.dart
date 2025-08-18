import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../states/providers.dart';
import '../../services/user_profile_service.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _nicknameController = TextEditingController();
  final _sloganController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _selectedAvatarBytes;
  Uint8List? _selectedCoverImageBytes;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final profile = await ref.read(userProfileServiceProvider).getUserProfile();
    setState(() {
      _nicknameController.text = profile.nickname;
      _sloganController.text = profile.slogan;
    });
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // 裁剪头像为1:1比例
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '裁剪头像',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
            IOSUiSettings(
              title: '裁剪头像',
              aspectRatioPresets: [CropAspectRatioPreset.square],
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await File(croppedFile.path).readAsBytes();
          setState(() {
            _selectedAvatarBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择头像失败：$e')));
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _selectedCoverImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择背景图失败：$e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('昵称不能为空')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? avatarPath;
      String? coverImagePath;

      // 保存头像
      if (_selectedAvatarBytes != null) {
        avatarPath = await ref
            .read(userProfileServiceProvider)
            .saveImageToLocal(_selectedAvatarBytes!, 'default_avatar.jpg');
      }

      // 保存背景图
      if (_selectedCoverImageBytes != null) {
        coverImagePath = await ref
            .read(userProfileServiceProvider)
            .saveImageToLocal(_selectedCoverImageBytes!, 'default_cover.jpg');
      }

      await ref
          .read(userProfileServiceProvider)
          .updateProfile(
            nickname: _nicknameController.text.trim(),
            slogan: _sloganController.text.trim(),
            avatar: avatarPath,
            coverImage: coverImagePath,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置已保存')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Uint8List? selectedBytes,
    required String? currentImagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            // 图片预览区域
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: selectedBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        selectedBytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 80,
                      ),
                    )
                  : currentImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageFromPath(currentImagePath),
                    )
                  : const Center(
                      child: Icon(
                        Icons.add_photo_alternate,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
            ),
          ],
        ),
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onTap),
      ),
    );
  }

  Widget _buildImageFromPath(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.grey));
        },
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 80,
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.grey));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('默认个人信息'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _saveSettings, child: const Text('保存')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 昵称设置
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '默认昵称',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: '请输入默认昵称',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 口号设置
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '默认口号',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sloganController,
                      decoration: const InputDecoration(
                        hintText: '请输入默认口号',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // 头像设置
            _buildImagePicker(
              title: '默认头像',
              subtitle: '点击编辑按钮选择头像图片',
              onTap: _pickAvatar,
              selectedBytes: _selectedAvatarBytes,
              currentImagePath: null, // TODO: 从当前配置中获取
            ),

            // 背景图设置
            _buildImagePicker(
              title: '默认背景图',
              subtitle: '点击编辑按钮选择背景图片',
              onTap: _pickCoverImage,
              selectedBytes: _selectedCoverImageBytes,
              currentImagePath: null, // TODO: 从当前配置中获取
            ),

            const SizedBox(height: 24),

            // 说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '说明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 这些设置将作为每日个人信息的默认值\n'
                    '• 您可以在主页点击个人信息卡片来编辑当天的信息\n'
                    '• 如果没有编辑当天的信息，将显示这些默认值\n'
                    '• 头像将自动裁剪为1:1比例',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
