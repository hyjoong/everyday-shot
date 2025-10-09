import 'dart:io';
import 'package:everyday_shot/models/photo.dart';
import 'package:everyday_shot/features/photo/services/database_service.dart';
import 'package:everyday_shot/features/photo/services/firestore_service.dart';
import 'package:everyday_shot/features/photo/services/storage_service.dart';

/// 로컬 DB와 Firebase 간 동기화를 담당하는 서비스
class SyncService {
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  /// 로컬 사진을 클라우드로 업로드
  /// 로그인 시 또는 수동 동기화 시 호출
  Future<void> uploadLocalPhotosToCloud(String userId) async {
    try {
      // 로컬의 모든 사진 가져오기
      final localPhotos = await _databaseService.getAllPhotos();

      // 클라우드의 모든 사진 가져오기
      final cloudPhotos = await _firestoreService.getUserPhotos(userId);
      final cloudPhotoIds = cloudPhotos.map((p) => p.id).toSet();

      // 클라우드에 없는 로컬 사진만 업로드
      for (var localPhoto in localPhotos) {
        if (!cloudPhotoIds.contains(localPhoto.id)) {
          await _uploadPhotoToCloud(userId, localPhoto);
        }
      }
    } catch (e) {
      throw '클라우드 동기화 실패: $e';
    }
  }

  /// 클라우드 사진을 로컬로 다운로드
  /// 로그인 시 또는 수동 동기화 시 호출
  Future<void> downloadCloudPhotosToLocal(String userId) async {
    try {
      // 클라우드의 모든 사진 가져오기
      final cloudPhotos = await _firestoreService.getUserPhotos(userId);

      // 로컬의 모든 사진 가져오기
      final localPhotos = await _databaseService.getAllPhotos();
      final localPhotoIds = localPhotos.map((p) => p.id).toSet();

      // 로컬에 없는 클라우드 사진만 다운로드
      for (var cloudPhoto in cloudPhotos) {
        if (!localPhotoIds.contains(cloudPhoto.id)) {
          await _databaseService.savePhoto(cloudPhoto);
        }
      }
    } catch (e) {
      throw '로컬 동기화 실패: $e';
    }
  }

  /// 양방향 동기화 (로그인 시 호출)
  Future<void> syncAll(String userId) async {
    try {
      // 1. 로컬 → 클라우드 업로드
      await uploadLocalPhotosToCloud(userId);

      // 2. 클라우드 → 로컬 다운로드
      await downloadCloudPhotosToLocal(userId);
    } catch (e) {
      throw '전체 동기화 실패: $e';
    }
  }

  /// 단일 사진 추가 및 동기화
  Future<void> addPhotoWithSync({
    String? userId,
    required Photo photo,
  }) async {
    try {
      // 1. 로컬에 저장
      await _databaseService.savePhoto(photo);

      // 2. 로그인 상태면 클라우드에도 저장
      if (userId != null) {
        await _uploadPhotoToCloud(userId, photo);
      }
    } catch (e) {
      throw '사진 추가 실패: $e';
    }
  }

  /// 단일 사진 업데이트 및 동기화
  Future<void> updatePhotoWithSync({
    String? userId,
    required Photo photo,
  }) async {
    try {
      // 1. 로컬 업데이트
      await _databaseService.updatePhoto(photo);

      // 2. 로그인 상태면 클라우드에도 업데이트
      if (userId != null) {
        await _uploadPhotoToCloud(userId, photo);
      }
    } catch (e) {
      throw '사진 업데이트 실패: $e';
    }
  }

  /// 단일 사진 삭제 및 동기화
  Future<void> deletePhotoWithSync({
    String? userId,
    required String photoId,
  }) async {
    try {
      // 1. 로컬 삭제
      await _databaseService.deletePhoto(photoId);

      // 2. 로그인 상태면 클라우드에서도 삭제
      if (userId != null) {
        await _firestoreService.deletePhoto(userId: userId, photoId: photoId);
        await _storageService.deletePhoto(userId: userId, photoId: photoId);
      }
    } catch (e) {
      throw '사진 삭제 실패: $e';
    }
  }

  /// 사진을 Firebase Storage에 업로드하고 Firestore에 메타데이터 저장
  Future<void> _uploadPhotoToCloud(String userId, Photo photo) async {
    try {
      final imageFile = File(photo.imagePath);

      // 파일이 존재하는지 확인
      if (!imageFile.existsSync()) {
        throw '이미지 파일을 찾을 수 없습니다: ${photo.imagePath}';
      }

      // 1. Firebase Storage에 이미지 업로드
      final downloadUrl = await _storageService.uploadPhoto(
        userId: userId,
        imageFile: imageFile,
        photoId: photo.id,
      );

      // 2. Firestore에 메타데이터 저장 (imagePath를 downloadUrl로 변경)
      final cloudPhoto = photo.copyWith(imagePath: downloadUrl);
      await _firestoreService.addPhoto(userId: userId, photo: cloudPhoto);
    } catch (e) {
      throw '사진 업로드 실패: $e';
    }
  }

  /// 계정 삭제 시 모든 데이터 삭제
  Future<void> deleteAllData(String userId) async {
    try {
      // 1. 클라우드 데이터 삭제
      await _firestoreService.deleteAllUserData(userId);
      await _storageService.deleteAllUserPhotos(userId);

      // 2. 로컬 데이터는 유지 (사용자가 원하면 별도로 삭제)
    } catch (e) {
      throw '데이터 삭제 실패: $e';
    }
  }

  /// 로그아웃 시 로컬 데이터 삭제 여부 (선택사항)
  Future<void> clearLocalData() async {
    try {
      final localPhotos = await _databaseService.getAllPhotos();
      for (var photo in localPhotos) {
        await _databaseService.deletePhoto(photo.id);
      }
    } catch (e) {
      throw '로컬 데이터 삭제 실패: $e';
    }
  }
}
