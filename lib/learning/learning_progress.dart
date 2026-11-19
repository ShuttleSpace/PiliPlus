import 'package:PiliPlus/learning/learning_watch_record.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

/// 本地观看进度与历史。完全不写回 B 站账号。
class LearningProgress {
  LearningProgress._();

  static final LearningProgress instance = LearningProgress._();

  static const String _recordsKey = 'learningProgress';

  Box<dynamic>? _box;
  final RxList<LearningWatchRecord> records = <LearningWatchRecord>[].obs;

  void attach(Box<dynamic> box) {
    _box = box;
    final stored = box.get(_recordsKey);
    loadFromJson(stored is List ? stored : const <dynamic>[]);
  }

  void loadFromJson(List<dynamic> raw) {
    records
      ..clear()
      ..addAll(
        raw.whereType<Map>().map(
          (item) =>
              LearningWatchRecord.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    records.refresh();
  }

  /// 同一 bvid（合集多 P）最近一次观看记录，用于从清单进入时定位分 P。
  LearningWatchRecord? latestForBvid(String bvid) {
    LearningWatchRecord? latest;
    for (final record in records) {
      if (record.bvid != bvid) continue;
      if (latest == null || record.lastPlayedAt.isAfter(latest.lastPlayedAt)) {
        latest = record;
      }
    }
    return latest;
  }

  LearningWatchRecord? get({required String bvid, required int cid}) {
    final key = '$bvid:$cid';
    for (final record in records) {
      if (record.key == key) return record;
    }
    return null;
  }

  void record({
    required String bvid,
    required int cid,
    required String title,
    required String cover,
    required int positionMs,
    required int durationMs,
    bool? completed,
  }) {
    if (bvid.isEmpty || positionMs <= 0) return;

    // 完播阈值 [假设]：播放到 90% 即视为完播，短分 P 也不会误判。
    final isCompleted =
        completed ?? (durationMs > 0 && positionMs >= durationMs * 0.9);
    final existing = get(bvid: bvid, cid: cid);
    final entry = LearningWatchRecord(
      bvid: bvid,
      cid: cid,
      title: title,
      cover: cover,
      positionMs: isCompleted ? durationMs : positionMs,
      durationMs: durationMs,
      lastPlayedAt: DateTime.now(),
      completed: isCompleted || (existing?.completed ?? false),
    );

    records.removeWhere((item) => item.key == entry.key);
    records.add(entry);
    _persist();
  }

  List<LearningWatchRecord> history() {
    final sorted = List<LearningWatchRecord>.from(records)
      ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return sorted;
  }

  Map<String, dynamic> stats() {
    final total = records.length;
    final completed = records.where((item) => item.completed).length;
    final watchedMs = records.fold<int>(
      0,
      (sum, item) => sum + (item.completed ? item.durationMs : item.positionMs),
    );
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = records
        .where((item) => item.lastPlayedAt.isAfter(weekAgo))
        .length;
    return {
      'total': total,
      'completed': completed,
      'completionRate': total == 0 ? 0.0 : completed / total,
      'watchedMs': watchedMs,
      'thisWeek': thisWeek,
    };
  }

  List<Map<String, dynamic>> exportJson() =>
      records.map((item) => item.toJson()).toList();

  void _persist() {
    _box?.put(_recordsKey, exportJson());
    records.refresh();
  }
}
