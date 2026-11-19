class LearningVideo {
  LearningVideo({
    required this.bvid,
    required this.title,
    this.cover = '',
    this.cid,
    this.sourceId,
    this.author = '',
    this.avatar = '',
    DateTime? addedAt,
    DateTime? publishedAt,
    this.publishedText = '',
  }) : addedAt = addedAt ?? DateTime.now(),
       publishedAt = publishedAt ?? addedAt ?? DateTime.now();

  final String bvid;
  final String title;
  final String cover;
  final int? cid;
  final String? sourceId;
  final String author;
  final String avatar;
  final DateTime addedAt;
  final DateTime publishedAt;
  final String publishedText;

  Map<String, dynamic> toJson() => {
    'bvid': bvid,
    'title': title,
    'cover': cover,
    'cid': cid,
    'sourceId': sourceId,
    'author': author,
    'avatar': avatar,
    'addedAt': addedAt.millisecondsSinceEpoch,
    'publishedAt': publishedAt.millisecondsSinceEpoch,
    'publishedText': publishedText,
  };

  factory LearningVideo.fromJson(Map<String, dynamic> json) => LearningVideo(
    bvid: json['bvid'] as String,
    title: json['title'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    cid: json['cid'] as int?,
    sourceId: json['sourceId'] as String?,
    author: json['author'] as String? ?? '',
    addedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['addedAt'] as int?) ??
          (json['publishedAt'] as int?) ??
          DateTime.now().millisecondsSinceEpoch,
    ),
    publishedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['publishedAt'] as int?) ??
          (json['addedAt'] as int?) ??
          DateTime.now().millisecondsSinceEpoch,
    ),
    publishedText: json['publishedText'] as String? ?? '',
  );
}

class LearningList {
  LearningList({
    required this.id,
    required this.name,
    List<LearningVideo>? videos,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFeed = false,
  }) : videos = videos ?? <LearningVideo>[],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  final List<LearningVideo> videos;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isFeed;

  bool contains(String bvid) => videos.any((item) => item.bvid == bvid);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isFeed': isFeed,
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
    isFeed: (json['isFeed'] as bool?) ?? (json['name'] as String?) == '订阅更新',
  );
}
