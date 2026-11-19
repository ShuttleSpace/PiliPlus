import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_refresh.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/subscription_video_card.dart';
import 'package:collection/collection.dart';
import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:PiliPlus/models/common/image_type.dart';
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
/// 左侧固定的已订阅项列表，点击头像切到该 UP 的全部视频。
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
  String? _selectedSourceId;
  int? get _selectedMid =>
      _sources.firstWhereOrNull((s) => s.id == _selectedSourceId)?.mid;
  final Set<int> _bootstrappedMids = <int>{};
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

  List<LearningSource> get _currentSources {
    final index = _tabController.index;
    if (index == 0) return _sources;
    if (index == _tabController.length - 1) {
      final mid = _selectedMid;
      return _sources.where((s) => s.mid == mid).toList();
    }
    final group = _groups[index - 1];
    return _sources.where((s) => s.group == group).toList();
  }

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

  Future<void> _refresh({bool baseline = false, int? onlyMid}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final targets = _currentSources
          .where((s) => onlyMid == null || s.mid == onlyMid)
          .toList();
      if (targets.isEmpty) {
        SmartDialog.showToast('还没有订阅源');
        return;
      }
      var added = 0;
      for (final source in targets) {
        final outcome = await LearningRefresh.refresh(
          source: source,
          library: LearningLibrary.instance,
          baseline: baseline,
        );
        LearningSources.instance.recordRefresh(
          id: source.id,
          seenBvids: outcome.seenBvids,
          newBvids: outcome.newBvids,
          error: outcome.error,
        );
        added += outcome.added;
      }
      SmartDialog.showToast(added > 0 ? '新增 $added 个视频' : '暂无更新');
    } catch (e) {
      SmartDialog.showToast('刷新失败: $e');
    } finally {
      _refreshing = false;
    }
  }

  void _openSource(LearningSource source) {
    LearningSources.instance.markSourceRead(source.id);
    Get.toNamed('/member?mid=${source.mid}');
  }

  Future<void> _selectSource(LearningSource source) async {
    _selectedSourceId = source.id;
    setState(() {
      _tabController.index = _tabController.length - 1;
    });
    if (_bootstrappedMids.add(source.mid)) {
      await _refresh(baseline: true, onlyMid: source.mid);
    }
    LearningSources.instance.markSourceRead(source.id);
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
      final sources = _sources;
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
                      itemCount: sources.length,
                      itemBuilder: (context, index) {
                        final source = sources[index];
                        final selected = _selectedSourceId == source.id;
                        final unread = source.unreadBvids.length;
                        final label = source.name;
                        return SizedBox(
                          height: 76,
                          child: Tooltip(
                            message: '${source.type.label}\n${source.name}',
                            child: InkWell(
                              onTap: () => _selectSource(source),
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
                                          child: source.avatar != null
                                              ? ClipOval(
                                                  child: NetworkImgLayer(
                                                    src: source.avatar,
                                                    width: 38,
                                                    height: 38,
                                                    type: ImageType.avatar,
                                                  ),
                                                )
                                              : Text(
                                                  source.name.isEmpty
                                                      ? '订'
                                                      : source.name.substring(
                                                          0,
                                                          1,
                                                        ),
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.onPrimary,
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
                                        label,
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
                        sources: sources,
                        onRefresh: _refresh,
                        onOpenSource: _openSource,
                      ),
                      ...groups.map(
                        (group) => _FeedView(
                          sources: sources
                              .where((s) => s.group == group)
                              .toList(),
                          onRefresh: _refresh,
                          onOpenSource: _openSource,
                        ),
                      ),
                      Obx(
                        () => _FeedView(
                          sources: sources
                              .where((s) => s.mid == _selectedMid)
                              .toList(),
                          onRefresh: _refresh,
                          onOpenSource: _openSource,
                        ),
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
      builder: (sheetContext) => Material(
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _sources.length,
              itemBuilder: (context, index) {
                final source = _sources[index];
                return ListTile(
                  title: Text(source.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(source.type.label),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      LearningSources.instance.remove(source.id);
                      Navigator.pop(sheetContext);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedView extends StatelessWidget {
  const _FeedView({
    required this.sources,
    required this.onRefresh,
    required this.onOpenSource,
  });

  final List<LearningSource> sources;
  final Future<void> Function({bool baseline, int? onlyMid}) onRefresh;
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
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return RefreshIndicator(
        onRefresh: onRefresh,
        child: videos.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                children: const [
                  SizedBox(height: 240, child: Center(child: Text('下拉刷新订阅'))),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
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
