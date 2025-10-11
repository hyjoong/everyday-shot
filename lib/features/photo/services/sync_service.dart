import 'dart:io';
import 'package:flutter/material.dart';
import 'package:everyday_shot/models/photo.dart';
import 'package:everyday_shot/features/photo/services/database_service.dart';
import 'package:everyday_shot/features/photo/services/firestore_service.dart';
import 'package:everyday_shot/features/photo/services/storage_service.dart';

/// 로컬 DB, Firestore, Firebase Storage 동기화 서비스
class SyncService {
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  /// 로컬 사진 메타데이터를 Firestore로 업로드 (이미지는 로컬만)
  /// 로그인 시 또는 수동 동기화 시 호출
  Future<void> uploadLocalPhotosToCloud(String userId) async {
    try {
      // 로컬의 모든 사진 가져오기
      final localPhotos = await _databaseService.getAllPhotos();

      // 클라우드의 모든 사진 가져오기
      final cloudPhotos = await _firestoreService.getUserPhotos(userId);
      final cloudPhotoIds = cloudPhotos.map((p) => p.id).toSet();

      // 클라우드에 없는 로컬 사진 메타데이터만 업로드
      for (var localPhoto in localPhotos) {
        if (!cloudPhotoIds.contains(localPhoto.id)) {
          // 이미지 없이 메타데이터만 Firestore에 저장
          final metadataPhoto = localPhoto.copyWith(imagePath: ''); // 빈 문자열로 설정
          await _firestoreService.addPhoto(userId: userId, photo: metadataPhoto);
        }
      }
    } catch (e) {
      throw '클라우드 동기화 실패: $e';
    }
  }

  /// 클라우드 메타데이터를 로컬로 다운로드 (이미지는 제외)
  /// 참고: 이미지 파일은 각 기기에만 저장되므로, 다른 기기에서는 메타데이터만 동기화됨
  Future<void> downloadCloudPhotosToLocal(String userId) async {
    try {
      // 클라우드의 모든 사진 메타데이터 가져오기
      final cloudPhotos = await _firestoreService.getUserPhotos(userId);

      // 로컬의 모든 사진 가져오기
      final localPhotos = await _databaseService.getAllPhotos();
      final localPhotoIds = localPhotos.map((p) => p.id).toSet();

      // 로컬에 없는 클라우드 메타데이터 처리 (이미지 없음 - 건너뜀)
      // 참고: 실제 이미지 파일은 각 기기의 로컬에만 저장되므로
      // 다른 기기에서는 메타데이터만 있고 이미지는 없음
      for (var cloudPhoto in cloudPhotos) {
        if (!localPhotoIds.contains(cloudPhoto.id)) {
          // 이미지 파일 없이 메타데이터만 있는 항목은 로컬에 저장하지 않음
          // 필요시 placeholder 이미지로 저장 가능
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

  /// 단일 사진 추가 및 동기화 (이미지 + 메타데이터)
  Future<void> addPhotoWithSync({
    String? userId,
    required Photo photo,
  }) async {
    try {
      // 1. 로컬에 저장
      await _databaseService.savePhoto(photo);

      // 2. 로그인 상태면 Storage에 이미지 업로드 + Firestore에 메타데이터 저장
      if (userId != null && photo.imagePath.isNotEmpty) {
        // Storage에 이미지 업로드
        final downloadUrl = await _storageService.uploadPhoto(
          userId: userId,
          imageFile: File(photo.imagePath),
          photoId: photo.id,
        );

        // Firestore에 메타데이터 + Storage URL 저장
        final cloudPhoto = photo.copyWith(imagePath: downloadUrl);
        await _firestoreService.addPhoto(userId: userId, photo: cloudPhoto);
      }
    } catch (e) {
      throw '사진 추가 실패: $e';
    }
  }

  /// 단일 사진 업데이트 및 동기화 (메타데이터만)
  Future<void> updatePhotoWithSync({
    String? userId,
    required Photo photo,
  }) async {
    try {
      // 1. 로컬 업데이트
      await _databaseService.updatePhoto(photo);

      // 2. 로그인 상태면 Firestore 메타데이터 업데이트
      if (userId != null) {
        // Firestore에서 기존 메타데이터 가져오기
        await _firestoreService.updatePhoto(userId: userId, photo: photo);
      }
    } catch (e) {
      throw '사진 업데이트 실패: $e';
    }
  }

  /// 단일 사진 삭제 및 동기화 (Storage + Firestore)
  Future<void> deletePhotoWithSync({
    String? userId,
    required String photoId,
  }) async {
    try {
      // 1. 로컬 삭제
      await _databaseService.deletePhoto(photoId);

      // 2. 로그인 상태면 Storage와 Firestore에서도 삭제
      if (userId != null) {
        // Storage에서 이미지 삭제
        await _storageService.deletePhoto(userId: userId, photoId: photoId);

        // Firestore에서 메타데이터 삭제
        await _firestoreService.deletePhoto(userId: userId, photoId: photoId);
      }
    } catch (e) {
      throw '사진 삭제 실패: $e';
    }
  }


  /// 계정 삭제 시 Storage 및 Firestore 데이터 삭제
  Future<void> deleteAllData(String userId) async {
    try {
      // 1. Firestore에서 사용자의 모든 사진 메타데이터 가져오기
      final userPhotos = await _firestoreService.getUserPhotos(userId);

      // 2. Storage에서 각 사진 이미지 삭제
      for (var photo in userPhotos) {
        try {
          await _storageService.deletePhoto(userId: userId, photoId: photo.id);
        } catch (e) {
          // 개별 사진 삭제 실패는 무시하고 계속 진행
          debugPrint('Storage 사진 삭제 실패 (${photo.id}): $e');
        }
      }

      // 3. Firestore 데이터 삭제
      await _firestoreService.deleteAllUserData(userId);

      // 로컬 데이터는 유지 (사용자가 원하면 별도로 삭제)
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
