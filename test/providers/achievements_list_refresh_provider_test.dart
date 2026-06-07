import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/providers/achievements_list_refresh_provider.dart';

void main() {
  test('achievementsListRefreshProvider bumps generation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(achievementsListRefreshProvider), 0);
    container.read(achievementsListRefreshProvider.notifier).bump();
    expect(container.read(achievementsListRefreshProvider), 1);
  });
}
