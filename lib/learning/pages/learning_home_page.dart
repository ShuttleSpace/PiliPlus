import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/pages/learning_lists_page.dart';
import 'package:PiliPlus/learning/pages/learning_sources_page.dart';
import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:flutter/material.dart' as fw;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 底部「首页」实际打开的页面：顶部只有「清单 / 订阅」两个 tab。
class LearningHomePage extends StatefulWidget {
  const LearningHomePage({super.key});

  @override
  State<LearningHomePage> createState() => _LearningHomePageState();
}

class _LearningHomePageState extends State<LearningHomePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _listScroll = ScrollController();
  final _sourceScroll = ScrollController();

  @override
  void dispose() {
    _tabs.dispose();
    _listScroll.dispose();
    _sourceScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return fw.Material(
      type: fw.MaterialType.transparency,
      child: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: [
              const Tab(text: '清单'),
              Obx(() {
                final count = LearningSources.instance.totalUnread;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('订阅'),
                      if (count > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                LearningLocalizations(
                  child: fw.Material(
                    type: fw.MaterialType.transparency,
                    child: LearningListsView(
                      embedded: true,
                      scrollController: _listScroll,
                    ),
                  ),
                ),
                LearningLocalizations(
                  child: fw.Material(
                    type: fw.MaterialType.transparency,
                    child: LearningSourcesView(
                      embedded: true,
                      scrollController: _sourceScroll,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
