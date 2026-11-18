import 'package:PiliPlus/learning/learning_source.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

class LearningSources {
  LearningSources._();

  static final LearningSources instance = LearningSources._();

  static const String _sourcesKey = 'learningSources';

  Box<dynamic>? _box;
  final RxList<LearningSource> sources = <LearningSource>[].obs;

  void attach(Box<dynamic> box) {
    _box = box;
    final stored = box.get(_sourcesKey);
    loadFromJson(stored is List ? stored : const <dynamic>[]);
  }

  void loadFromJson(List<dynamic> raw) {
    sources
      ..clear()
      ..addAll(
        raw.whereType<Map>().map(
          (item) => LearningSource.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    sources.refresh();
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
  }) {
    final source = LearningSource(
      id: LearningSource.makeId(type: type, mid: mid, refId: refId),
      type: type,
      mid: mid,
      refId: refId,
      name: name.trim().isEmpty ? '未命名订阅' : name.trim(),
      targetListId: targetListId,
    );
    sources.add(source);
    _persist();
    return source;
  }

  void remove(String id) {
    sources.removeWhere((source) => source.id == id);
    _persist();
  }

  void recordRefresh({
    required String id,
    required Iterable<String> seenBvids,
    String? error,
  }) {
    final source = find(id);
    if (source == null) return;
    source.seenBvids
      ..clear()
      ..addAll(seenBvids);
    source
      ..lastRefreshAt = DateTime.now()
      ..lastError = error;
    _persist();
  }

  List<Map<String, dynamic>> exportJson() =>
      sources.map((source) => source.toJson()).toList();

  void _persist() {
    _box?.put(_sourcesKey, exportJson());
    sources.refresh();
  }
}
