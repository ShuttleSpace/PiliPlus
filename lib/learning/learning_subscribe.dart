import 'package:PiliPlus/learning/learning_library.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_sources.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

void subscribeUpArchive({required int mid, String? name}) {
  final sources = LearningSources.instance;
  final id = LearningSource.makeId(
    type: LearningSourceType.upArchive,
    mid: mid,
  );
  if (sources.find(id) != null) {
    SmartDialog.showToast('已订阅该 UP 的投稿');
    return;
  }
  final targetListId = LearningLibrary.instance.ensureFeedList();
  sources.add(
    type: LearningSourceType.upArchive,
    mid: mid,
    name: (name ?? '').trim().isEmpty ? 'UP $mid' : name!.trim(),
    targetListId: targetListId,
  );
  SmartDialog.showToast('已订阅，去「订阅」页手动刷新');
}

void subscribeCollection({
  required int mid,
  int? seasonId,
  int? seriesId,
  String? name,
}) {
  final isSeason = seasonId != null;
  final id = isSeason ? seasonId : seriesId;
  if (id == null) return;

  final type = isSeason
      ? LearningSourceType.upSeason
      : LearningSourceType.upSeries;
  final sources = LearningSources.instance;
  final sourceId = LearningSource.makeId(
    type: type,
    mid: mid,
    refId: id,
  );
  if (sources.find(sourceId) != null) {
    SmartDialog.showToast('已订阅该合集');
    return;
  }
  final targetListId = LearningLibrary.instance.ensureFeedList();
  sources.add(
    type: type,
    mid: mid,
    refId: id,
    name: (name ?? '').trim().isEmpty ? '合集 $id' : name!.trim(),
    targetListId: targetListId,
  );
  SmartDialog.showToast('已订阅，去「订阅」页手动刷新');
}
