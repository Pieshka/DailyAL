import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/widgets/anime_graph.dart';
import 'package:dal_commons/commons.dart' as dal;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The related-graph page draws edge to edge, so its control row has to keep
/// clear of the Android navigation bar. It used to sit at a fixed 20 px from
/// the bottom of the screen, which put it under the bar on phones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const screenSize = Size(400, 700);
  const navBarInset = 48.0;

  setUp(() => HttpOverrides.global = _StubHttpOverrides());
  tearDown(() => HttpOverrides.global = null);

  final graph = dal.AnimeGraph(
    nodes: [
      dal.GraphNode(
        id: 1,
        title: 'Sword Art Online',
        mean: 7.5,
        mainPicture: dal.GMainPicture(large: 'https://example.com/1.jpg'),
      ),
      dal.GraphNode(
        id: 2,
        title: 'Sword Art Online II',
        mean: 7.4,
        mainPicture: dal.GMainPicture(large: 'https://example.com/2.jpg'),
      ),
    ],
    edges: [
      dal.GraphEdge(
        source: 1,
        target: 2,
        relationType: dal.GRelationType.sequel,
      ),
    ],
  );

  Future<void> pumpGraph(WidgetTester tester, {double? bottomInset}) async {
    await tester.binding.setSurfaceSize(screenSize);
    final graphWidget = AnimeGraphWidget(
      graph: graph,
      id: 1,
      statusMap: const {},
      actions: const [],
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: bottomInset == null
          ? graphWidget
          : MediaQuery(
              data: MediaQueryData(
                  padding: EdgeInsets.only(bottom: bottomInset)),
              child: graphWidget,
            ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('the graph controls stay above the navigation bar',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGraph(tester, bottomInset: navBarInset);

    for (final icon in [
      Icons.location_searching,
      Icons.info,
      Icons.camera_alt,
    ]) {
      final rect = tester.getRect(find.byIcon(icon));
      expect(rect.bottom, lessThanOrEqualTo(screenSize.height - navBarInset),
          reason: '$icon is drawn under the system navigation bar');
    }
  });

  testWidgets('without a system inset the row keeps its original offset',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGraph(tester);

    final screenBottom = tester.getRect(find.byType(Scaffold)).bottom;
    // Measure the button itself: the Icon inside it is smaller than its tap
    // target, so it would sit 12 px above the row.
    final rect = tester.getRect(find.ancestor(
      of: find.byIcon(Icons.camera_alt),
      matching: find.byType(IconButton),
    ));
    expect(rect.bottom, closeTo(screenBottom - 20, 1));
  });
}

/// The graph nodes load their poster over the network; tests have no network,
/// so every request answers with a 1x1 transparent png.
class _StubHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _StubClient();
}

final List<int> _stubPng = base64
    .decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

class _StubClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _StubRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _StubResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _stubPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(_stubPng)
          .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
