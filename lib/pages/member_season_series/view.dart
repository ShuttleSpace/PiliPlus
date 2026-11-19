import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/learning/learning_source.dart';
import 'package:PiliPlus/learning/learning_subscribe.dart';
import 'package:PiliPlus/learning/widgets/subscribe_sheet.dart';
import 'package:PiliPlus/models/common/member/contribute_type.dart';
import 'package:PiliPlus/models_new/space/space_season_series/season.dart'
    show SpaceSsModel;
import 'package:PiliPlus/pages/member_season_series/controller.dart';
import 'package:PiliPlus/pages/member_season_series/widget/season_series_card.dart';
import 'package:PiliPlus/pages/member_video/view.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SeasonSeriesPage extends StatefulWidget {
  const SeasonSeriesPage({
    super.key,
    required this.mid,
    this.heroTag,
  });

  final int mid;
  final String? heroTag;

  @override
  State<SeasonSeriesPage> createState() => _SeasonSeriesPageState();
}

class _SeasonSeriesPageState extends State<SeasonSeriesPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final SeasonSeriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      SeasonSeriesController(widget.mid),
      tag: widget.heroTag,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      physics: platformAlwaysClampingPhysics,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
          ),
          sliver: Obx(
            () => _buildBody(_controller.loadingState.value),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(LoadingState<List<SpaceSsModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  final item = response[index];
                  final meta = item.meta;
                  final seasonId = _asInt(meta?.seasonId);
                  final seriesId = _asInt(meta?.seriesId);
                  final isSeason = seasonId != null;
                  return Stack(
                    children: [
                      SeasonSeriesCard(
                        item: item,
                        onTap: () => Get.to(
                          SimpleScaffold(
                            appBar: AppBar(title: Text(meta?.name ?? '')),
                            body: ViewSafeArea(
                              child: MemberVideo(
                                type: isSeason
                                    ? ContributeType.season
                                    : ContributeType.series,
                                heroTag: widget.heroTag,
                                mid: widget.mid,
                                seasonId: seasonId,
                                seriesId: seriesId,
                                title: meta?.name,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Obx(() {
                          final type = isSeason
                              ? LearningSourceType.upSeason
                              : LearningSourceType.upSeries;
                          final subscribed = isSubscribed(
                            type,
                            widget.mid,
                            refId: seasonId ?? seriesId,
                          );
                          return IconButton(
                            tooltip: subscribed ? '已订阅' : '订阅此合集',
                            icon: Icon(subscribeIcon(subscribed)),
                            color: subscribed
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.primary,
                            onPressed: () => subscribeCollection(
                              context: context,
                              mid: widget.mid,
                              seasonId: seasonId,
                              seriesId: seriesId,
                              name: meta?.name,
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
