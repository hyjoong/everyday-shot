import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:everyday_shot/models/photo.dart';

/// SQLite 데이터베이스 서비스 (싱글톤)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'everyday_shot.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 테이블 생성
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        memo TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // date 컬럼에 인덱스 생성 (빠른 날짜 조회를 위해)
    await db.execute('''
      CREATE INDEX idx_photos_date ON photos(date)
    ''');
  }

  /// 사진 저장
  Future<void> savePhoto(Photo photo) async {
    final db = await database;
    await db.insert(
      'photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 날짜의 사진 가져오기
  Future<Photo?> getPhotoByDate(DateTime date) async {
    final db = await database;

    // 날짜만 비교 (시간 제외)
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final results = await db.query(
      'photos',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Photo.fromMap(results.first);
  }

  /// 모든 사진 가져오기 (최신순)
  Future<List<Photo>> getAllPhotos() async {
    final db = await database;
    final results = await db.query(
      'photos',
      orderBy: 'date DESC',
    );

    return results.map((map) => Photo.fromMap(map)).toList();
  }

  /// 사진 삭제
  Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 사진 업데이트
  Future<void> updatePhoto(Photo photo) async {
    final db = await database;
    await db.update(
      'photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  /// 날짜 범위로 사진 가져오기
  Future<List<Photo>> getPhotosByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final results = await db.query(
      'photos',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    return results.map((map) => Photo.fromMap(map)).toList();
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
