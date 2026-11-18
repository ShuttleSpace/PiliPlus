enum LearningSourceType { upArchive, upSeries, upSeason }

extension LearningSourceTypeExt on LearningSourceType {
  String get label => switch (this) {
    LearningSourceType.upArchive => 'UP 投稿',
    LearningSourceType.upSeries => '视频合集',
    LearningSourceType.upSeason => '系列合集',
  };

  String get idPrefix => switch (this) {
    LearningSourceType.upArchive => 'up',
    LearningSourceType.upSeries => 'series',
    LearningSourceType.upSeason => 'season',
  };
}

class LearningSource {
  LearningSource({
    required this.id,
    required this.type,
    required this.mid,
    required this.name,
    required this.targetListId,
    this.refId,
    List<String>? seenBvids,
    this.lastRefreshAt,
    this.lastError,
  }) : seenBvids = seenBvids ?? <String>[];

  final String id;
  final LearningSourceType type;
  final int mid;
  final int? refId;
  final String name;
  final String targetListId;
  final List<String> seenBvids;
  DateTime? lastRefreshAt;
  String? lastError;

  static String makeId({
    required LearningSourceType type,
    required int mid,
    int? refId,
  }) {
    final suffix = type == LearningSourceType.upArchive ? '' : ':$refId';
    return '${type.idPrefix}:$mid$suffix';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'mid': mid,
    'refId': refId,
    'name': name,
    'targetListId': targetListId,
    'seenBvids': seenBvids,
    'lastRefreshAt': lastRefreshAt?.millisecondsSinceEpoch,
    'lastError': lastError,
  };

  factory LearningSource.fromJson(Map<String, dynamic> json) => LearningSource(
    id: json['id'] as String,
    type: LearningSourceType.values.byName(json['type'] as String),
    mid: json['mid'] as int,
    refId: json['refId'] as int?,
    name: json['name'] as String? ?? '未命名订阅',
    targetListId: json['targetListId'] as String,
    seenBvids:
        (json['seenBvids'] as List?)?.map((item) => item.toString()).toList() ??
        <String>[],
    lastRefreshAt: json['lastRefreshAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['lastRefreshAt'] as int),
    lastError: json['lastError'] as String?,
  );
}
