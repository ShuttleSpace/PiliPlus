import 'package:PiliPlus/learning/learning_source.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

/// 本地订阅源与分组的唯一事实源。
class LearningSources {
  LearningSources._();

  static final LearningSources instance = LearningSources._();

  static const String _sourcesKey = 'learningSources';
  static const String _groupsKey = 'learningGroups';
  static const String defaultGroup = '未分组';

  Box<dynamic>? _box;
  final RxList<LearningSource> sources = <LearningSource>[].obs;
  final RxList<String> groups = <String>[].obs;

  int get totalUnread =>
      sources.fold<int>(0, (sum, source) => sum + source.unreadBvids.length);

  Set<String> get unreadBvids => sources.fold<Set<String>>(
    <String>{},
    (set, source) => set..addAll(source.unreadBvids),
  );

  void attach(Box<dynamic> box) {
    _box = box;
    final storedSources = box.get(_sourcesKey);
    loadFromJson(
      storedSources is List ? storedSources : const <dynamic>[],
      groups: box.get(_groupsKey) is List
          ? (box.get(_groupsKey) as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  void loadFromJson(List<dynamic> raw, {List<String>? groups}) {
    sources
      ..clear()
      ..addAll(
        raw.whereType<Map>().map(
          (item) => LearningSource.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    this.groups
      ..clear()
      ..addAll((groups ?? const <String>[]).toSet())
      ..remove(defaultGroup)
      ..insert(0, defaultGroup);
    for (final source in sources) {
      if (!this.groups.contains(source.group)) this.groups.add(source.group);
    }
    sources.refresh();
    this.groups.refresh();
  }

  LearningSource? find(String id) {
    for (final source in sources) {
      if (source.id == id) return source;
    }
    return null;
  }

  LearningSource add({
    required LearningSourceType type,
    required int mid,
    int? refId,
    required String name,
    required String targetListId,
    String? avatar,
    String group = defaultGroup,
  }) {
    final finalGroup = group.trim().isEmpty ? defaultGroup : group.trim();
    final source = LearningSource(
      id: LearningSource.makeId(type: type, mid: mid, refId: refId),
      type: type,
      mid: mid,
      refId: refId,
      name: name.trim().isEmpty ? '未命名订阅' : name.trim(),
      targetListId: targetListId,
      avatar: avatar,
      group: finalGroup,
    );
    sources.add(source);
    if (!groups.contains(finalGroup)) groups.add(finalGroup);
    _persist();
    return source;
  }

  void updateAvatar(String id, String? avatar) {
    final source = find(id);
    if (source == null || avatar == null || avatar.isEmpty) return;
    source.avatar = avatar;
    _persist();
  }

  void remove(String id) {
    sources.removeWhere((source) => source.id == id);
    _persist();
  }

  void addGroup(String name) {
    final value = name.trim();
    if (value.isEmpty || groups.contains(value)) return;
    groups.add(value);
    _persist();
  }

  void renameGroup(String oldName, String newName) {
    final value = newName.trim();
    if (value.isEmpty || value == oldName || oldName == defaultGroup) return;
    for (final source in sources) {
      if (source.group == oldName) source.group = value;
    }
    final index = groups.indexOf(oldName);
    if (index != -1) groups[index] = value;
    _persist();
  }

  void deleteGroup(String name) {
    if (name == defaultGroup) return;
    groups.remove(name);
    for (final source in sources) {
      if (source.group == name) source.group = defaultGroup;
    }
    _persist();
  }

  void moveSource(String sourceId, String group) {
    final source = find(sourceId);
    if (source == null) return;
    source.group = group;
    if (!groups.contains(group)) groups.add(group);
    _persist();
  }

  void recordRefresh({
    required String id,
    required Iterable<String> seenBvids,
    Iterable<String>? newBvids,
    String? error,
  }) {
    final source = find(id);
    if (source == null) return;
    source.seenBvids
      ..clear()
      ..addAll(seenBvids);
    if (newBvids != null) {
      source.unreadBvids
        ..clear()
        ..addAll(newBvids);
    }
    source
      ..lastRefreshAt = DateTime.now()
      ..lastError = error;
    _persist();
  }

  void markSourceRead(String id) {
    find(id)?.unreadBvids.clear();
    _persist();
  }

  DateTime? lastRefreshAtFor(String bvid) {
    DateTime? latest;
    for (final source in sources) {
      final at = source.lastRefreshAt;
      if (at != null && source.seenBvids.contains(bvid)) {
        latest = latest == null || at.isAfter(latest) ? at : latest;
      }
    }
    return latest;
  }

  void markVideoRead(String bvid) {
    for (final source in sources) {
      source.unreadBvids.remove(bvid);
    }
    _persist();
  }

  List<Map<String, dynamic>> exportJson() =>
      sources.map((source) => source.toJson()).toList();

  List<String> exportGroups() =>
      groups.where((g) => g != defaultGroup).toSet().toList();

  void _persist() {
    _box
      ?..put(_sourcesKey, exportJson())
      ..put(_groupsKey, exportGroups());
    sources.refresh();
    groups.refresh();
  }
}
