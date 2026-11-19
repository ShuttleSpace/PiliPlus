import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

void showAddToLearningListSheet(
  BuildContext context, {
  required LearningVideo video,
}) {
  final library = LearningLibrary.instance;

  showLearningBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      void closeSheet() => Navigator.of(sheetContext).pop();

      return SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .stretch,
            children: [
              Text('加入待阅清单', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Obx(() {
                if (library.lists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '还没有清单，先新建一个吧',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final list in library.lists)
                      ListTile(
                        dense: true,
                        title: Text(list.name),
                        subtitle: Text('${list.videos.length} 个视频'),
                        trailing: list.contains(video.bvid)
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 18,
                              )
                            : null,
                        onTap: () {
                          final result = library.addVideo(
                            listId: list.id,
                            video: video,
                          );
                          closeSheet();
                          switch (result) {
                            case AddVideoResult.duplicate:
                              SmartDialog.showToast(
                                '已在「${list.name}」中，无需重复添加',
                              );
                            case AddVideoResult.added:
                              SmartDialog.showToast('已加入「${list.name}」');
                            case AddVideoResult.missingList:
                              SmartDialog.showToast('清单不存在');
                          }
                        },
                      ),
                  ],
                );
              }),
              const Divider(height: 1),
              ListTile(
                dense: true,
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('新建清单'),
                onTap: () async {
                  final name = await _askName(sheetContext);
                  if (name == null || name.trim().isEmpty) return;
                  final list = library.createList(name);
                  library.addVideo(listId: list.id, video: video);
                  closeSheet();
                  SmartDialog.showToast('已新建「${list.name}」并加入');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _askName(BuildContext context) => showLearningDialog<String>(
  context: context,
  builder: (context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('新建清单'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '例如：机器学习'),
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
    );
  },
);
