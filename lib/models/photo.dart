/// 사진 모델 클래스
class Photo {
  /// 고유 ID (UUID)
  final String id;

  /// 사진 찍은 날짜
  final DateTime date;

  /// 로컬 파일 경로
  final String imagePath;

  /// 메모 (nullable)
  final String? memo;

  /// 생성 시간
  final DateTime createdAt;

  /// 수정 시간
  final DateTime updatedAt;

  const Photo({
    required this.id,
    required this.date,
    required this.imagePath,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map으로 변환 (SQLite 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Map에서 Photo 객체 생성 (SQLite 읽기용)
  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      imagePath: map['imagePath'] as String,
      memo: map['memo'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// 불변 객체 복사 (필드 업데이트용)
  Photo copyWith({
    String? id,
    DateTime? date,
    String? imagePath,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Photo(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Photo(id: $id, date: $date, imagePath: $imagePath, memo: $memo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Photo &&
        other.id == id &&
        other.date == date &&
        other.imagePath == imagePath &&
        other.memo == memo &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        imagePath.hashCode ^
        memo.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
