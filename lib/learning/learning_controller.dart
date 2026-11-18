import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';

/// 首页「清单」tab 的滚动/刷新宿主。
/// 清单数据本身由 [LearningLibrary] 持有，这里只满足首页 tabBarView 的契约。
class LearningController extends GetxController with ScrollOrRefreshMixin {
  @override
  final ScrollController scrollController = ScrollController();

  @override
  Future<void> onRefresh() async {}

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
