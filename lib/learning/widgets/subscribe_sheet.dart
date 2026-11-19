import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// 从各页面点击「订阅」时共用：选择本地分组 / 新建分组 / 取消订阅。
Future<void> showSubscribeSheet({
  required BuildContext context,
  required LearningSource source,
}) async {
  final existing = LearningSources.instance.find(source.id);
  if (existing != null) {
    final cancel = await showLearningDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('已订阅'),
        content: Text('是否取消订阅「${existing.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('取消订阅'),
          ),
        ],
      ),
    );
    if (cancel != true) return;
    LearningSources.instance.remove(existing.id);
    SmartDialog.showToast('已取消订阅');
    return;
  }

  final group = await showLearningBottomSheet<String>(
    context: context,
    builder: (sheetContext) => _GroupSheet(source: source),
  );
  if (group == null) return;
  LearningSources.instance.add(
    type: source.type,
    mid: source.mid,
    refId: source.refId,
    name: source.name,
    targetListId: source.targetListId,
    group: group,
    avatar: source.avatar,
  );
  SmartDialog.showToast('已加入「$group」');
}

class _GroupSheet extends StatefulWidget {
  const _GroupSheet({required this.source});

  final LearningSource source;

  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  final _nameCtr = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = LearningSources.instance.groups.toList();
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '订阅「${widget.source.name}」',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _creating ? '输入新分组名' : '选择分组',
                style: TextStyle(fontSize: 13, color: colorScheme.outline),
              ),
              const SizedBox(height: 8),
              if (_creating)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtr,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: '分组名',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submitNewGroup(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submitNewGroup,
                      child: const Text('确定'),
                    ),
                  ],
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == groups.length) {
                        return ListTile(
                          leading: Icon(
                            Icons.create_new_folder_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('新建分组'),
                          onTap: () => setState(() => _creating = true),
                        );
                      }
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(
                          groups[index],
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(context, groups[index]),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitNewGroup() {
    final name = _nameCtr.text.trim();
    if (name.isEmpty) {
      SmartDialog.showToast('请输入分组名');
      return;
    }
    Navigator.pop(context, name);
  }
}

/// 所有订阅按钮统一图标：实心=已订阅，空心=未订阅。
IconData subscribeIcon(bool subscribed) => subscribed
    ? Icons.playlist_add_check_circle
    : Icons.playlist_add_check_circle_outlined;
