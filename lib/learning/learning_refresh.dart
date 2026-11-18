import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/models/common/member/archive_order_type_app.dart';
import 'package:PiliPlus/models/common/member/archive_sort_type_app.dart';
import 'package:PiliPlus/models/common/member/contribute_type.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';

class RefreshOutcome {
  const RefreshOutcome(this.added, this.seenBvids, [this.error]);

  final int added;
  final List<String> seenBvids;
  final String? error;
}

/// 只读取白名单接口：UP 投稿列表 / UP 自制合集列表。
/// diff 与写入清单全部在本地完成。
class LearningRefresh {
  LearningRefresh._();

  static ContributeType _contributeType(LearningSourceType type) =>
      switch (type) {
        LearningSourceType.upArchive => ContributeType.video,
        LearningSourceType.upSeries => ContributeType.series,
        LearningSourceType.upSeason => ContributeType.season,
      };

  static Future<RefreshOutcome> refresh({
    required LearningSource source,
    required LearningLibrary library,
  }) async {
    final result = await MemberHttp.spaceArchive(
      type: _contributeType(source.type),
      mid: source.mid,
      seriesId: source.type == LearningSourceType.upSeries
          ? source.refId
          : null,
      seasonId: source.type == LearningSourceType.upSeason
          ? source.refId
          : null,
      order: source.type == LearningSourceType.upArchive
          ? ArchiveOrderTypeApp.pubdate
          : null,
      sort: source.type == LearningSourceType.upArchive
          ? ArchiveSortTypeApp.desc
          : null,
      pn: 1,
    );

    return switch (result) {
      Success(:final response) => _apply(
        source: source,
        library: library,
        items: response.item ?? const [],
      ),
      Error(:final errMsg) => RefreshOutcome(
        0,
        source.seenBvids,
        errMsg ?? '刷新失败',
      ),
      Loading() => RefreshOutcome(0, source.seenBvids, '刷新中'),
    };
  }

  static RefreshOutcome _apply({
    required LearningSource source,
    required LearningLibrary library,
    required List<SpaceArchiveItem> items,
  }) {
    final known = source.seenBvids.toSet();
    final seen = <String>{...known};
    var added = 0;

    for (final item in items) {
      final bvid = item.bvid;
      if (bvid == null || bvid.isEmpty) continue;
      seen.add(bvid);
      if (known.contains(bvid)) continue;

      final result = library.addVideo(
        listId: source.targetListId,
        video: LearningVideo(
          bvid: bvid,
          title: item.title,
          cover: item.cover ?? '',
          cid: item.cid,
        ),
      );
      if (result == AddVideoResult.added) added++;
    }

    return RefreshOutcome(added, seen.toList());
  }
}
