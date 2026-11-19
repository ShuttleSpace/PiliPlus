import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_refresh.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/learning_video_card.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class LearningSourcesPage extends StatelessWidget {
  const LearningSourcesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的订阅')),
    body: const LearningSourcesView(),
  );
}

/// 首页「订阅」tab：顶部横向分组 tab + 下拉刷新。
class LearningSourcesView extends StatefulWidget {
  const LearningSourcesView({
    super.key,
    this.embedded = false,
    this.scrollController,
  });

  final bool embedded;
  final ScrollController? scrollController;

  @override
  State<LearningSourcesView> createState() => _LearningSourcesViewState();
}

class _LearningSourcesViewState extends State<LearningSourcesView> {
  final _pageController = PageController();
  int _index = 0;
  bool _refreshing = false;

  List<String> get _tabs => [
    '更新',
    '全部',
    ...LearningSources.instance.groups.where((g) => g != '未分组'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    final tabs = _tabs;
    final group = _index >= 2 ? tabs[_index] : null;
    final targets = group == null
        ? LearningSources.instance.sources.toList()
        : LearningSources.instance.sources
              .where((source) => source.group == group)
              .toList();
    var added = 0;
    for (final source in targets) {
      final outcome = await LearningRefresh.refresh(
        source: source,
        library: LearningLibrary.instance,
      );
      LearningSources.instance.recordRefresh(
        id: source.id,
        seenBvids: outcome.seenBvids,
        newBvids: outcome.newBvids,
        error: outcome.error,
      );
      added += outcome.added;
    }
    _refreshing = false;
    if (added > 0) {
      SmartDialog.showToast('新增 $added 个视频');
    } else if (targets.isEmpty) {
      SmartDialog.showToast('还没有订阅源');
    } else {
      SmartDialog.showToast('暂无更新');
    }
  }

  void _openSource(LearningSource source) {
    LearningSources.instance.markSourceRead(source.id);
    Get.toNamed('/member?mid=${source.mid}');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabs = _tabs;
      if (_index >= tabs.length) {
        _index = tabs.length - 1;
      }
      return Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: tabs.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                if (index == tabs.length) {
                  return Align(
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showGroupDialog,
                    ),
                  );
                }
                final unread = index == 0
                    ? LearningSources.instance.totalUnread
                    : 0;
                return Align(
                  child: InkWell(
                    onTap: () {
                      _index = index;
                      _pageController.jumpToPage(index);
                    },
                    child: Row(
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: index == _index
                                ? FontWeight.bold
                                : null,
                            color: index == _index
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '$unread',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: ValueKey(tabs.length),
              controller: _pageController,
              onPageChanged: (index) => setState(() => _index = index),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FeedView(onlyUnread: true, onRefresh: _refresh);
                }
                if (index == 1) {
                  return _FeedView(onlyUnread: false, onRefresh: _refresh);
                }
                return _GroupSourcesView(
                  group: tabs[index],
                  onOpen: _openSource,
                  onAdd: _showAddSourceDialog,
                  onRefresh: _refresh,
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Future<void> _showGroupDialog() async {
    final name = await askName(context, title: '新建分组');
    if (name == null || name.trim().isEmpty) return;
    LearningSources.instance.addGroup(name);
    SmartDialog.showToast('已新建分组');
  }

  Future<void> _showAddSourceDialog() async {
    var type = LearningSourceType.upArchive;
    var group = LearningSources.instance.groups.first;
    final midCtr = TextEditingController();
    final refCtr = TextEditingController();
    final nameCtr = TextEditingController();
    final confirmed = await showDialog<bool>(
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
                  decoration: const InputDecoration(labelText: '类型'),
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
                  decoration: const InputDecoration(labelText: 'UP mid'),
                ),
                if (type != LearningSourceType.upArchive)
                  TextField(
                    controller: refCtr,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '合集 ID'),
                  ),
                TextField(
                  controller: nameCtr,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: '分组'),
                  items: [
                    for (final item in LearningSources.instance.groups)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => group = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final mid = int.tryParse(midCtr.text.trim());
    if (mid == null) {
      SmartDialog.showToast('mid 必须是数字');
      return;
    }
    int? refId;
    if (type != LearningSourceType.upArchive) {
      refId = int.tryParse(refCtr.text.trim());
      if (refId == null) return;
    }
    final target = LearningLibrary.instance.ensureFeedList();
    LearningSources.instance.add(
      type: type,
      mid: mid,
      refId: refId,
      name: nameCtr.text.trim().isEmpty ? type.label : nameCtr.text.trim(),
      targetListId: target,
      group: group,
    );
    SmartDialog.showToast('已添加，下拉刷新');
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView({required this.onlyUnread, required this.onRefresh});

  final bool onlyUnread;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    final sources = LearningSources.instance;
    return Obx(() {
      final feedId = library.ensureFeedList();
      var videos = library.find(feedId)?.videos ?? <LearningVideo>[];
      if (onlyUnread) {
        videos = videos
            .where((v) => sources.unreadBvids.contains(v.bvid))
            .toList();
      }
      final bySource = <String, List<LearningVideo>>{};
      for (final video in videos) {
        (bySource[video.sourceId ?? ''] ??= <LearningVideo>[]).add(video);
      }
      if (videos.isEmpty) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 300,
                child: Center(
                  child: Text(onlyUnread ? '暂无新视频' : '暂无更新内容'),
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: bySource.length,
          itemBuilder: (context, sectionIndex) {
            final entry = bySource.entries.elementAt(sectionIndex);
            final source = sources.find(entry.key);
            final unread = source?.unreadBvids.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      Text(
                        source?.name ?? '其他',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (unread > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '$unread 条新视频',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (source != null)
                        InkWell(
                          onTap: () {
                            sources.markSourceRead(source.id);
                            Get.toNamed('/member?mid=${source.mid}');
                          },
                          child: Text(
                            '查看该 UP 全部 ›',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final video in entry.value)
                  LearningVideoCard(
                    video: video,
                    showNew: sources.unreadBvids.contains(video.bvid),
                  ),
              ],
            );
          },
        ),
      );
    });
  }
}

class _GroupSourcesView extends StatelessWidget {
  const _GroupSourcesView({
    required this.group,
    required this.onOpen,
    required this.onAdd,
    required this.onRefresh,
  });

  final String group;
  final void Function(LearningSource) onOpen;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sources = LearningSources.instance.sources
          .where((s) => s.group == group)
          .toList();
      return Scaffold(
        floatingActionButton: FloatingActionButton.small(
          onPressed: onAdd,
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: sources.length + 1,
            itemBuilder: (context, index) {
              if (index == sources.length) {
                final real = sources.length;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: 80,
                    top: real == 0 ? 160 : 10,
                  ),
                  child: Center(
                    child: Text(
                      real == 0 ? '该分组还没有订阅' : '共 $real 个订阅',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                );
              }
              final source = sources[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(source.name.characters.first),
                ),
                title: Text(source.name),
                subtitle: Text(source.type.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (source.unreadBvids.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${source.unreadBvids.length}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'delete') {
                          LearningSources.instance.remove(source.id);
                        } else if (action.startsWith('move:')) {
                          LearningSources.instance.moveSource(
                            source.id,
                            action.substring(5),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        for (final g in LearningSources.instance.groups)
                          PopupMenuItem(value: 'move:$g', child: Text('移到 $g')),
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                  ],
                ),
                onTap: () => onOpen(source),
              );
            },
          ),
        ),
      );
    });
  }
}

Future<String?> askName(
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
