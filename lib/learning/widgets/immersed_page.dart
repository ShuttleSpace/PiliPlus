import 'package:flutter/material.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

/// 设置里以路由方式打开官方页面时，补上主壳原本提供的沉浸式状态栏与顶部安全区。
class ImmersedPage extends StatelessWidget {
  const ImmersedPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: theme.brightness,
        statusBarIconBrightness: theme.brightness.reverse,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: theme.brightness.reverse,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
          child: child,
        ),
      ),
    );
  }
}
