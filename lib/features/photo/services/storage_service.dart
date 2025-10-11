import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 사진을 Firebase Storage에 업로드하고 다운로드 URL 반환
  Future<String> uploadPhoto({
    required String userId,
    required File imageFile,
    required String photoId,
  }) async {
    try {
      final String fileName = '${photoId}${path.extension(imageFile.path)}';
      final Reference storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('photos')
          .child(fileName);

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 업로드
      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);

      // 업로드 완료 대기
      final TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw '사진 업로드 실패: $e';
    }
  }

  /// Storage에서 사진 삭제
  Future<void> deletePhoto({
    required String userId,
    required String photoId,
  }) async {
    try {
      // jpg, png, jpeg 등 확장자를 모르는 경우를 대비해 폴더 내 모든 파일 삭제 시도
      final Reference folderRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('photos');

      final ListResult result = await folderRef.listAll();

      // photoId로 시작하는 파일 찾아서 삭제
      for (var item in result.items) {
        if (item.name.startsWith(photoId)) {
          await item.delete();
        }
      }
    } catch (e) {
      throw '사진 삭제 실패: $e';
    }
  }

  /// 사용자의 모든 사진 삭제 (계정 삭제 시)
  Future<void> deleteAllUserPhotos(String userId) async {
    try {
      final Reference userPhotosRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('photos');

      final ListResult result = await userPhotosRef.listAll();

      // 모든 파일 삭제
      for (var item in result.items) {
        await item.delete();
      }
    } catch (e) {
      throw '사용자 사진 삭제 실패: $e';
    }
  }
}
