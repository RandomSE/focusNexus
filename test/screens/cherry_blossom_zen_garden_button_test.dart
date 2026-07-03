import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/progressive_visuals/cherry_blossom_unlock.dart';
import 'package:focusNexus/progressive_visuals/garden_persistence.dart';
import 'package:focusNexus/progressive_visuals/garden_state.dart';

void main() {
  test('legacy saves load cherry blossom defaults', () {
    const json = '{"items":[]}';
    final state = GardenPersistence.decodeZenGarden(json, 0);
    expect(state.lifetimeZenPointsSpent, 0);
    expect(state.cherryBlossomTreeUnlocked, isFalse);
    expect(state.suppressRestartGrowthPrompt, isFalse);
    expect(state.cherryBlossomTree.stageIndex, 0);
  });

  test('suppressRestartGrowthPrompt roundtrips in persistence', () {
    const original = GardenState(
      pointsBalance: 1,
      suppressRestartGrowthPrompt: true,
    );
    final json = GardenPersistence.encodeZenGarden(original);
    final restored = GardenPersistence.decodeZenGarden(json, 1);
    expect(restored.suppressRestartGrowthPrompt, isTrue);
  });

  testWidgets('zen garden cherry blossom entry hidden before unlock', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            const garden = GardenState(pointsBalance: 100);
            return isCherryBlossomTreeUnlocked(garden)
                ? const Text('Visit Cherry Blossom Tree')
                : const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(find.text('Visit Cherry Blossom Tree'), findsNothing);
  });

  testWidgets('zen garden cherry blossom entry visible when unlocked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            const garden = GardenState(
              pointsBalance: 15000,
              cherryBlossomTreeUnlocked: true,
            );
            return isCherryBlossomTreeUnlocked(garden)
                ? const Text('Visit Cherry Blossom Tree')
                : const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(find.text('Visit Cherry Blossom Tree'), findsOneWidget);
  });
}
