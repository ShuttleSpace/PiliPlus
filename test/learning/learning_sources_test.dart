import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sources = LearningSources.instance;

  setUp(() => sources.loadFromJson(const <dynamic>[]));

  test('本地订阅时间取最后一次刷新的 seen 记录', () {
    final now = DateTime.now();
    sources.loadFromJson([
      LearningSource(
        id: 'a',
        type: LearningSourceType.upArchive,
        mid: 1,
        name: 'A',
        targetListId: 'l',
        seenBvids: const ['BV1'],
        lastRefreshAt: now,
      ).toJson(),
    ]);

    expect(
      sources.lastRefreshAtFor('BV1')?.millisecondsSinceEpoch,
      now.millisecondsSinceEpoch,
    );
    expect(sources.lastRefreshAtFor('BV2'), isNull);
  });
}
