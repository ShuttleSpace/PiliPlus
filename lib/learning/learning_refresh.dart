import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/learning/learning_diff.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/models/common/member/archive_order_type_app.dart';
import 'package:PiliPlus/models/common/member/contribute_type.dart';
import 'package:collection/collection.dart';

/// 只读取白名单接口：UP 投稿列表 / UP 自制合集列表。
/// diff 与写入清单全部在本地完成。
class LearningRefresh {
  LearningRefresh._();

  /// 与官方 space/archive/cursor 接口一致：视频用 aid 游标，合集用 next 游标。
  static const int maxPages = 50;

  static ContributeType _contributeType(LearningSourceType type) =>
      switch (type) {
        LearningSourceType.upArchive => ContributeType.video,
        LearningSourceType.upSeries => ContributeType.series,
        LearningSourceType.upSeason => ContributeType.season,
        LearningSourceType.upLive => throw UnsupportedError('直播间不从投稿列表刷新'),
      };

  /// [baseline] 为 true 时把拉取到的全部视频作为已知项，不打新增 badge。
  static Future<RefreshOutcome> refresh({
    required LearningSource source,
    required LearningLibrary library,
    bool baseline = false,
  }) async {
    if (source.type == LearningSourceType.upLive) {
      return const RefreshOutcome(0, <String>[], <String>[]);
    }
    final isArchive = source.type == LearningSourceType.upArchive;
    final items = <LearningRefreshItem>[];
    String? aid;
    int? next;
    String? error;
    String? avatar = source.avatar;
    if (avatar == null) {
      final info = await MemberHttp.memberInfo(mid: source.mid);
      avatar = switch (info) {
        Success(:final response) => response.face,
        _ => null,
      };
      if (avatar != null) {
        LearningSources.instance.updateAvatar(source.id, avatar);
      }
    }

    for (var page = 0; page < maxPages; page++) {
      final result = await MemberHttp.spaceArchive(
        type: _contributeType(source.type),
        mid: source.mid,
        aid: isArchive ? aid : null,
        seriesId: source.type == LearningSourceType.upSeries
            ? source.refId
            : null,
        seasonId: source.type == LearningSourceType.upSeason
            ? source.refId
            : null,
        order: isArchive ? ArchiveOrderTypeApp.pubdate : null,
        sort: null,
        next: isArchive ? null : next,
      );
      switch (result) {
        case Success(:final response):
          final pageItems = response.item ?? const [];
          items.addAll(
            pageItems
                .map(
                  (item) => LearningRefreshItem(
                    bvid: item.bvid ?? '',
                    title: item.title,
                    cover: item.cover ?? '',
                    cid: item.cid,
                    author: item.owner.name ?? '',
                    avatar: avatar ?? '',
                    publishedAt: _parseEpoch(
                      item.pubdate ?? item.season?.mtime,
                    ),
                  ),
                )
                .where((item) => item.bvid.isNotEmpty),
          );
          final hasNext = response.hasNext != false;
          if (isArchive) {
            final lastAid = pageItems.lastOrNull?.param;
            if (!hasNext || lastAid == null || lastAid == aid) {
              return _finish(
                source: source,
                library: library,
                items: items,
                baseline: baseline,
              );
            }
            aid = lastAid;
          } else {
            final nextPage = response.next;
            if (!hasNext ||
                nextPage == null ||
                nextPage == 0 ||
                nextPage == next) {
              return _finish(
                source: source,
                library: library,
                items: items,
                baseline: baseline,
              );
            }
            next = nextPage;
          }
        case Error(:final errMsg):
          error = errMsg ?? '刷新失败';
        case Loading():
          error = '刷新中';
      }
      if (error != null) break;
    }

    // 某页失败也保留已拉到的视频，不整批丢弃。
    return _finish(
      source: source,
      library: library,
      items: items,
      baseline: baseline,
    );
  }

  /// 接口里 pubdate 是秒，mtime 有时是秒有时是毫秒，统一转成 DateTime。
  static DateTime? _parseEpoch(dynamic value) {
    final number = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (number == null) return null;
    final ms = number > 100000000000 ? number : number * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static RefreshOutcome _finish({
    required LearningSource source,
    required LearningLibrary library,
    required List<LearningRefreshItem> items,
    required bool baseline,
  }) {
    final outcome = applyRefreshItems(
      source: source,
      library: library,
      items: items,
    );
    if (!baseline) return outcome;
    return RefreshOutcome(outcome.added, outcome.seenBvids, const <String>[]);
  }
}
