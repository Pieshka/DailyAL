import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dailyanimelist/widgets/user/contentbuilder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The anime/manga list page has an inline search box. While it is open the
/// system back button used to pop the list page itself, which closed the app
/// instead of closing the search box.
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

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: UserContentBuilder(
          username: '@me',
          category: 'anime',
          customFuture: (_) async => [],
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// The route itself also installs a PopScope, so only look at the one the
  /// list page adds. PopScope is generic, so match on the type rather than a
  /// concrete type argument.
  Finder listPopScope() => find.descendant(
        of: find.byType(UserContentBuilder),
        matching: find.byWidgetPredicate((widget) => widget is PopScope),
      );

  testWidgets('the list page stays poppable while search is closed',
      (tester) async {
    await pumpList(tester);

    expect(listPopScope(), findsOneWidget);
    expect(tester.widget<PopScope>(listPopScope()).canPop, isTrue);
  });

  testWidgets('opening the inline search blocks the system back button',
      (tester) async {
    await pumpList(tester);

    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.widget<PopScope>(listPopScope()).canPop, isFalse,
        reason: 'back must close the search box, not exit the app');

    // The clear button collapses it again, so the page becomes poppable.
    await tester.tap(find.byIcon(Icons.clear).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.widget<PopScope>(listPopScope()).canPop, isTrue);
  });
}
