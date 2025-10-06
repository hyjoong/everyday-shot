import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

/// 이미지 파일 처리 서비스
class ImageService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// 특정 날짜의 갤러리 사진 가져오기
  Future<List<AssetEntity>> getPhotosForDate(DateTime date) async {
    try {
      // 권한 요청
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        debugPrint('사진 접근 권한 없음');
        return [];
      }

      // 날짜 범위 설정 (해당 날짜의 00:00 ~ 23:59)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // 갤러리에서 사진 가져오기
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          createTimeCond: DateTimeCond(
            min: startOfDay,
            max: endOfDay,
          ),
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false, // 최신순
            ),
          ],
        ),
      );

      if (albums.isEmpty) return [];

      // 최근 사진들 가져오기 (최대 20장)
      final List<AssetEntity> photos = await albums.first.getAssetListRange(
        start: 0,
        end: 20,
      );

      return photos;
    } catch (e) {
      debugPrint('갤러리 사진 가져오기 실패: $e');
      return [];
    }
  }

  /// EXIF 데이터에서 촬영 날짜 추출
  Future<DateTime?> getImageDateTime(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // EXIF 데이터에서 촬영 날짜 추출
      final exifData = image.exif;
      if (exifData.isEmpty) return null;

      // DateTime Original 또는 DateTime 태그 확인
      final dateTimeOriginal = exifData['EXIF DateTimeOriginal']?.toString();
      final dateTime = exifData['Image DateTime']?.toString();

      final dateString = dateTimeOriginal ?? dateTime;
      if (dateString == null) return null;

      // EXIF 날짜 형식: "YYYY:MM:DD HH:mm:ss"
      // DateTime 형식으로 변환
      final parts = dateString.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
    } catch (e) {
      debugPrint('EXIF 날짜 추출 실패: $e');
      return null;
    }
  }

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
