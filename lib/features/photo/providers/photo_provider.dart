import 'package:flutter/foundation.dart';
import 'package:everyday_shot/models/photo.dart';
import 'package:everyday_shot/features/photo/services/database_service.dart';

/// 사진 상태 관리 Provider
class PhotoProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Photo> _photos = [];
  bool _isLoading = false;

  /// 모든 사진 목록
  List<Photo> get photos => _photos;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 초기화 및 모든 사진 로드
  Future<void> loadPhotos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _photos = await _databaseService.getAllPhotos();
    } catch (e) {
      debugPrint('사진 로드 실패: $e');
    } finally {
      _isLoading = false;
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
    try {
      await _databaseService.savePhoto(photo);
      _photos.insert(0, photo); // 최신순으로 맨 앞에 추가
      notifyListeners();
    } catch (e) {
      debugPrint('사진 추가 실패: $e');
      rethrow;
    }
  }

  /// 사진 업데이트
  Future<void> updatePhoto(Photo photo) async {
    try {
      await _databaseService.updatePhoto(photo);

      final index = _photos.indexWhere((p) => p.id == photo.id);
      if (index != -1) {
        _photos[index] = photo;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('사진 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 사진 삭제
  Future<void> deletePhoto(String id) async {
    try {
      await _databaseService.deletePhoto(id);
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
}
