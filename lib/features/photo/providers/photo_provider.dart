import 'package:flutter/foundation.dart';
import 'package:everyday_shot/models/photo.dart';
import 'package:everyday_shot/features/photo/services/database_service.dart';
import 'package:everyday_shot/features/photo/services/sync_service.dart';

/// 사진 상태 관리 Provider
class PhotoProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();

  List<Photo> _photos = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _currentUserId;

  /// 모든 사진 목록
  List<Photo> get photos => _photos;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 동기화 상태
  bool get isSyncing => _isSyncing;

  /// 현재 사용자 ID 설정 (로그인 시 호출)
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  /// 초기화 및 모든 사진 로드 (최신 날짜순)
  Future<void> loadPhotos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _photos = await _databaseService.getAllPhotos();
      // 날짜 기준 최신순 정렬 보장
      _photos.sort((a, b) => b.date.compareTo(a.date));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Firestore 메타데이터 동기화 (로그인 시 호출)
  Future<void> syncWithCloud(String userId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      _currentUserId = userId;
      await _syncService.syncAll(userId);
      await loadPhotos();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 특정 날짜의 사진 가져오기
  Photo? getPhotoByDate(DateTime date) {
    // 날짜만 비교 (시간 제외)
    final targetDate = DateTime(date.year, date.month, date.day);

    return _photos.cast<Photo?>().firstWhere(
      (photo) {
        final photoDate = DateTime(
          photo!.date.year,
          photo.date.month,
          photo.date.day,
        );
        return photoDate.isAtSameMomentAs(targetDate);
      },
      orElse: () => null,
    );
  }

  /// 사진 추가
  Future<void> addPhoto(Photo photo) async {
    await _syncService.addPhotoWithSync(
      userId: _currentUserId,
      photo: photo,
    );
    _photos.add(photo);
    // 날짜 기준 최신순 정렬
    _photos.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// 사진 업데이트
  Future<void> updatePhoto(Photo photo) async {
    await _syncService.updatePhotoWithSync(
      userId: _currentUserId,
      photo: photo,
    );

    final index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      _photos[index] = photo;
      // 날짜가 변경되었을 수 있으므로 다시 정렬
      _photos.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  /// 사진 삭제
  Future<void> deletePhoto(String id) async {
    try {
      // SyncService 사용 (로그인 상태면 Firestore에서도 삭제)
      await _syncService.deletePhotoWithSync(
        userId: _currentUserId,
        photoId: id,
      );
      _photos.removeWhere((photo) => photo.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('사진 삭제 실패: $e');
      rethrow;
    }
  }

  /// 날짜 범위로 사진 가져오기
  Future<List<Photo>> getPhotosByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _databaseService.getPhotosByDateRange(start, end);
    } catch (e) {
      debugPrint('날짜 범위 사진 조회 실패: $e');
      return [];
    }
  }

  /// 특정 월의 사진이 있는 날짜들 가져오기
  List<DateTime> getPhotoDatesInMonth(int year, int month) {
    final datesWithPhotos = <DateTime>[];

    for (var photo in _photos) {
      if (photo.date.year == year && photo.date.month == month) {
        final dateOnly = DateTime(
          photo.date.year,
          photo.date.month,
          photo.date.day,
        );
        if (!datesWithPhotos.contains(dateOnly)) {
          datesWithPhotos.add(dateOnly);
        }
      }
    }

    return datesWithPhotos;
  }

  /// 로그아웃 시 로컬 데이터 완전 삭제
  Future<void> clearLocalData() async {
    try {
      await _syncService.clearLocalData();
      _photos = [];
      notifyListeners();
      debugPrint('✅ 로컬 데이터 삭제 완료');
    } catch (e) {
      debugPrint('❌ 로컬 데이터 삭제 실패: $e');
      rethrow;
    }
  }
}
