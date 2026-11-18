import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_refresh.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

final RxSet<String> _refreshingSources = <String>{}.obs;

class LearningSourcesPage extends StatelessWidget {
  const LearningSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的订阅')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: const LearningSourcesView(embedded: false),
    );
  }
}

class LearningSourcesView extends StatelessWidget {
  const LearningSourcesView({
    super.key,
    this.embedded = false,
    this.scrollController,
  });

  final bool embedded;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final sources = LearningSources.instance.sources;
    return Obx(() {
      if (sources.isEmpty) {
        return Center(
          child: Text(embedded ? '还没有订阅，点 + 添加' : '还没有订阅，点右下角添加'),
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
                    '我的订阅',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '添加订阅',
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddDialog(context),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: sources.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final source = sources[index];
                return Obx(() {
                  final refreshing = _refreshingSources.contains(source.id);
                  return ListTile(
                    title: Text(source.name),
                    subtitle: Text(
                      '${source.type.label}${source.lastError != null ? ' · 上次失败' : ''}'
                      '${source.lastRefreshAt == null ? '' : ' · ${source.lastRefreshAt.toString().substring(0, 16)}'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: '手动刷新',
                          icon: const Icon(Icons.refresh),
                          onPressed: refreshing
                              ? null
                              : () => _refresh(context, source),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'delete') {
                              LearningSources.instance.remove(source.id);
                              SmartDialog.showToast('已删除订阅「${source.name}」');
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                        ),
                      ],
                    ),
                  );
                });
              },
            ),
          ),
        ],
      );
    });
  }
}

Future<void> _refresh(BuildContext context, LearningSource source) async {
  _refreshingSources.add(source.id);
  try {
    final outcome = await LearningRefresh.refresh(
      source: source,
      library: LearningLibrary.instance,
    );
    LearningSources.instance.recordRefresh(
      id: source.id,
      seenBvids: outcome.seenBvids,
      error: outcome.error,
    );
    if (outcome.error != null) {
      SmartDialog.showToast('刷新失败：${outcome.error}');
    } else if (outcome.added > 0) {
      SmartDialog.showToast('新增 ${outcome.added} 个视频到「订阅更新」');
    } else {
      SmartDialog.showToast('暂无更新');
    }
  } catch (e) {
    LearningSources.instance.recordRefresh(
      id: source.id,
      seenBvids: source.seenBvids,
      error: e.toString(),
    );
    SmartDialog.showToast('刷新失败：$e');
  } finally {
    _refreshingSources.remove(source.id);
  }
}

Future<void> _showAddDialog(BuildContext context) async {
  var type = LearningSourceType.upArchive;
  final midCtr = TextEditingController();
  final refCtr = TextEditingController();
  final nameCtr = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('添加订阅'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<LearningSourceType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: '来源类型'),
                items: [
                  for (final item in LearningSourceType.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => type = value);
                },
              ),
              TextField(
                controller: midCtr,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'UP 主 mid'),
              ),
              if (type != LearningSourceType.upArchive)
                TextField(
                  controller: refCtr,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '合集 / 系列 ID',
                  ),
                ),
              TextField(
                controller: nameCtr,
                decoration: const InputDecoration(labelText: '名称'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('添加'),
          ),
        ],
      ),
    ),
  );
  if (result != true || !context.mounted) return;

  final mid = int.tryParse(midCtr.text.trim());
  if (mid == null) {
    SmartDialog.showToast('mid 必须是数字');
    return;
  }
  int? refId;
  if (type != LearningSourceType.upArchive) {
    refId = int.tryParse(refCtr.text.trim());
    if (refId == null) {
      SmartDialog.showToast('请填写合集 / 系列 ID');
      return;
    }
  }

  final targetListId = LearningLibrary.instance.ensureFeedList();
  LearningSources.instance.add(
    type: type,
    mid: mid,
    refId: refId,
    name: nameCtr.text.trim().isEmpty ? type.label : nameCtr.text.trim(),
    targetListId: targetListId,
  );
  SmartDialog.showToast('已添加订阅，点刷新拉取新视频');
}
