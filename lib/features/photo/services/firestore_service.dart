import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everyday_shot/models/photo.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 참조 (사용자별 서브컬렉션)
  CollectionReference _photosCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('photos');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 사용자 프로필 생성 또는 업데이트
  Future<void> createOrUpdateUser({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      await _usersCollection.doc(userId).set({
        'email': email,
        'displayName': displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw '사용자 정보 저장 실패: $e';
    }
  }

  /// 사진 추가
  Future<void> addPhoto({
    required String userId,
    required Photo photo,
  }) async {
    try {
      await _photosCollection(userId).doc(photo.id).set({
        'date': photo.date.toIso8601String().split('T')[0],
        'imageUrl': photo.imagePath, // Firebase Storage URL로 저장
        'memo': photo.memo,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw '사진 저장 실패: $e';
    }
  }

  /// 사진 업데이트
  Future<void> updatePhoto({
    required String userId,
    required Photo photo,
  }) async {
    try {
      final docRef = _photosCollection(userId).doc(photo.id);
      final doc = await docRef.get();

      // 해당 사진이 존재하는지 확인
      if (!doc.exists) {
        return;
      }

      await docRef.update({
        'date': photo.date.toIso8601String().split('T')[0],
        'imageUrl': photo.imagePath,
        'memo': photo.memo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ 사진 업데이트 오류: $e');
    }
  }

  /// 사진 삭제
  Future<void> deletePhoto({
    required String userId,
    required String photoId,
  }) async {
    try {
      final docRef = _photosCollection(userId).doc(photoId);
      final doc = await docRef.get();

      // 해당 사진이 존재하는지 확인
      if (!doc.exists) {
        print('⚠️ 삭제할 사진이 Firestore에 없습니다. 무시합니다.');
        return;
      }

      await docRef.delete();
    } catch (e) {
      print('⚠️ 사진 삭제 오류: $e');
      // 에러를 throw하지 않고 로그만 남김
    }
  }

  /// 특정 사용자의 모든 사진 가져오기
  Future<List<Photo>> getUserPhotos(String userId) async {
    try {
      // 사용자 문서가 존재하는지 확인
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        print('ℹ️ 사용자 문서가 없습니다. 빈 목록 반환');
        return [];
      }

      final querySnapshot = await _photosCollection(userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Photo(
          id: doc.id,
          date: DateTime.parse(data['date']),
          imagePath: data['imageUrl'] ?? '',
          memo: data['memo'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('⚠️ 사진 목록 불러오기 오류: $e');
      // 에러 발생 시 빈 목록 반환 (앱이 터지지 않도록)
      return [];
    }
  }

  /// 특정 날짜의 사진 가져오기
  Future<Photo?> getPhotoByDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final querySnapshot = await _photosCollection(userId)
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return Photo(
        id: doc.id,
        date: DateTime.parse(data['date']),
        imagePath: data['imageUrl'] ?? '',
        memo: data['memo'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      throw '사진 불러오기 실패: $e';
    }
  }

  /// 사용자의 사진을 실시간으로 스트리밍
  Stream<List<Photo>> streamUserPhotos(String userId) {
    return _photosCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Photo(
          id: doc.id,
          date: DateTime.parse(data['date']),
          imagePath: data['imageUrl'] ?? '',
          memo: data['memo'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  /// 모든 사용자 데이터 삭제 (계정 삭제 시)
  Future<void> deleteAllUserData(String userId) async {
    try {
      // 사용자의 모든 사진 삭제
      final photosSnapshot = await _photosCollection(userId).get();

      final batch = _firestore.batch();
      for (var doc in photosSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 사용자 프로필 삭제
      batch.delete(_usersCollection.doc(userId));

      await batch.commit();
    } catch (e) {
      throw '사용자 데이터 삭제 실패: $e';
    }
  }
}
