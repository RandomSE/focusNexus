import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/mini_games/mini_game_round_config.dart';
import 'package:focusNexus/mini_games/stone_balance/stone_balance_constants.dart';
import 'package:focusNexus/screens/stone_balance_play_screen.dart';
import 'package:focusNexus/services/storage/storage_keys.dart';

import '../helpers/test_provider_scope.dart';

void main() {
  testWidgets('play screen uses drag-to-aim hint and no Left/Right pad',
      (tester) async {
    final storage = onboardedTestStorage();
    await storage.write(key: StorageKeys.points, value: '50');
    final container = await createTestContainer(storage: storage);
    await lightTestBootstrap(container);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      testUncontrolledScope(
        container: container,
        child: const MaterialApp(
          home: StoneBalancePlayScreen(
            config: MiniGameRoundConfig(
              gameId: StoneBalanceConstants.gameId,
              endless: false,
            ),
          ),
        ),
      ),
    );

    await pumpUntilFound(tester, find.textContaining('Height'));
    expect(find.textContaining('Drag or tap to aim'), findsOneWidget);
    expect(find.text('Left'), findsNothing);
    expect(find.text('Right'), findsNothing);
  });
}
