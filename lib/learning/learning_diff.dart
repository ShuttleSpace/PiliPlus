import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_source.dart';

class RefreshOutcome {
  const RefreshOutcome(this.added, this.seenBvids, this.newBvids, [this.error]);

  final int added;
  final List<String> seenBvids;
  final List<String> newBvids;
  final String? error;
}

class LearningRefreshItem {
  const LearningRefreshItem({
    required this.bvid,
    required this.title,
    required this.cover,
    required this.cid,
    this.author = '',
  });

  final String bvid;
  final String title;
  final String cover;
  final int? cid;
  final String author;
}

/// 纯本地 diff，无网络依赖：只把新 bvid 写入订阅更新清单。
RefreshOutcome applyRefreshItems({
  required LearningSource source,
  required LearningLibrary library,
  required List<LearningRefreshItem> items,
}) {
  final known = source.seenBvids.toSet();
  final seen = <String>{...known};
  final addedBvids = <String>[];

  for (final item in items) {
    if (item.bvid.isEmpty) continue;
    seen.add(item.bvid);
    if (known.contains(item.bvid)) continue;

    final result = library.addVideo(
      listId: source.targetListId,
      video: LearningVideo(
        bvid: item.bvid,
        title: item.title,
        cover: item.cover,
        cid: item.cid,
        sourceId: source.id,
        author: item.author,
      ),
    );
    if (result == AddVideoResult.added) addedBvids.add(item.bvid);
  }

  return RefreshOutcome(addedBvids.length, seen.toList(), addedBvids);
}
