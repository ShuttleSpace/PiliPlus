import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/pages/rcmd/view.dart';
import 'package:material_ui/material_ui.dart';

/// 三级入口：设置 → 推荐设置 → 算法发现页。
/// 默认首页不再展示该页面。
class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(title: const Text('算法发现页')),
      body: const RcmdPage(),
    );
  }
}
