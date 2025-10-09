import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:everyday_shot/models/photo.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 참조
  CollectionReference get _photosCollection => _firestore.collection('photos');
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
      await _photosCollection.doc(photo.id).set({
        'userId': userId,
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
      final docRef = _photosCollection.doc(photo.id);
      final doc = await docRef.get();

      // 해당 사진이 존재하고 본인 소유인지 확인
      if (!doc.exists) {
        throw '사진을 찾을 수 없습니다';
      }
      if (doc.get('userId') != userId) {
        throw '권한이 없습니다';
      }

      await docRef.update({
        'date': photo.date.toIso8601String().split('T')[0],
        'imageUrl': photo.imagePath,
        'memo': photo.memo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw '사진 업데이트 실패: $e';
    }
  }

  /// 사진 삭제
  Future<void> deletePhoto({
    required String userId,
    required String photoId,
  }) async {
    try {
      final docRef = _photosCollection.doc(photoId);
      final doc = await docRef.get();

      // 해당 사진이 존재하고 본인 소유인지 확인
      if (!doc.exists) {
        throw '사진을 찾을 수 없습니다';
      }
      if (doc.get('userId') != userId) {
        throw '권한이 없습니다';
      }

      await docRef.delete();
    } catch (e) {
      throw '사진 삭제 실패: $e';
    }
  }

  /// 특정 사용자의 모든 사진 가져오기
  Future<List<Photo>> getUserPhotos(String userId) async {
    try {
      final querySnapshot = await _photosCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Photo(
          id: doc.id,
          date: DateTime.parse(data['date']),
          imagePath: data['imageUrl'] ?? '',
          memo: data['memo'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw '사진 목록 불러오기 실패: $e';
    }
  }

  /// 특정 날짜의 사진 가져오기
  Future<Photo?> getPhotoByDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final querySnapshot = await _photosCollection
          .where('userId', isEqualTo: userId)
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
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      throw '사진 불러오기 실패: $e';
    }
  }

  /// 사용자의 사진을 실시간으로 스트리밍
  Stream<List<Photo>> streamUserPhotos(String userId) {
    return _photosCollection
        .where('userId', isEqualTo: userId)
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
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  /// 모든 사용자 데이터 삭제 (계정 삭제 시)
  Future<void> deleteAllUserData(String userId) async {
    try {
      // 사용자의 모든 사진 삭제
      final photosSnapshot = await _photosCollection
          .where('userId', isEqualTo: userId)
          .get();

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
