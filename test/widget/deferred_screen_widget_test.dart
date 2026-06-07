import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/widgets/deferred_screen.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('DeferredScreen shows loading then data', (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          home: DeferredScreen<String>(
            loadToken: 'widget-test',
            minLoadingMs: 0,
            load: () async => 'loaded',
            loading: (_) => const Text('loading'),
            builder: (_, data) => Text('data:$data'),
          ),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    await pumpSettleWithTimeout(tester);
    expect(find.text('data:loaded'), findsOneWidget);
    expect(find.text('loading'), findsNothing);
  });

  testWidgets('DeferredScreen reloads when loadToken changes', (tester) async {
    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          home: DeferredScreen<int>(
            loadToken: 'token-1',
            load: () async => 1,
            loading: (_) => const Text('loading'),
            builder: (_, data) => Text('v$data'),
          ),
        ),
      ),
    );
    await pumpSettleWithTimeout(tester);
    expect(find.text('v1'), findsOneWidget);

    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          home: DeferredScreen<int>(
            loadToken: 'token-2',
            load: () async => 2,
            loading: (_) => const Text('loading'),
            builder: (_, data) => Text('v$data'),
          ),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('v2'));
    expect(find.text('loading'), findsNothing);
  });
}
