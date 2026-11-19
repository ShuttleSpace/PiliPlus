import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_refresh.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/learning_video_card.dart';
import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class LearningSourcesPage extends StatelessWidget {
  const LearningSourcesPage({super.key});

  @override
  Widget build(BuildContext context) => LearningLocalizations(
    child: Scaffold(
      appBar: AppBar(title: const Text('我的订阅')),
      body: const LearningSourcesView(),
    ),
  );
}

/// 首页「订阅」tab：全部（时间线）+ 每个 UP / 合集一个横向 tab。
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

  List<LearningSource> get _sources =>
      LearningSources.instance.sources.toList();

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    final sources = _sources;
    final targets = _index == 0
        ? sources
        : (_index - 1 < sources.length
              ? [sources[_index - 1]]
              : <LearningSource>[]);
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
    if (targets.isEmpty) {
      SmartDialog.showToast('还没有订阅源');
    } else if (added > 0) {
      SmartDialog.showToast('新增 $added 个视频');
    } else {
      SmartDialog.showToast('暂无更新');
    }
  }

  void _openSource(LearningSource source) {
    LearningSources.instance.markSourceRead(source.id);
    Get.toNamed('/member?mid=${source.mid}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sources = _sources;
      final tabs = <String>['全部', ...sources.map((s) => s.name)];
      if (_index >= tabs.length) _index = tabs.length - 1;
      if (sources.isEmpty && _index != 0) _index = 0;

      return Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: tabs.length + 2,
              itemBuilder: (context, index) {
                if (index == tabs.length) {
                  return Align(
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: showAddSourceDialog,
                    ),
                  );
                }
                if (index == tabs.length + 1) {
                  return Align(
                    child: IconButton(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      onPressed: showManageSheet,
                    ),
                  );
                }
                final unread = index == 0
                    ? LearningSources.instance.totalUnread
                    : sources[index - 1].unreadBvids.length;
                return Align(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () {
                        if (index > 0) {
                          LearningSources.instance.markSourceRead(
                            sources[index - 1].id,
                          );
                        }
                        setState(() => _index = index);
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
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: ValueKey(sources.length),
              controller: _pageController,
              onPageChanged: (index) {
                if (index > 0) {
                  LearningSources.instance.markSourceRead(
                    sources[index - 1].id,
                  );
                }
                setState(() => _index = index);
              },
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final child = index == 0
                    ? _AllFeedView(
                        onRefresh: _refresh,
                        onOpenSource: _openSource,
                      )
                    : _SourceFeedView(
                        source: sources[index - 1],
                        onRefresh: _refresh,
                        onOpenSource: _openSource,
                      );
                return LearningLocalizations(
                  child: Material(
                    type: MaterialType.transparency,
                    child: child,
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  void showManageSheet() {
    showLearningBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final source in _sources)
              ListTile(
                title: Text(source.name),
                subtitle: Text(source.type.label),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    LearningSources.instance.remove(source.id);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> showAddSourceDialog() async {
    var type = LearningSourceType.upArchive;
    final midCtr = TextEditingController();
    final refCtr = TextEditingController();
    final nameCtr = TextEditingController();
    final confirmed = await showLearningDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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
    LearningSources.instance.add(
      type: type,
      mid: mid,
      refId: refId,
      name: nameCtr.text.trim().isEmpty ? type.label : nameCtr.text.trim(),
      targetListId: LearningLibrary.instance.ensureFeedList(),
    );
    SmartDialog.showToast('已添加，下拉刷新');
  }
}

class _AllFeedView extends StatelessWidget {
  const _AllFeedView({required this.onRefresh, required this.onOpenSource});

  final Future<void> Function() onRefresh;
  final void Function(LearningSource) onOpenSource;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    final sources = LearningSources.instance;
    return Obx(() {
      final feedId = library.ensureFeedList();
      final videos = List<LearningVideo>.from(
        library.find(feedId)?.videos ?? const <LearningVideo>[],
      )..sort((a, b) => b.addedAt.compareTo(a.addedAt));

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: videos.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 240, child: Center(child: Text('下拉刷新订阅'))),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final source = sources.find(video.sourceId ?? '');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (source != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                          child: InkWell(
                            onTap: () => onOpenSource(source),
                            child: Text(
                              source.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
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

class _SourceFeedView extends StatelessWidget {
  const _SourceFeedView({
    required this.source,
    required this.onRefresh,
    required this.onOpenSource,
  });

  final LearningSource source;
  final Future<void> Function() onRefresh;
  final void Function(LearningSource) onOpenSource;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    final sources = LearningSources.instance;
    return Obx(() {
      final feedId = library.ensureFeedList();
      final videos =
          List<LearningVideo>.from(
              library.find(feedId)?.videos ?? const <LearningVideo>[],
            )
            ..removeWhere((v) => v.sourceId != source.id)
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: videos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    Text(source.name, style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    InkWell(
                      onTap: () => onOpenSource(source),
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
              );
            }
            final video = videos[index - 1];
            return LearningVideoCard(
              video: video,
              showNew: sources.unreadBvids.contains(video.bvid),
            );
          },
        ),
      );
    });
  }
}
