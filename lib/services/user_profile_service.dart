import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../data/models/user_profile.dart';
import 'storage_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class UserProfileService {
  static const String _profileKey = 'user_profile';
  final StorageService _storage;

  UserProfileService(this._storage);

  Future<void> init() async {
    await _storage.init();
  }

  Future<UserProfile> getUserProfile() async {
    final box = Hive.box(StorageService.dailyStepsBoxName);
    final jsonString = box.get(_profileKey);
    if (jsonString == null || jsonString.isEmpty) {
      return UserProfile.defaultProfile();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      return UserProfile.defaultProfile();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    final box = Hive.box(StorageService.dailyStepsBoxName);
    await box.put(_profileKey, jsonString);
  }

  Future<void> updateProfile({
    String? avatar,
    String? nickname,
    String? slogan,
    String? coverImage,
  }) async {
    final currentProfile = await getUserProfile();
    final updatedProfile = currentProfile.copyWith(
      avatar: avatar,
      nickname: nickname,
      slogan: slogan,
      coverImage: coverImage,
      lastUpdated: DateTime.now(),
    );
    await saveUserProfile(updatedProfile);
  }

  Future<String?> saveImageToLocal(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/user_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final file = File('${imagesDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      print('保存图片失败: $e');
      return null;
    }
  }
}
