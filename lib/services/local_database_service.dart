import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/emotion_record.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _tableName = 'emotions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'emotions_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        studentUid TEXT NOT NULL,
        emotion TEXT NOT NULL,
        note TEXT,
        createdAt INTEGER NOT NULL,
        dayKey TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_student_uid ON $_tableName(studentUid)');
    await db.execute('CREATE INDEX idx_created_at ON $_tableName(createdAt)');
    await db.execute('CREATE INDEX idx_is_synced ON $_tableName(isSynced)');
  }

  Future<String> insertEmotion(EmotionRecord emotion) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final emotionWithId = emotion.copyWith(id: id);
    
    await db.insert(
      _tableName,
      emotionWithId.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<EmotionRecord>> getEmotionsByStudent(String studentUid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'studentUid = ?',
      whereArgs: [studentUid],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => EmotionRecord.fromMap(maps[i]));
  }

  Future<List<EmotionRecord>> getUnsyncedEmotions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => EmotionRecord.fromMap(maps[i]));
  }

  Future<void> markAsSynced(String emotionId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [emotionId],
    );
  }

  Future<void> deleteEmotion(String emotionId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [emotionId],
    );
  }

  Future<void> clearAllEmotions() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<int> getEmotionCount(String studentUid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE studentUid = ?',
      [studentUid],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getEmotionStats(String studentUid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT emotion, COUNT(*) as count FROM $_tableName WHERE studentUid = ? GROUP BY emotion',
      [studentUid],
    );
    
    final Map<String, int> stats = {};
    for (final row in result) {
      stats[row['emotion'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
