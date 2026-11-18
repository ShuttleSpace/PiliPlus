import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

enum AddVideoResult { added, duplicate, missingList }

/// 本地学习清单的唯一事实源。
/// 所有页面（播放页、搜索结果、清单页）都读这里的 Rx 状态。
class LearningLibrary {
  LearningLibrary._();

  static final LearningLibrary instance = LearningLibrary._();

  static const String _listsKey = 'learningLists';

  Box<dynamic>? _box;

  final RxList<LearningList> lists = <LearningList>[].obs;

  void attach(Box<dynamic> box) {
    _box = box;

    final stored = box.get(_listsKey);
    if (stored is List) {
      loadFromJson(stored);
    } else {
      loadFromJson(const <dynamic>[]);
      createList('学习清单');
    }
  }

  void loadFromJson(List<dynamic> raw) {
    lists
      ..clear()
      ..addAll(
        raw.whereType<Map>().map(
          (item) => LearningList.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    lists.refresh();
  }

  LearningList? find(String id) {
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  /// 视频所在的清单名，用于搜索结果卡片和播放页按钮回显。
  List<String> listNamesContaining(String bvid) => lists
      .where((list) => list.contains(bvid))
      .map((list) => list.name)
      .toList();

  bool containsAny(String bvid) => lists.any((list) => list.contains(bvid));

  LearningList createList(String name) {
    final list = LearningList(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? '未命名清单' : name.trim(),
    );
    lists.add(list);
    _persist();
    return list;
  }

  /// 订阅刷新结果统一进入这个清单；它只是一个普通清单，用户可自由搬移。
  String ensureFeedList() {
    for (final list in lists) {
      if (list.name == '订阅更新') return list.id;
    }
    return createList('订阅更新').id;
  }

  void renameList(String id, String name) {
    final list = find(id);
    if (list == null) return;
    list.name = name.trim().isEmpty ? list.name : name.trim();
    list.updatedAt = DateTime.now();
    _persist();
  }

  void deleteList(String id) {
    lists.removeWhere((list) => list.id == id);
    _persist();
  }

  AddVideoResult addVideo({
    required String listId,
    required LearningVideo video,
  }) {
    final list = find(listId);
    if (list == null) return AddVideoResult.missingList;
    if (list.contains(video.bvid)) return AddVideoResult.duplicate;

    list.videos.add(video);
    list.updatedAt = DateTime.now();
    _persist();
    return AddVideoResult.added;
  }

  void removeVideo({required String listId, required String bvid}) {
    final list = find(listId);
    if (list == null) return;
    list.videos.removeWhere((item) => item.bvid == bvid);
    list.updatedAt = DateTime.now();
    _persist();
  }

  void moveVideo({
    required String fromListId,
    required String toListId,
    required String bvid,
  }) {
    final from = find(fromListId);
    final to = find(toListId);
    if (from == null || to == null || fromListId == toListId) return;

    final video = from.videos.where((item) => item.bvid == bvid).firstOrNull;
    if (video == null || to.contains(bvid)) return;

    from.videos.remove(video);
    to.videos.add(video);
    from.updatedAt = DateTime.now();
    to.updatedAt = DateTime.now();
    _persist();
  }

  List<Map<String, dynamic>> exportJson() =>
      lists.map((list) => list.toJson()).toList();

  /// 备份只含本地规则/清单结构，不含 cookie、账号或观看历史。
  Map<String, dynamic> toBackup() => {
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'lists': exportJson(),
    'sources': LearningSources.instance.exportJson(),
  };

  /// 导入前先解析，供 UI 做 diff 预览，不改动当前状态。
  List<LearningList> previewBackup(Map<String, dynamic> backup) {
    if (backup['schemaVersion'] != 1) {
      throw const FormatException('不支持的备份版本');
    }
    final rawLists = backup['lists'];
    if (rawLists is! List) {
      throw const FormatException('备份缺少 lists 字段');
    }
    return rawLists
        .whereType<Map>()
        .map((item) => LearningList.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// 与 [previewBackup] 对应，导入前预览订阅规则，不改动当前状态。
  List<LearningSource> previewBackupSources(Map<String, dynamic> backup) {
    if (backup['schemaVersion'] != 1) {
      throw const FormatException('不支持的备份版本');
    }
    final raw = backup['sources'];
    if (raw is! List) return const <LearningSource>[];
    return raw
        .whereType<Map>()
        .map((item) => LearningSource.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  void importBackup(Map<String, dynamic> backup) {
    final preview = previewBackup(backup);
    final sourcesPreview = previewBackupSources(backup);
    loadFromJson(preview.map((list) => list.toJson()).toList());
    LearningSources.instance.loadFromJson(
      sourcesPreview.map((source) => source.toJson()).toList(),
    );
  }

  void _persist() {
    _box?.put(_listsKey, exportJson());
    lists.refresh();
  }
}
