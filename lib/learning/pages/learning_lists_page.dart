import 'dart:convert';

import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class LearningListsPage extends StatelessWidget {
  const LearningListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的学习清单'),
        actions: [
          IconButton(
            tooltip: '备份/迁移',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => _showBackupDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createList(context),
        child: const Icon(Icons.add),
      ),
      body: const LearningListsView(),
    );
  }
}

/// 可嵌入首页 tab 的清单视图；[embedded] 时自带一个「+」入口。
class LearningListsView extends StatelessWidget {
  const LearningListsView({
    super.key,
    this.embedded = false,
    this.scrollController,
  });

  final bool embedded;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    return Obx(() {
      if (library.lists.isEmpty) {
        return Center(
          child: Text(embedded ? '还没有清单，点 + 新建' : '还没有清单，点右下角新建'),
        );
      }
      return Column(
        crossAxisAlignment: .stretch,
        children: [
          if (embedded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '我的学习清单',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '新建清单',
                    icon: const Icon(Icons.add),
                    onPressed: () => _createList(context),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: library.lists.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final list = library.lists[index];
                return ListTile(
                  title: Text(list.name),
                  subtitle: Text('${list.videos.length} 个视频'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      switch (action) {
                        case 'rename':
                          final name = await _askName(
                            context,
                            title: '重命名',
                            initial: list.name,
                          );
                          if (name != null) library.renameList(list.id, name);
                        case 'delete':
                          library.deleteList(list.id);
                          SmartDialog.showToast('已删除「${list.name}」');
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('重命名')),
                      PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                  onTap: () =>
                      Get.to(() => LearningListDetailPage(listId: list.id)),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

Future<void> _createList(BuildContext context) async {
  final name = await _askName(context, title: '新建清单');
  if (name == null || name.trim().isEmpty) return;
  LearningLibrary.instance.createList(name);
  SmartDialog.showToast('已新建「${name.trim()}」');
}

void _showBackupDialog(BuildContext context) {
  final library = LearningLibrary.instance;
  showImportExportDialog<Map<String, dynamic>>(
    context,
    title: '学习清单',
    onExport: () => jsonEncode(library.toBackup()),
    localFileName: () => 'learning_lists',
    onImport: (json) async {
      final preview = library.previewBackup(json);
      final videoCount = preview.fold<int>(
        0,
        (sum, list) => sum + list.videos.length,
      );
      final sourceCount = library.previewBackupSources(json).length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入？'),
          content: Text(
            '将用备份中的 ${preview.length} 个清单（共 $videoCount 个视频）'
            '与 $sourceCount 条订阅规则，覆盖当前的 '
            '${library.lists.length} 个清单 / '
            '${LearningSources.instance.sources.length} 条订阅。\n'
            '备份不含账号凭证。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('覆盖导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      library.importBackup(json);
      SmartDialog.showToast('已导入 ${preview.length} 个清单');
    },
  );
}

class LearningListDetailPage extends StatelessWidget {
  const LearningListDetailPage({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(library.find(listId)?.name ?? '清单已删除')),
      ),
      body: Obx(() {
        final list = library.find(listId);
        if (list == null) return const Center(child: Text('清单不存在'));
        if (list.videos.isEmpty) {
          return const Center(
            child: Text('清单为空：在搜索结果中播放视频后，点「清单」加入'),
          );
        }
        return ListView.separated(
          itemCount: list.videos.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final video = list.videos[index];
            return ListTile(
              title: Text(video.title, maxLines: 2),
              subtitle: Text(video.bvid),
              trailing: IconButton(
                tooltip: '移除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  library.removeVideo(listId: listId, bvid: video.bvid);
                  SmartDialog.showToast('已移出清单');
                },
              ),
              onTap: () {
                if (video.cid == null) {
                  SmartDialog.showToast('缺少分 P 信息，请重新从视频页加入');
                  return;
                }
                PageUtils.toVideoPage(
                  bvid: video.bvid,
                  cid: video.cid!,
                  cover: video.cover,
                  title: video.title,
                );
              },
            );
          },
        );
      }),
    );
  }
}

Future<String?> _askName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '清单名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
