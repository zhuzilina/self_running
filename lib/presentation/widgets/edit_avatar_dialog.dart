import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../states/providers.dart';

class EditAvatarDialog extends ConsumerStatefulWidget {
  final String? currentAvatar;

  const EditAvatarDialog({super.key, this.currentAvatar});

  @override
  ConsumerState<EditAvatarDialog> createState() => _EditAvatarDialogState();
}

class _EditAvatarDialogState extends ConsumerState<EditAvatarDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑头像'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片预览区域
          Container(
            height: 120,
            width: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: _selectedImageBytes != null
                ? ClipOval(
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.currentAvatar != null
                ? ClipOval(child: _buildAvatarImage(widget.currentAvatar!))
                : const Icon(Icons.person, size: 60, color: Colors.grey),
          ),

          // 选择图片按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('拍照'),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('相册'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(
            onPressed: _selectedImageBytes != null ? _saveAvatar : null,
            child: const Text('确认'),
          ),
      ],
    );
  }

  Widget _buildAvatarImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image != null) {
        // 进入裁剪页面
        final croppedFile = await _cropImage(image.path);
        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImagePath = croppedFile.path;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败：$e')));
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 1:1 比例
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // 锁定1:1比例
            hideBottomControls: false,
            showCropGrid: true,
            cropGridColumnCount: 3,
            cropGridRowCount: 3,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: '裁剪头像',
            aspectRatioLockEnabled: true, // 锁定1:1比例
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: true,
            rotateClockwiseButtonHidden: true,
            aspectRatioLockDimensionSwapEnabled: false,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
        ],
      );
      return croppedFile;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('裁剪失败：$e')));
      return null;
    }
  }

  Future<void> _saveAvatar() async {
    if (_selectedImageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(userProfileServiceProvider);
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = await service.saveImageToLocal(
        _selectedImageBytes!,
        fileName,
      );

      if (savedPath != null) {
        await service.updateProfile(avatar: savedPath);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('保存图片失败');
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
}
