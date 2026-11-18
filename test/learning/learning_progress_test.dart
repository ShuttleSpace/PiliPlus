import 'package:PiliPlus/learning/learning_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final progress = LearningProgress.instance;

  setUp(() => progress.loadFromJson(const <dynamic>[]));

  test('进度按 bvid+cid 记录并恢复', () {
    progress.record(
      bvid: 'BV1',
      cid: 123,
      title: '第一课',
      cover: '',
      positionMs: 120000,
      durationMs: 600000,
    );

    final record = progress.get(bvid: 'BV1', cid: 123);
    expect(record, isNotNull);
    expect(record!.positionMs, 120000);
    expect(record.completed, isFalse);

    progress.record(
      bvid: 'BV1',
      cid: 123,
      title: '第一课',
      cover: '',
      positionMs: 600000,
      durationMs: 600000,
    );
    expect(progress.records, hasLength(1));
    expect(progress.get(bvid: 'BV1', cid: 123)?.completed, isTrue);
  });

  test('同一视频不同分P分别记录，统计与备份可还原', () {
    progress
      ..record(
        bvid: 'BV2',
        cid: 1,
        title: 'P1',
        cover: '',
        positionMs: 100,
        durationMs: 200,
      )
      ..record(
        bvid: 'BV2',
        cid: 2,
        title: 'P2',
        cover: '',
        positionMs: 300,
        durationMs: 300,
      );

    expect(progress.records, hasLength(2));
    final stats = progress.stats();
    expect(stats['total'], 2);
    expect(stats['completed'], 1);
    expect(stats['completionRate'], 0.5);

    final backup = progress.exportJson();
    progress
      ..loadFromJson(const <dynamic>[])
      ..loadFromJson(backup);
    expect(progress.get(bvid: 'BV2', cid: 2)?.completed, isTrue);
    expect(progress.history().first.cid, isNotNull);
  });
}
