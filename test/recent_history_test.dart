import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dailyanimelist/widgets/user/contentlistwidget.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Recent Anime / Recent Manga rows on the search page delete an entry by
/// index. `buildBaseNodePageItem` used to pass the column index inside the
/// chunk (always 0 for a horizontal row), so the first entry was removed no
/// matter which card was closed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
  });

  testWidgets('the close button reports the tapped card index',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final closedIndexes = <int>[];
    final items = [101, 102, 103]
        .map((id) => BaseNode(content: Node(id: id, title: 'title $id')))
        .toList();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 260,
          child: horizontalList(
            category: 'anime',
            items: items,
            onClose: closedIndexes.add,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    // The close button only renders once the poster image loads, which the
    // test environment blocks, so drive the callbacks the cards were given.
    final cards =
        tester.widgetList<ContentAllWidget>(find.byType(ContentAllWidget)).toList();
    expect(cards, hasLength(items.length),
        reason: 'every recent card must be built for this to prove anything');

    cards.last.onClose!();
    await tester.pump(const Duration(milliseconds: 100));

    expect(closedIndexes, [items.length - 1],
        reason: 'closing the last recent card must report its own index');
  });
}
