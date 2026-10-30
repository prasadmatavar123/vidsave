import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/download_manager.dart';
import '../../../core/utils/safe_notifier.dart';
import '../../../data/models/download_model.dart';
import '../../../data/repositories/download_repository.dart';

enum HistoryFilter { all, completed, failed }

class HistoryViewModel extends ChangeNotifier with SafeNotifier {
  HistoryViewModel(this._repo, this._manager) {
    _tick = _manager.libraryTick;
    _manager.addListener(_onManager);
    refresh();
  }

  final DownloadRepository _repo;
  final DownloadManager _manager;

  List<DownloadModel> items = [];
  String query = '';
  bool newest = true;
  HistoryFilter filter = HistoryFilter.all;
  bool loading = false;
  bool hasMore = true;

  int _gen = 0;
  int _tick = 0;
  bool _suppress = false;
  Timer? _debounce;

  List<DownloadStatus> get _statuses => switch (filter) {
        HistoryFilter.all => [DownloadStatus.completed, DownloadStatus.failed],
        HistoryFilter.completed => [DownloadStatus.completed],
        HistoryFilter.failed => [DownloadStatus.failed],
      };

  void _onManager() {
    if (_manager.libraryTick != _tick) {
      _tick = _manager.libraryTick;
      if (!_suppress) refresh();
    }
  }

  Future<void> refresh() async {
    _gen++;
    items = [];
    hasMore = true;
    await _loadPage();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    await _loadPage();
  }

  Future<void> _loadPage() async {
    final gen = _gen;
    loading = true;
    notifyListeners();
    final page = await _repo.fetch(
      search: query,
      statuses: _statuses,
      newest: newest,
      limit: AppConstants.pageSize,
      offset: items.length,
    );
    if (gen != _gen) return; // a newer refresh superseded this load
    items = [...items, ...page];
    hasMore = page.length == AppConstants.pageSize;
    loading = false;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), refresh);
  }

  void setNewest(bool v) {
    if (newest == v) return;
    newest = v;
    refresh();
  }

  void setFilter(HistoryFilter f) {
    if (filter == f) return;
    filter = f;
    refresh();
  }

  Future<void> delete(DownloadModel m) async {
    _suppress = true; // update locally, keep scroll position
    await _manager.deleteDownload(m);
    _suppress = false;
    items = items.where((e) => e.id != m.id).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _manager.removeListener(_onManager);
    super.dispose();
  }
}
