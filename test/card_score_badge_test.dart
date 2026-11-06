import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/user/hompagepref.dart';
import 'package:dailyanimelist/widgets/home/animecard.dart'
    show NodeStatusValue;
import 'package:dailyanimelist/widgets/home/nodebadge.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "I liked it, they hated it" section shows the user's own score and the
/// global score on the card bar. The status badge used to take the whole card
/// width (a max-sized Row plus a Center), so the global score lost all of its
/// space and both scores were cut off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final node = AnimeDetailed(
    id: 21,
    title: 'One Piece',
    mean: 8.13,
    numListUsers: 123456,
  );
  final listStatus = MyAnimeListStatus(score: 8, status: 'watching');

  Future<void> pumpBar(
    WidgetTester tester, {
    required double width,
    bool selfScore = true,
    HomePageTileSize? tileSize,
    String status = 'CW',
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 40,
            child: AnimeCardBar(
              nsv: NodeStatusValue(status: status, color: Colors.blue),
              node: node,
              myListStatus: selfScore ? listStatus : null,
              showSelfScoreInsteadOfStatus: selfScore,
              showMemberCount: true,
              homePageTileSize: tileSize,
              smallWidth: width,
              smallHeight: 30,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  Rect barRect(WidgetTester tester) => tester.getRect(find.byType(AnimeCardBar));

  void expectInsideBar(WidgetTester tester, Iterable<Finder> finders) {
    final bar = barRect(tester);
    for (final finder in finders) {
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(bar.left - 0.5),
          reason: '$finder is cut off on the left');
      expect(rect.right, lessThanOrEqualTo(bar.right + 0.5),
          reason: '$finder is cut off on the right');
    }
  }

  testWidgets('the bar shows the own score and the global score',
      (tester) async {
    await pumpBar(tester, width: 180);

    expect(find.text('8 · '), findsOneWidget,
        reason: 'the user score must be visible in the badge');
    expect(find.textContaining('8.13'), findsOneWidget,
        reason: 'the global mean must be visible');

    final ownScore = tester.getRect(find.text('8 · '));
    final globalScore = tester.getRect(find.textContaining('8.13'));
    // The test font is far wider than any real font, so only assert the score
    // keeps a readable slice instead of a specific number of glyphs.
    expect(globalScore.width, greaterThanOrEqualTo(10),
        reason: 'the global score is squeezed to nothing and cannot be read');
    expect(globalScore.right, lessThanOrEqualTo(ownScore.left + 0.5),
        reason: 'the global score must stay left of the badge');
    expectInsideBar(
        tester, [find.text('8 · '), find.textContaining('8.13'), find.byIcon(Icons.edit)]);
  });

  testWidgets('a narrow card keeps both scores inside the bar', (tester) async {
    // 150 is narrower than any card that shows both scores in the app (the
    // stats screen uses 180, the bookmarks page 160).
    await pumpBar(tester, width: 150);

    expect(find.text('8 · '), findsOneWidget);
    expect(find.textContaining('8.13'), findsOneWidget);
    expect(tester.getRect(find.textContaining('8.13')).width,
        greaterThanOrEqualTo(10),
        reason: 'the global score must stay readable');
    expectInsideBar(
        tester, [find.text('8 · '), find.textContaining('8.13'), find.byIcon(Icons.edit)]);
  });

  testWidgets('the status text alone does not eat the whole bar',
      (tester) async {
    await pumpBar(tester, width: 140, selfScore: false, status: 'Completed');

    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('8.13'), findsOneWidget,
        reason: 'the global score keeps its space next to a long status');
    expectInsideBar(
        tester, [find.text('Completed'), find.textContaining('8.13')]);
  });

  testWidgets('home page tiles keep their status badge', (tester) async {
    // xs and s tiles only show the badge, m and up also show the score field.
    for (final size in HomePageTileSize.values) {
      final width = tileMap[size]!.contentWidth;
      await pumpBar(tester, width: width, selfScore: false, tileSize: size);
      expectInsideBar(tester, [find.byIcon(Icons.edit)]);
    }
  });
}
