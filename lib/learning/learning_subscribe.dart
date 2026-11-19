import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:PiliPlus/learning/widgets/subscribe_sheet.dart';
import 'package:material_ui/material_ui.dart';

Future<void> subscribeUpArchive({
  required BuildContext context,
  required int mid,
  String? name,
  String? avatar,
}) => showSubscribeSheet(
  context: context,
  source: LearningSource(
    id: LearningSource.makeId(type: LearningSourceType.upArchive, mid: mid),
    type: LearningSourceType.upArchive,
    mid: mid,
    name: (name ?? '').trim().isEmpty ? 'UP $mid' : name!.trim(),
    avatar: avatar,
    targetListId: LearningLibrary.instance.ensureFeedList(),
  ),
);

Future<void> subscribeCollection({
  required BuildContext context,
  required int mid,
  int? seasonId,
  int? seriesId,
  String? name,
}) async {
  final isSeason = seasonId != null;
  final id = isSeason ? seasonId : seriesId;
  if (id == null) return;
  await showSubscribeSheet(
    context: context,
    source: LearningSource(
      id: LearningSource.makeId(
        type: isSeason
            ? LearningSourceType.upSeason
            : LearningSourceType.upSeries,
        mid: mid,
        refId: id,
      ),
      type: isSeason
          ? LearningSourceType.upSeason
          : LearningSourceType.upSeries,
      mid: mid,
      refId: id,
      name: (name ?? '').trim().isEmpty ? '合集 $id' : name!.trim(),
      targetListId: LearningLibrary.instance.ensureFeedList(),
    ),
  );
}

bool isSubscribed(LearningSourceType type, int mid, {int? refId}) =>
    LearningSources.instance.find(
      LearningSource.makeId(type: type, mid: mid, refId: refId),
    ) !=
    null;

/// 直播间右上角菜单复用同一套订阅弹窗。
Future<void> subscribeLiveRoom({
  required BuildContext context,
  required int mid,
  required int roomId,
  String? name,
  String? avatar,
}) => showSubscribeSheet(
  context: context,
  source: LearningSource(
    id: LearningSource.makeId(type: LearningSourceType.upLive, mid: mid),
    type: LearningSourceType.upLive,
    mid: mid,
    refId: roomId,
    name: (name ?? '').trim().isEmpty ? '直播间 $roomId' : name!.trim(),
    avatar: avatar,
    targetListId: LearningLibrary.instance.ensureFeedList(),
  ),
);
