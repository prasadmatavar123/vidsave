import '../database/database_helper.dart';
import '../models/download_model.dart';

class DownloadRepository {
  DownloadRepository(this._db);
  final DatabaseHelper _db;

  Future<int> insert(DownloadModel m) => _db.insert(m.toMap());

  Future<List<DownloadModel>> fetch({
    String? search,
    List<DownloadStatus>? statuses,
    bool newest = true,
    int? limit,
    int offset = 0,
  }) async {
    final rows = await _db.query(
      search: search,
      statuses: statuses?.map((s) => s.name).toList(),
      newest: newest,
      limit: limit,
      offset: offset,
    );
    return rows.map(DownloadModel.fromMap).toList();
  }

  Future<void> updateStatus(int id, DownloadStatus s) =>
      _db.update(id, {'download_status': s.name});

  Future<void> updateProgress(int id, double progress) =>
      _db.update(id, {'progress': progress});

  Future<void> update(DownloadModel m) => _db.update(m.id!, m.toMap());

  Future<void> delete(int id) => _db.delete(id);

  Future<int> count({List<DownloadStatus>? statuses}) =>
      _db.count(statuses: statuses?.map((s) => s.name).toList());

  Future<int> totalSize() => _db.sumSize();

  Future<void> clearFinished() => _db.deleteWhereStatusIn(
      [DownloadStatus.completed.name, DownloadStatus.failed.name]);
}
