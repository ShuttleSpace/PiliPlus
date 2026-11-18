import 'package:PiliPlus/learning/learning_progress.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

class LearningHistoryPage extends StatelessWidget {
  const LearningHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = LearningProgress.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('观看记录与统计')),
      body: Obx(() {
        final stats = progress.stats();
        final history = progress.history();
        final completion = (stats['completionRate'] as double) * 100;
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Text('本周记录 ${stats['thisWeek']} 条'),
                      const SizedBox(height: 6),
                      Text(
                        '累计 ${stats['total']} 条 · 完播 ${stats['completed']} 条',
                      ),
                      const SizedBox(height: 6),
                      Text('完播率 ${completion.toStringAsFixed(1)}%'),
                      const SizedBox(height: 6),
                      Text('本地观看时长 ${_format(stats['watchedMs'] as int)}'),
                    ],
                  ),
                ),
              ),
            ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('还没有本地观看记录')),
              )
            else
              for (final item in history)
                ListTile(
                  title: Text(
                    item.title.isEmpty ? item.bvid : item.title,
                    maxLines: 2,
                  ),
                  subtitle: Text(
                    '${_format(item.positionMs)} / ${_format(item.durationMs)}'
                    '${item.completed ? ' · 已完播' : ''}',
                  ),
                  onTap: () => PageUtils.toVideoPage(
                    bvid: item.bvid,
                    cid: item.cid,
                    cover: item.cover,
                    title: item.title,
                    progress: item.completed ? 0 : item.positionMs,
                  ),
                ),
          ],
        );
      }),
    );
  }
}

String _format(int ms) {
  final duration = Duration(milliseconds: ms);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
