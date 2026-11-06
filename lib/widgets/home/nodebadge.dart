import 'package:dailyanimelist/user/hompagepref.dart';
import 'package:dailyanimelist/widgets/home/animecard.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/material.dart';

import '../../constant.dart';

/// Smallest width the global score label (star + rating) needs inside
/// [AnimeCardBar]; the status badge is capped so it cannot take more than the
/// bar minus this.
const double _minScoreFieldWidth = 55;

class AnimeCardBar extends StatelessWidget {
  final NodeStatusValue? nsv;
  final double smallHeight;
  final double smallWidth;
  final double radius;
  final Node? node;
  final bool showMemberCount;
  final bool showNsv;
  final VoidCallback? onTap;
  final bool showEdit;
  final HomePageTileSize? homePageTileSize;
  final bool showSelfScoreInsteadOfStatus;
  final MyListStatus? myListStatus;
  const AnimeCardBar({
    Key? key,
    this.nsv,
    this.radius = 6,
    this.smallHeight = 30,
    this.smallWidth = 30,
    this.onTap,
    this.showMemberCount = true,
    this.showNsv = true,
    this.showEdit = true,
    this.node,
    this.homePageTileSize,
    this.showSelfScoreInsteadOfStatus = false,
    this.myListStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userPrefResize = homePageTileSize != null;
    final editWidget = Icon(
      Icons.edit,
      color: nsv?.color == null ? Colors.black : Colors.white,
      size: 16,
    );

    // Not wrapped in Center: Center expands to the widest width it is given, so
    // inside a Row it ate the whole card width and pushed the edit icon and the
    // global score out of view.
    final badgeWidget = Flexible(
      child: Text(
        nsv?.status ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );

    final memberCountStyle = TextStyle(
      overflow: TextOverflow.ellipsis,
      fontSize: 13,
    );

    final badgeStatusWidget = Container(
      decoration: BoxDecoration(
          color: nsv?.color ?? Colors.white,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(radius),
          )),
      child: Row(
        // Hug the content, otherwise the status badge claims the full card
        // width and the global score on its left gets no space at all.
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SB.w5,
          if (showSelfScoreInsteadOfStatus &&
              (myListStatus is MyAnimeListStatus ||
                  myListStatus is MyMangaListStatus))
            Flexible(
              child: starField(
                '${(myListStatus as dynamic)?.score?.toString() ?? '0'} · ',
                starHeight: 14,
                textStyle: memberCountStyle,
              ),
            ),
          badgeWidget,
          SB.w5,
          editWidget,
          SB.w5,
        ],
      ),
    );

    final starMemberWidget = (detailed) => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SB.w10,
            Container(
              height: 14,
              child: Image.asset("assets/images/star.png"),
            ),
            SB.w5,
            Flexible(
              flex: 3,
              child: title(
                  !(detailed is AnimeDetailed || detailed is MangaDetailed)
                      ? ('-')
                      : (detailed.mean == null
                          ? '-'
                          : ratingFormat.format(detailed.mean)),
                  fontSize: (!userPrefResize ||
                          homePageTileSize!.index == HomePageTileSize.m.index)
                      ? 11.5
                      : 14,
                  opacity: 1,
                  maxLines: 1,
                  textOverflow: TextOverflow.ellipsis),
            ),
            SB.w5,
            if (showMemberCount &&
                (detailed is AnimeDetailed || detailed is MangaDetailed) &&
                detailed.numListUsers != null &&
                (!userPrefResize ||
                    homePageTileSize!.index > HomePageTileSize.m.index))
              Expanded(
                child: title(
                  '(${userCountFormat.format(detailed.numListUsers)})',
                  textOverflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  fontSize: 9,
                  opacity: .7,
                ),
              )
          ],
        );

    final borderRadius = BorderRadius.only(
      bottomRight: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );

    final materialWidget = Material(
      elevation: 5,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showScoreField = !userPrefResize ||
                homePageTileSize!.index >= HomePageTileSize.m.index;
            // The badge hugs its content, which is fine until the card is
            // narrow: it would then take everything and squeeze the global
            // score out of the bar. Reserve just enough room for that score.
            final badgeMaxWidth = !showScoreField || !constraints.hasBoundedWidth
                ? double.infinity
                : constraints.maxWidth > _minScoreFieldWidth
                    ? constraints.maxWidth - _minScoreFieldWidth
                    : 0.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showScoreField) Expanded(child: starMemberWidget(node)),
                if (showNsv && showEdit) ...[
                  SB.w5,
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: badgeMaxWidth),
                    child: badgeStatusWidget,
                  ),
                ]
              ],
            );
          },
        ),
      ),
    );

    return Container(
      width: smallWidth,
      height: smallHeight,
      child: materialWidget,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final double height;
  final double width;
  final NodeStatusValue nsv;
  const StatusBadge(this.nsv, {this.height = 30.0, this.width = 40.0, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: height,
        width: width,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
            color: nsv.color, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: title(nsv?.status ?? "",
              opacity: 1, fontSize: 11, colorVal: Colors.white.value),
        ));
  }
}
