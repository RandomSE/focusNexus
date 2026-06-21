import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusNexus/models/classes/achievement.dart';
import 'package:focusNexus/providers/app_services_provider.dart';
import 'package:focusNexus/repositories/achievement_repository.dart';
import 'package:focusNexus/repositories/points_repository.dart';
import 'package:focusNexus/services/achievement_service.dart';
import 'package:focusNexus/services/sound_service.dart';
import 'package:focusNexus/views/achievement_detail_view.dart';

import '../helpers/in_memory_key_value_storage.dart';

void main() {
  Future<AchievementService> readyService({
    List<Achievement>? achievements,
  }) async {
    final storage = InMemoryKeyValueStorage();
    final seeded = achievements ??
        [
          const Achievement(
            id: '1',
            title: 'Test',
            reward: '10 points',
            task: 'Do thing',
            progress: 100,
          ),
        ];
    await AchievementRepository(storage).saveAll(seeded);
    final service = AchievementService(
      storage: storage,
      repository: AchievementRepository(storage),
      pointsRepository: PointsRepository(storage),
      soundService: SoundService(storage),
    );
    await service.setInitializationPrerequisites();
    await service.initialize();
    return service;
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required AchievementService service,
    required void Function(bool? result) onPop,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AchievementDetailView(
                        achievementId: '1',
                        themeData: ThemeData.light(),
                        primaryColor: Colors.blue,
                        secondaryColor: Colors.white,
                        textStyle: const TextStyle(),
                        buttonStyle: ElevatedButton.styleFrom(),
                      ),
                    ),
                  );
                  onPop(result);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows Complete label for completed achievements', (
    tester,
  ) async {
    final service = await readyService(
      achievements: [
        const Achievement(
          id: '1',
          title: 'Test',
          reward: '10 points',
          task: 'Do thing',
          progress: 3285,
          isCompleted: true,
        ),
      ],
    );

    await pumpDetail(tester, service: service, onPop: (_) {});

    expect(find.textContaining('Progress: Complete'), findsOneWidget);
    expect(find.textContaining('3285'), findsNothing);
  });

  testWidgets('system back pops with refresh after achievement completed', (
    tester,
  ) async {
    final service = await readyService();
    bool? popResult;

    await pumpDetail(tester, service: service, onPop: (r) => popResult = r);

    await tester.tap(find.text('Complete Achievement'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popResult, isTrue);
  });

  testWidgets('system back pops without refresh when not completed', (
    tester,
  ) async {
    final service = await readyService();
    bool? popResult;

    await pumpDetail(tester, service: service, onPop: (r) => popResult = r);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popResult, isFalse);
  });

  testWidgets('Close button pops without refresh when not completed', (
    tester,
  ) async {
    final service = await readyService();
    bool? popResult;

    await pumpDetail(tester, service: service, onPop: (r) => popResult = r);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(popResult, isFalse);
  });

  testWidgets('complete button hidden after achievement is completed', (
    tester,
  ) async {
    final service = await readyService();

    await pumpDetail(tester, service: service, onPop: (_) {});

    expect(find.text('Complete Achievement'), findsOneWidget);

    await tester.tap(find.text('Complete Achievement'));
    await tester.pumpAndSettle();

    expect(find.text('Complete Achievement'), findsNothing);
  });
}
