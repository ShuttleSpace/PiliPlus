import 'package:PiliPlus/learning/learning_progress.dart';
import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// 与搜索结果一致的横向视频卡片：封面 + 时长 + 标题 + UP + 本地进度。
class LearningVideoCard extends StatelessWidget {
  const LearningVideoCard({
    super.key,
    required this.video,
    this.showNew = false,
    this.onPlayed,
  });

  final LearningVideo video;
  final bool showNew;
  final VoidCallback? onPlayed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = LearningProgress.instance.get(
      bvid: video.bvid,
      cid: video.cid ?? 0,
    );
    final played = progress?.positionMs ?? 0;
    return InkWell(
      onTap: () {
        LearningSources.instance.markVideoRead(video.bvid);
        onPlayed?.call();
        if (video.cid == null) {
          SmartDialog.showToast('缺少分 P 信息');
          return;
        }
        PageUtils.toVideoPage(
          bvid: video.bvid,
          cid: video.cid!,
          cover: video.cover,
          title: video.title,
          progress: progress?.completed == true ? 0 : played,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 140,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (video.cover.isNotEmpty)
                      Image.network(
                        video.cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      )
                    else
                      Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    if (showNew)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    if (played > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress?.durationMs == null
                              ? null
                              : (played / progress!.durationMs).clamp(0.0, 1.0),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.author.isEmpty ? video.bvid : video.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (played > 0)
                    Text(
                      '看到 ${_format(played)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _format(int ms) {
  final d = Duration(milliseconds: ms);
  return '${d.inMinutes.toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
}
