import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/screens/sound_effects_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('sound effects page groups SFX by function', (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.soundEnabled, value: 'true');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(home: SoundEffectsScreen()),
      ),
    );

    await pumpUntilFound(tester, find.text('Goals'));
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Music volume'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Goal creation'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mini-games'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mini-games'), findsOneWidget);
    expect(find.text('Firefly click'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Stone landing'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Stone landing'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Game failed'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Game failed'), findsOneWidget);
  });
}
