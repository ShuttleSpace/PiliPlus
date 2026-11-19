import 'dart:convert';

import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:PiliPlus/common/widgets/dialog/export_import.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/widgets/learning_video_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class LearningListsPage extends StatelessWidget {
  const LearningListsPage({super.key});

  @override
  Widget build(BuildContext context) => LearningLocalizations(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('我的清单'),
        actions: [
          IconButton(
            tooltip: '备份/迁移',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => showBackupDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => createList(context),
        child: const Icon(Icons.add),
      ),
      body: const LearningListsView(),
    ),
  );
}

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
      final lists = library.lists.where((l) => !l.isFeed).toList();
      if (lists.isEmpty) {
        return const Center(child: Text('还没有清单'));
      }
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: lists.length + (embedded ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          if (embedded && index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
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
                    onPressed: () => createList(context),
                  ),
                ],
              ),
            );
          }
          final list = lists[index - (embedded ? 1 : 0)];
          return _ListCard(list: list);
        },
      );
    });
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list});

  final LearningList list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videos = list.videos;
    return Stack(
      children: [
        InkWell(
          onTap: () => Get.to(() => LearningListDetailPage(listId: list.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 56, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      list.name.isEmpty ? '未命名清单' : list.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${videos.length} 个视频',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (videos.isEmpty)
                  Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '空清单',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      for (final video in videos.take(3))
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 58,
                                child: video.cover.isEmpty
                                    ? Container(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                      )
                                    : Image.network(
                                        video.cover,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 4,
          child: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              final action = await showLearningBottomSheet<String>(
                context: context,
                builder: (sheetContext) => Material(
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('重命名'),
                          onTap: () => Navigator.pop(sheetContext, 'rename'),
                        ),
                        ListTile(
                          title: const Text('删除'),
                          onTap: () => Navigator.pop(sheetContext, 'delete'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (!context.mounted) return;
              final library = LearningLibrary.instance;
              if (action == 'rename') {
                final name = await askName(
                  context,
                  title: '重命名',
                  initial: list.name,
                );
                if (name != null) library.renameList(list.id, name);
              } else if (action == 'delete') {
                library.deleteList(list.id);
                SmartDialog.showToast('已删除');
              }
            },
          ),
        ),
      ],
    );
  }
}

class LearningListDetailPage extends StatelessWidget {
  const LearningListDetailPage({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    return LearningLocalizations(
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(library.find(listId)?.name ?? '清单已删除')),
        ),
        body: Obx(() {
          final list = library.find(listId);
          if (list == null) return const Center(child: Text('清单不存在'));
          if (list.videos.isEmpty) {
            return const Center(child: Text('清单为空：在播放页点「清单」加入视频'));
          }
          return ListView.separated(
            itemCount: list.videos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final video = list.videos[index];
              return Stack(
                children: [
                  LearningVideoCard(video: video),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: IconButton(
                      tooltip: '移出',
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () {
                        library.removeVideo(listId: listId, bvid: video.bvid);
                        SmartDialog.showToast('已移出清单');
                      },
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

Future<void> createList(BuildContext context) async {
  final name = await askName(context, title: '新建清单');
  if (name == null || name.trim().isEmpty) return;
  LearningLibrary.instance.createList(name);
  SmartDialog.showToast('已新建');
}

void showBackupDialog(BuildContext context) {
  final library = LearningLibrary.instance;
  showImportExportDialog<Map<String, dynamic>>(
    context,
    title: '清单与订阅',
    onExport: () => jsonEncode(library.toBackup()),
    localFileName: () => 'learning_lists',
    onImport: (json) async {
      final preview = library.previewBackup(json);
      final sourceCount = library.previewBackupSources(json).length;
      final confirmed = await showLearningDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认导入？'),
          content: Text(
            '备份含 ${preview.length} 个清单、$sourceCount 条订阅规则，将覆盖当前数据。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('覆盖导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      library.importBackup(json);
      SmartDialog.showToast('已导入');
    },
  );
}

Future<String?> askName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showLearningDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
