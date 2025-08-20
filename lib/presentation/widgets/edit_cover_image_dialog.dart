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
import 'package:image_picker/image_picker.dart';
import '../states/providers.dart';

class EditCoverImageDialog extends ConsumerStatefulWidget {
  final String? currentCoverImage;

  const EditCoverImageDialog({super.key, this.currentCoverImage});

  @override
  ConsumerState<EditCoverImageDialog> createState() =>
      _EditCoverImageDialogState();
}

class _EditCoverImageDialogState extends ConsumerState<EditCoverImageDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑背景图'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片预览区域
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: _selectedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.currentCoverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildCoverImage(widget.currentCoverImage!),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                          Colors.purple.shade600,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
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
            onPressed: _selectedImageBytes != null ? _saveCoverImage : null,
            child: const Text('确认'),
          ),
      ],
    );
  }

  Widget _buildCoverImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败：$e')));
    }
  }

  Future<void> _saveCoverImage() async {
    if (_selectedImageBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(userProfileServiceProvider);
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = await service.saveImageToLocal(
        _selectedImageBytes!,
        fileName,
      );

      if (savedPath != null) {
        await service.updateProfile(coverImage: savedPath);
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
