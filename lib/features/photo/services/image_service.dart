import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// 이미지 파일 처리 서비스
class ImageService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// 갤러리에서 이미지 선택
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 품질 85%로 압축
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('갤러리에서 이미지 선택 실패: $e');
      return null;
    }
  }

  /// 카메라로 사진 촬영
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('카메라 촬영 실패: $e');
      return null;
    }
  }

  /// 이미지를 앱 디렉토리에 영구 저장
  Future<String> saveImage(File imageFile) async {
    try {
      // 앱 전용 디렉토리 가져오기
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'images');

      // images 디렉토리 생성 (없으면)
      final Directory imagesDirPath = Directory(imagesDir);
      if (!await imagesDirPath.exists()) {
        await imagesDirPath.create(recursive: true);
      }

      // 고유한 파일명 생성 (UUID + 확장자)
      final String fileExtension = path.extension(imageFile.path);
      final String fileName = '${_uuid.v4()}$fileExtension';
      final String savedPath = path.join(imagesDir, fileName);

      // 파일 복사
      final File savedImage = await imageFile.copy(savedPath);

      return savedImage.path;
    } catch (e) {
      debugPrint('이미지 저장 실패: $e');
      rethrow;
    }
  }

  /// 이미지 파일 삭제
  Future<void> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      debugPrint('이미지 삭제 실패: $e');
      rethrow;
    }
  }

  /// 이미지 파일 존재 여부 확인
  Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      debugPrint('이미지 존재 확인 실패: $e');
      return false;
    }
  }

  /// 갤러리 또는 카메라 선택 후 저장
  Future<String?> pickAndSaveImage({required ImageSource source}) async {
    try {
      File? imageFile;

      if (source == ImageSource.gallery) {
        imageFile = await pickImageFromGallery();
      } else {
        imageFile = await takePhoto();
      }

      if (imageFile == null) return null;

      // 앱 디렉토리에 저장
      final String savedPath = await saveImage(imageFile);
      return savedPath;
    } catch (e) {
      debugPrint('이미지 선택 및 저장 실패: $e');
      return null;
    }
  }
}
