import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_refresh.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/subscription_video_card.dart';
import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:collection/collection.dart';
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

/// 首页「订阅」tab，布局与官方「动态」一致：顶部 全部/分组/UP，
/// 左侧固定的已订阅 UP 列表，点头像切到该 UP 的投稿。
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

class _LearningSourcesViewState extends State<LearningSourcesView>
    with TickerProviderStateMixin {
  late TabController _tabController = TabController(length: 2, vsync: this);
  int _selectedMid = -1;
  bool _refreshing = false;

  List<LearningSource> get _sources =>
      LearningSources.instance.sources.toList();

  List<String> get _groups => LearningSources.instance.groups
      .where(
        (g) =>
            g != LearningSources.defaultGroup &&
            _sources.any((s) => s.group == g),
      )
      .toList();

  void _syncTabs(int length) {
    if (_tabController.length == length) return;
    final index = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: index.clamp(0, length - 1),
    );
  }

  String get _activeGroup {
    final index = _tabController.index;
    return index > 0 && index <= _groups.length ? _groups[index - 1] : '';
  }

  List<LearningSource> get _currentSources {
    final index = _tabController.index;
    if (index == 0) return _sources;
    if (index == _tabController.length - 1) {
      return _sources.where((s) => s.mid == _selectedMid).toList();
    }
    return _sources.where((s) => s.group == _activeGroup).toList();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    final targets = _currentSources;
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

  void _selectUp(int mid) {
    _selectedMid = mid;
    setState(() {
      _tabController.index = _tabController.length - 1;
    });
    final source = _sources.firstWhereOrNull((s) => s.mid == mid);
    if (source != null) LearningSources.instance.markSourceRead(source.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final groups = _groups;
      _syncTabs(groups.length + 2);
      final tabs = <String>['全部', ...groups, 'UP'];
      final colorScheme = Theme.of(context).colorScheme;
      final upSources = _sources
          .groupFoldBy<int, LearningSource>(
            (s) => s.mid,
            (previous, source) =>
                previous ?? source, // shortcut: 同一 UP 的多个合集只显示一个头像
          )
          .values
          .toList();

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerHeight: 0,
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface,
                  labelStyle: const TextStyle(fontSize: 13),
                  tabs: [for (final tab in tabs) Tab(text: tab)],
                ),
              ),
              IconButton(
                tooltip: '添加订阅',
                icon: const Icon(Icons.add),
                onPressed: showAddSourceDialog,
              ),
              IconButton(
                tooltip: '管理订阅',
                icon: const Icon(Icons.manage_accounts_outlined),
                onPressed: showManageSheet,
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: upSources.length,
                      itemBuilder: (context, index) {
                        final source = upSources[index];
                        final selected = _selectedMid == source.mid;
                        final unread = upSources
                            .where((s) => s.mid == source.mid)
                            .fold<int>(
                              0,
                              (sum, s) => sum + s.unreadBvids.length,
                            );
                        return SizedBox(
                          height: 76,
                          child: InkWell(
                            onTap: () => _selectUp(source.mid),
                            child: Opacity(
                              opacity: selected ? 1 : 0.6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 19,
                                        backgroundColor: colorScheme.primary,
                                        child: Text(
                                          source.name.isEmpty
                                              ? '订'
                                              : source.name.substring(0, 1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (unread > 0)
                                        const Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Badge(
                                            smallSize: 8,
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      source.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: selected
                                            ? colorScheme.primary
                                            : colorScheme.outline,
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
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FeedView(
                        sources: _sources,
                        onRefresh: _refresh,
                        onOpenSource: _openSource,
                      ),
                      ...groups.map(
                        (group) => _FeedView(
                          sources: _sources
                              .where((s) => s.group == group)
                              .toList(),
                          onRefresh: _refresh,
                          onOpenSource: _openSource,
                        ),
                      ),
                      _FeedView(
                        sources: _sources
                            .where((s) => s.mid == _selectedMid)
                            .toList(),
                        onRefresh: _refresh,
                        onOpenSource: _openSource,
                      ),
                    ],
                  ),
                ),
              ],
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

class _FeedView extends StatelessWidget {
  const _FeedView({
    required this.sources,
    required this.onRefresh,
    required this.onOpenSource,
  });

  final List<LearningSource> sources;
  final Future<void> Function() onRefresh;
  final void Function(LearningSource) onOpenSource;

  @override
  Widget build(BuildContext context) {
    final library = LearningLibrary.instance;
    final allSources = LearningSources.instance;
    return Obx(() {
      final feedId = library.ensureFeedList();
      final allowed = sources.map((s) => s.id).toSet();
      final videos =
          List<LearningVideo>.from(
              library.find(feedId)?.videos ?? const <LearningVideo>[],
            )
            ..removeWhere((v) => !allowed.contains(v.sourceId))
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

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
                  final source = allSources.find(video.sourceId ?? '');
                  if (source == null) return const SizedBox.shrink();
                  return SubscriptionVideoCard(
                    video: video,
                    source: source,
                    showNew: allSources.unreadBvids.contains(video.bvid),
                    onOpenSource: onOpenSource,
                  );
                },
              ),
      );
    });
  }
}
