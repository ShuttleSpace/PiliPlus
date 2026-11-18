import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 首页「订阅」tab 的滚动/刷新宿主。
class LearningSourcesController extends GetxController
    with ScrollOrRefreshMixin {
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
