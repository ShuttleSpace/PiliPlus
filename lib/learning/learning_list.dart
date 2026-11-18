class LearningVideo {
  LearningVideo({
    required this.bvid,
    required this.title,
    this.cover = '',
    this.cid,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String bvid;
  final String title;
  final String cover;
  final int? cid;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'bvid': bvid,
    'title': title,
    'cover': cover,
    'cid': cid,
    'addedAt': addedAt.millisecondsSinceEpoch,
  };

  factory LearningVideo.fromJson(Map<String, dynamic> json) => LearningVideo(
    bvid: json['bvid'] as String,
    title: json['title'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    cid: json['cid'] as int?,
    addedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['addedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );
}

class LearningList {
  LearningList({
    required this.id,
    required this.name,
    List<LearningVideo>? videos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : videos = videos ?? <LearningVideo>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  final List<LearningVideo> videos;
  final DateTime createdAt;
  DateTime updatedAt;

  bool contains(String bvid) => videos.any((item) => item.bvid == bvid);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'videos': videos.map((item) => item.toJson()).toList(),
  };

  factory LearningList.fromJson(Map<String, dynamic> json) => LearningList(
    id: json['id'] as String,
    name: json['name'] as String? ?? '未命名清单',
    videos:
        (json['videos'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => LearningVideo.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList() ??
        <LearningVideo>[],
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );
}
