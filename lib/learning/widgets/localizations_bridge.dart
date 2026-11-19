import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// TabBarView / PageView 会产生 LookupBoundary，根部的 MaterialLocalizations
/// 在子页里查不到。这里在每个子页内部补一份默认本地化，showDialog /
/// showModalBottomSheet 才能正常工作。
class LearningLocalizations extends StatelessWidget {
  const LearningLocalizations({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: Localizations.maybeLocaleOf(context) ?? const Locale('zh', 'CN'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        ...GlobalMaterialLocalizations.delegates,
        ...mui.GlobalMaterialLocalizations.delegates,
      ],
      child: child,
    );
  }
}

Future<T?> showLearningDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) =>
        LearningLocalizations(child: builder(dialogContext)),
  );
}

Future<T?> showLearningBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (sheetContext) =>
        LearningLocalizations(child: builder(sheetContext)),
  );
}
