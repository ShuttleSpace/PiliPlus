import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_progress.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/localizations_bridge.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// 待阅清单/订阅卡片统一入口：按设置决定是否提示恢复分 P 与进度。
Future<void> openLearningVideo(
  BuildContext context,
  LearningVideo video, {
  VoidCallback? onPlayed,
}) async {
  LearningSources.instance.markVideoRead(video.bvid);
  onPlayed?.call();
  if (video.cid == null) {
    SmartDialog.showToast('缺少分 P 信息');
    return;
  }

  void play({required int cid, required int progress}) => PageUtils.toVideoPage(
    bvid: video.bvid,
    cid: cid,
    cover: video.cover,
    title: video.title,
    progress: progress,
  );

  final last = Pref.learningResumePrompt
      ? LearningProgress.instance.latestForBvid(video.bvid)
      : null;
  if (last == null) {
    play(cid: video.cid!, progress: 0);
    return;
  }
  final resume = await showLearningDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('恢复播放进度？'),
      content: Text(
        last.title.isEmpty ? '是否从上次观看的分 P 继续？' : '上次看到「${last.title}」，是否继续？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('从头开始'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('继续观看'),
        ),
      ],
    ),
  );
  if (resume == true) {
    play(
      cid: last.cid,
      progress: last.completed ? 0 : last.positionMs,
    );
  } else {
    play(cid: video.cid!, progress: 0);
  }
}
