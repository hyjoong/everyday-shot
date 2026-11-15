import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyday_shot/models/photo.dart';

void main() {
  final createdAt = DateTime(2026, 11, 15, 9, 30);
  final photo = Photo(
    id: 'photo-1',
    date: DateTime(2026, 11, 15),
    imagePath: '/tmp/photo.jpg',
    memo: '오늘의 한 컷',
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  test('Photo는 SQLite용 Map으로 변환했다가 그대로 복원된다', () {
    expect(Photo.fromMap(photo.toMap()), photo);
  });

  test('copyWith는 지정한 필드만 바꾼다', () {
    final edited = photo.copyWith(memo: '수정된 메모');
    expect(edited.memo, '수정된 메모');
    expect(edited.id, photo.id);
    expect(edited.date, photo.date);
  });

  test('Firestore Timestamp가 DateTime과 오가며 값이 유지된다', () {
    final ts = Timestamp.fromDate(createdAt);
    expect(ts.toDate(), createdAt);
  });
}
