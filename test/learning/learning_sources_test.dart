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

  test('订阅源 CRUD 与刷新状态本地持久化', () {
    final listId = library.ensureFeedList();
    final source = sources.add(
      type: LearningSourceType.upArchive,
      mid: 123,
      name: 'UP A',
      targetListId: listId,
    );

    expect(source.id, 'up:123');
    expect(library.lists.single.name, '订阅更新');
    expect(sources.sources, hasLength(1));

    sources.recordRefresh(
      id: source.id,
      seenBvids: const ['BV1', 'BV2'],
    );
    expect(sources.find(source.id)?.seenBvids, ['BV1', 'BV2']);
    expect(sources.find(source.id)?.lastRefreshAt, isNotNull);

    sources.remove(source.id);
    expect(sources.sources, isEmpty);
  });

  test('合集订阅 id 含 mid 与 seriesId，可被备份还原', () {
    final listId = library.ensureFeedList();
    sources.add(
      type: LearningSourceType.upSeries,
      mid: 456,
      refId: 789,
      name: '课程合集',
      targetListId: listId,
    );

    final backup = library.toBackup();
    expect(backup['sources'], isA<List>());
    expect((backup['sources'] as List).single['id'], 'series:456:789');

    sources.loadFromJson(const <dynamic>[]);
    library
      ..loadFromJson(const <dynamic>[])
      ..importBackup(backup);

    expect(sources.sources.single.name, '课程合集');
    expect(sources.sources.single.targetListId, isNotEmpty);
    expect(library.lists, hasLength(1));
  });
}
