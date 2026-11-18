class LearningWatchRecord {
  LearningWatchRecord({
    required this.bvid,
    required this.cid,
    required this.title,
    required this.cover,
    required this.positionMs,
    required this.durationMs,
    required this.lastPlayedAt,
    this.completed = false,
  });

  final String bvid;
  final int cid;
  final String title;
  final String cover;
  final int positionMs;
  final int durationMs;
  final DateTime lastPlayedAt;
  final bool completed;

  String get key => '$bvid:$cid';

  Map<String, dynamic> toJson() => {
    'bvid': bvid,
    'cid': cid,
    'title': title,
    'cover': cover,
    'positionMs': positionMs,
    'durationMs': durationMs,
    'lastPlayedAt': lastPlayedAt.millisecondsSinceEpoch,
    'completed': completed,
  };

  factory LearningWatchRecord.fromJson(Map<String, dynamic> json) =>
      LearningWatchRecord(
        bvid: json['bvid'] as String,
        cid: json['cid'] as int,
        title: json['title'] as String? ?? '',
        cover: json['cover'] as String? ?? '',
        positionMs: json['positionMs'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 0,
        lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['lastPlayedAt'] as int?) ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        completed: json['completed'] as bool? ?? false,
      );
}
