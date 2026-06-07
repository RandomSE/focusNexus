import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/app_repositories_provider.dart';
import 'package:focusNexus/providers/points_balance_provider.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  group('pointsBalance provider', () {
    test('loads initial balance from repository', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      await container.read(appRepositoriesProvider).points.ensureInitialized();

      final balance = await container.read(pointsBalanceProvider.future);

      expect(balance, 50);
    });

    test('invalidates when balance is credited', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final points = container.read(appRepositoriesProvider).points;
      await points.ensureInitialized();

      final before = await container.read(pointsBalanceProvider.future);
      points.creditBalance(10);

      final after = await container.read(pointsBalanceProvider.future);
      expect(after, before + 10);
    });

    test('reload refreshes balance', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);
      final points = container.read(appRepositoriesProvider).points;
      await points.ensureInitialized();
      await container.read(pointsBalanceProvider.future);

      await points.writeBalance(99);
      await container.read(pointsBalanceProvider.notifier).reload();

      expect(container.read(pointsBalanceProvider).value, 99);
    });
  });
}
