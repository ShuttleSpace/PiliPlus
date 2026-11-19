import 'package:flutter/material.dart' as fm;
import 'package:flutter_localizations/flutter_localizations.dart' as fl;
import 'package:material_ui/material_ui.dart' as mm;

/// 子页内补两份本地化和 Material：项目混用 flutter/material 和 material_ui，
/// 两套库的 MaterialLocalizations / Material 是不同的类型。
class LearningLocalizations extends fm.StatelessWidget {
  const LearningLocalizations({super.key, required this.child});

  final fm.Widget child;

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Localizations(
      locale:
          fm.Localizations.maybeLocaleOf(context) ??
          const fm.Locale('zh', 'CN'),
      delegates: const <fm.LocalizationsDelegate<dynamic>>[
        ...fl.GlobalMaterialLocalizations.delegates,
        ...mm.GlobalMaterialLocalizations.delegates,
      ],
      child: fm.Material(
        type: fm.MaterialType.transparency,
        child: mm.Material(
          type: mm.MaterialType.transparency,
          child: fm.Directionality(
            textDirection:
                fm.Directionality.maybeOf(context) ?? fm.TextDirection.ltr,
            child: child,
          ),
        ),
      ),
    );
  }
}

Future<T?> showLearningDialog<T>({
  required fm.BuildContext context,
  required fm.WidgetBuilder builder,
}) {
  return mm.showDialog<T>(
    context: context,
    builder: (dialogContext) =>
        LearningLocalizations(child: builder(dialogContext)),
  );
}

Future<T?> showLearningBottomSheet<T>({
  required fm.BuildContext context,
  required fm.WidgetBuilder builder,
  bool isScrollControlled = false,
  fm.Color? backgroundColor,
}) {
  return mm.showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    builder: (sheetContext) =>
        LearningLocalizations(child: builder(sheetContext)),
  );
}
