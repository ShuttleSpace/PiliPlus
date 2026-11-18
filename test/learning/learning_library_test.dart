import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final library = LearningLibrary.instance;

  setUp(() => library.loadFromJson(const <dynamic>[]));

  test('同一清单内重复添加被拒绝且不产生第二条', () {
    final list = library.createList('机器学习');
    final video = LearningVideo(bvid: 'BV1', title: '第一课');

    expect(
      library.addVideo(listId: list.id, video: video),
      AddVideoResult.added,
    );
    expect(
      library.addVideo(listId: list.id, video: video),
      AddVideoResult.duplicate,
    );
    expect(list.videos, hasLength(1));
    expect(library.listNamesContaining('BV1'), ['机器学习']);
  });

  test('同一视频可在不同清单各存一份', () {
    final first = library.createList('工作');
    final second = library.createList('兴趣');
    final video = LearningVideo(bvid: 'BV2', title: '第二课');

    expect(
      library.addVideo(listId: first.id, video: video),
      AddVideoResult.added,
    );
    expect(
      library.addVideo(listId: second.id, video: video),
      AddVideoResult.added,
    );
    expect(library.listNamesContaining('BV2'), ['工作', '兴趣']);
  });

  test('清单与视频可增删改查且导出可还原', () {
    final list = library.createList('初始');
    final video = LearningVideo(bvid: 'BV3', title: '第三课', cid: 123);

    library
      ..addVideo(listId: list.id, video: video)
      ..renameList(list.id, ' renamed ');
    expect(library.find(list.id)?.name, 'renamed');

    final exported = library.exportJson();
    library.loadFromJson(exported);

    expect(library.lists, hasLength(1));
    expect(library.lists.first.name, 'renamed');
    expect(library.lists.first.videos.first.bvid, 'BV3');
    expect(library.lists.first.videos.first.cid, 123);

    library.removeVideo(listId: list.id, bvid: 'BV3');
    expect(library.lists.first.videos, isEmpty);
    library.deleteList(list.id);
    expect(library.lists, isEmpty);
  });

  test('备份包含版本并能原样还原，且不含账号凭证字段', () {
    final list = library.createList('迁移测试');
    library.addVideo(
      listId: list.id,
      video: LearningVideo(bvid: 'BV4', title: '第四课', cid: 9),
    );

    final backup = library.toBackup();
    expect(backup['schemaVersion'], 1);
    expect(backup.containsKey('cookie'), isFalse);
    expect(backup.containsKey('token'), isFalse);

    library.loadFromJson(const <dynamic>[]);
    expect(library.lists, isEmpty);

    library.importBackup(backup);
    expect(library.lists, hasLength(1));
    expect(library.lists.first.name, '迁移测试');
    expect(library.lists.first.videos.first.cid, 9);
  });

  test('导入前预览不改动当前状态，错误版本被拒绝', () {
    final current = library.createList('当前');
    final backup = {
      'schemaVersion': 1,
      'lists': [
        LearningList(
          id: 'imported',
          name: '导入的清单',
          videos: [LearningVideo(bvid: 'BV5', title: '第五课')],
        ).toJson(),
      ],
    };

    final preview = library.previewBackup(backup);
    expect(preview.single.name, '导入的清单');
    expect(library.lists.single.id, current.id);

    expect(
      () => library.previewBackup({'schemaVersion': 99, 'lists': const []}),
      throwsFormatException,
    );
  });
}
