import 'dart:async';

import 'package:dailyanimelist/widgets/customfuture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CFutureBuilder renders done() when the future succeeds',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CFutureBuilder<String>(
        future: Future.value('ok'),
        loadingChild: const CircularProgressIndicator(),
        done: (snapshot) => Text(snapshot.data ?? 'nothing'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget);
  });

  testWidgets('CFutureBuilder renders done() instead of an endless loader '
      'when the future fails', (tester) async {
    // Regression: a failed future used to keep the loading child on screen
    // forever, which made countdowns and schedule lists look permanently stuck.
    Object? reported;
    final completer = Completer<String>();
    await tester.pumpWidget(MaterialApp(
      home: CFutureBuilder<String>(
        future: completer.future,
        loadingChild: const CircularProgressIndicator(),
        onError: (e) => reported = e,
        done: (snapshot) => const Text('error-or-empty-state'),
      ),
    ));
    completer.completeError(StateError('network down'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('error-or-empty-state'), findsOneWidget);
    expect(reported, isStateError);
  });

  testWidgets('CFutureBuilder without onError still leaves the empty state',
      (tester) async {
    final completer = Completer<String>();
    await tester.pumpWidget(MaterialApp(
      home: CFutureBuilder<String>(
        future: completer.future,
        loadingChild: const CircularProgressIndicator(),
        done: (snapshot) => Text(snapshot.hasData ? snapshot.data! : 'empty'),
      ),
    ));
    completer.completeError(StateError('boom'));
    await tester.pumpAndSettle();
    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('StateFullFutureWidget forwards errors to done() as well',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StateFullFutureWidget<int>(
        future: () => Future.error(Exception('failed')),
        loadingChild: const CircularProgressIndicator(),
        done: (snapshot) =>
            Text(snapshot.hasData ? '${snapshot.data}' : 'fallback'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('fallback'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
