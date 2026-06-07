import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/deferred_load_params.dart';
import 'package:focusNexus/providers/deferred_load_provider.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  group('deferredScreenLoadProvider', () {
    test('returns loader result', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      final value = await container.read(
        deferredScreenLoadProvider(
          DeferredLoadParams(
            token: 'test',
            loader: () async => 42,
          ),
        ).future,
      );

      expect(value, 42);
    });

    test('honors minimum loading duration', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      final stopwatch = Stopwatch()..start();
      await container.read(
        deferredScreenLoadProvider(
          DeferredLoadParams(
            token: 'slow',
            minLoadingMs: 80,
            loader: () async => 'ok',
          ),
        ).future,
      );
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(80));
    });

    test('same token reuses cached async value', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      var calls = 0;
      final params = DeferredLoadParams(
        token: 'cached',
        loader: () async {
          calls++;
          return 'x';
        },
      );

      await container.read(deferredScreenLoadProvider(params).future);
      await container.read(deferredScreenLoadProvider(params).future);

      expect(calls, 1);
    });
  });
}
