import 'package:PiliPlus/learning/learning_diff.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final library = LearningLibrary.instance;
  final sources = LearningSources.instance;

  setUp(() {
    library.loadFromJson(const <dynamic>[]);
    sources.loadFromJson(const <dynamic>[]);
  });

  test('首次基线拉取记录全部视频但不打新增 badge', () {
    final listId = library.ensureFeedList();
    final source = sources.add(
      type: LearningSourceType.upArchive,
      mid: 43,
      name: '基线UP',
      targetListId: listId,
    );
    final outcome = applyRefreshItems(
      source: source,
      library: library,
      items: const [
        LearningRefreshItem(bvid: 'BVbase', title: '视频', cover: '', cid: 7),
      ],
    );
    // baseline 只清 newBvids，seenBvids 保留，因此后续刷新不会再打 badge。
    final baselineOutcome = RefreshOutcome(
      outcome.added,
      outcome.seenBvids,
      const <String>[],
    );
    expect(baselineOutcome.seenBvids, contains('BVbase'));
    expect(baselineOutcome.newBvids, isEmpty);
  });

  test('刷新只把新 bvid 写入订阅更新清单，重复刷新不产生重复条目', () {
    final listId = library.ensureFeedList();
    final source = sources.add(
      type: LearningSourceType.upArchive,
      mid: 42,
      name: '测试UP',
      targetListId: listId,
    );
    const items = [
      LearningRefreshItem(
        bvid: 'BV1',
        title: '新视频',
        cover: 'cover',
        cid: 7,
      ),
    ];

    final first = applyRefreshItems(
      source: source,
      library: library,
      items: items,
    );
    expect(first.added, 1);
    expect(library.lists.single.videos, hasLength(1));

    sources.recordRefresh(id: source.id, seenBvids: first.seenBvids);
    final second = applyRefreshItems(
      source: source,
      library: library,
      items: items,
    );
    expect(second.added, 0);
    expect(library.lists.single.videos, hasLength(1));
  });
}
