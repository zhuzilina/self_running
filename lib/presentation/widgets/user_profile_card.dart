import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/providers.dart';
import 'edit_nickname_dialog.dart';
import 'edit_slogan_dialog.dart';
import 'edit_avatar_dialog.dart';

class UserProfileCard extends ConsumerStatefulWidget {
  const UserProfileCard({super.key});

  @override
  ConsumerState<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends ConsumerState<UserProfileCard> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => Container(
        height: 120,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text('加载失败：$error'),
            ],
          ),
        ),
      ),
      data: (profile) => Container(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 头像 - 可点击编辑
              GestureDetector(
                onTap: () => _showEditAvatarDialog(context, ref, profile),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: profile.avatar != null
                        ? ClipOval(child: _buildAvatarImage(profile.avatar!))
                        : const Icon(Icons.person, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 昵称 - 可点击编辑
                    GestureDetector(
                      onTap: () =>
                          _showEditNicknameDialog(context, ref, profile),
                      child: Text(
                        profile.nickname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 口号 - 可点击编辑
                    GestureDetector(
                      onTap: () => _showEditSloganDialog(context, ref, profile),
                      child: Text(
                        profile.slogan,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditNicknameDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          EditNicknameDialog(currentNickname: profile.nickname),
    );

    if (result == true) {
      ref.invalidate(userProfileProvider);
    }
  }

  Future<void> _showEditSloganDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditSloganDialog(currentSlogan: profile.slogan),
    );

    if (result == true) {
      ref.invalidate(userProfileProvider);
    }
  }

  Future<void> _showEditAvatarDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditAvatarDialog(currentAvatar: profile.avatar),
    );

    if (result == true) {
      ref.invalidate(userProfileProvider);
    }
  }

  Widget _buildAvatarImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 30),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 30),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.person, size: 30),
      );
    }
  }
}
