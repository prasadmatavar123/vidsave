import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';

typedef Migration = Future<void> Function(Database db);

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const table = 'downloads';
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_url TEXT,
        video_title TEXT,
        video_path TEXT,
        thumbnail_path TEXT,
        platform TEXT,
        file_size INTEGER,
        duration INTEGER,
        download_status TEXT,
        progress REAL,
        created_at TEXT
      )''');
    await db.execute('CREATE INDEX idx_downloads_created ON $table(created_at)');
    await db.execute('CREATE INDEX idx_downloads_status ON $table(download_status)');
  }

  /// Add one entry per new schema version, e.g.
  /// `2: (db) => db.execute('ALTER TABLE downloads ADD COLUMN notes TEXT')`.
  static final Map<int, Migration> _migrations = {};

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    for (var v = oldV + 1; v <= newV; v++) {
      final m = _migrations[v];
      if (m != null) await m(db);
    }
  }

  // ---------- CRUD ----------
  Future<int> insert(Map<String, Object?> values) async =>
      (await database).insert(table, values);

  Future<List<Map<String, Object?>>> query({
    String? search,
    List<String>? statuses,
    bool newest = true,
    int? limit,
    int offset = 0,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('video_title LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (statuses != null && statuses.isNotEmpty) {
      where.add('download_status IN (${List.filled(statuses.length, '?').join(',')})');
      args.addAll(statuses);
    }
    final dir = newest ? 'DESC' : 'ASC';
    return (await database).query(
      table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at $dir, id $dir',
      limit: limit,
      offset: limit == null ? null : offset,
    );
  }

  Future<void> update(int id, Map<String, Object?> values) async =>
      (await database).update(table, values, where: 'id = ?', whereArgs: [id]);

  Future<void> delete(int id) async =>
      (await database).delete(table, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteWhereStatusIn(List<String> statuses) async {
    final marks = List.filled(statuses.length, '?').join(',');
    await (await database).delete(table,
        where: 'download_status IN ($marks)', whereArgs: statuses);
  }

  Future<int> count({List<String>? statuses}) async {
    final db = await database;
    if (statuses == null || statuses.isEmpty) {
      return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table')) ?? 0;
    }
    final marks = List.filled(statuses.length, '?').join(',');
    return Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM $table WHERE download_status IN ($marks)', statuses)) ??
        0;
  }

  Future<int> sumSize() async => Sqflite.firstIntValue(await (await database).rawQuery(
          "SELECT COALESCE(SUM(file_size),0) FROM $table WHERE download_status = 'completed'")) ??
      0;
}
