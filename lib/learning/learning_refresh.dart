import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/learning/learning_diff.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/models/common/member/archive_order_type_app.dart';
import 'package:PiliPlus/models/common/member/archive_sort_type_app.dart';
import 'package:PiliPlus/models/common/member/contribute_type.dart';

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
      Success(:final response) => applyRefreshItems(
        source: source,
        library: library,
        items:
            response.item
                ?.map(
                  (item) => LearningRefreshItem(
                    bvid: item.bvid ?? '',
                    title: item.title,
                    cover: item.cover ?? '',
                    cid: item.cid,
                  ),
                )
                .toList() ??
            const [],
      ),
      Error(:final errMsg) => RefreshOutcome(
        0,
        source.seenBvids,
        errMsg ?? '刷新失败',
      ),
      Loading() => RefreshOutcome(0, source.seenBvids, '刷新中'),
    };
  }
}
