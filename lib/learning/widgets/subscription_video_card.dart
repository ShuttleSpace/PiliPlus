import 'package:PiliPlus/learning/learning_list.dart';
import 'package:PiliPlus/learning/learning_progress.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/add_to_list_sheet.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// 订阅流卡片：沿用官方「动态」的头像 + 来源 + 时间 + 视频卡 + 操作行布局，
/// 但数据源和动作全部是本地的，右上角用「本地」与官方动态区分。
class SubscriptionVideoCard extends StatelessWidget {
  const SubscriptionVideoCard({
    super.key,
    required this.video,
    required this.source,
    required this.showNew,
    this.onOpenSource,
  });

  final LearningVideo video;
  final LearningSource source;
  final bool showNew;
  final void Function(LearningSource)? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCollection = source.type != LearningSourceType.upArchive;
    final label = source.name.trim().isEmpty
        ? '订'
        : source.name.trim().substring(0, 1);
    return Container(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCollection
                  ? Colors.blue.shade400
                  : theme.colorScheme.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onOpenSource == null
                            ? null
                            : () => onOpenSource!(source),
                        child: Text(
                          source.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _time(
                        LearningSources.instance.lastRefreshAtFor(video.bvid) ??
                            video.addedAt,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '本地',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isCollection ? '合集新增' : '新投稿',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 7),
                _VideoCard(video: video, showNew: showNew),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Action(
                      icon: Icons.playlist_add,
                      label: '加入清单',
                      onTap: () =>
                          showAddToLearningListSheet(context, video: video),
                    ),
                    const SizedBox(width: 20),
                    Obx(() {
                      final read = !LearningSources.instance.unreadBvids
                          .contains(video.bvid);
                      return _Action(
                        icon: Icons.check_circle_outline,
                        label: read ? '已看' : '标为已看',
                        color: read ? theme.colorScheme.primary : null,
                        onTap: () {
                          LearningSources.instance.markVideoRead(video.bvid);
                          SmartDialog.showToast('已标记为已看');
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.showNew});

  final LearningVideo video;
  final bool showNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        LearningSources.instance.markVideoRead(video.bvid);
        if (video.cid == null) {
          SmartDialog.showToast('缺少分 P 信息');
          return;
        }
        PageUtils.toVideoPage(
          bvid: video.bvid,
          cid: video.cid!,
          cover: video.cover,
          title: video.title,
          progress:
              LearningProgress.instance
                  .get(
                    bvid: video.bvid,
                    cid: video.cid!,
                  )
                  ?.positionMs ??
              0,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 110,
                height: 70,
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
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.author.isEmpty ? video.bvid : video.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
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

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = color ?? theme.colorScheme.outline;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 15, color: effective),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: effective)),
        ],
      ),
    );
  }
}

String _time(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return '${time.month}月${time.day}日';
}
